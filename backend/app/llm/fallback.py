import asyncio
import json
import logging
import re
import time
from typing import Any, Dict, List

import httpx

from app.config import settings
from app.llm.base import (
    LLMProvider,
    LLMProviderError,
    LLMQuotaExceededError,
    LLMTimeoutError,
    LLMUnsupportedContentError,
    LLMValidationError,
)
from app.llm.sanitizer import build_safe_rule_parsing_prompt

logger = logging.getLogger(__name__)

_EMAIL_RULE_KEYWORDS = (
    "email", "emails", "mail", "mails", "thư", "hộp thư", "inbox",
    "label", "labels", "nhãn", "tag", "tags", "gán", "move", "chuyển",
    "from", "từ", "subject", "tiêu đề", "sender", "người gửi",
    "newsletter", "newsletters", "bản tin", "receipt", "receipts",
    "hoá đơn", "invoice", "invoices", "order", "orders", "đơn hàng",
    "shopping", "mua sắm", "security", "bảo mật", "alert", "alerts",
    "cảnh báo", "spam", "finance", "tldr", "github", "filter", "lọc",
    "organize", "sort", "rule", "rules", "quy tắc", "quản lý",
)


class QuotaManager:
    """Thread-safe sliding-window quota manager for fallback budget."""

    def __init__(self, hourly_limit: int | None = None) -> None:
        self.hourly_limit = (
            hourly_limit
            if hourly_limit is not None
            else settings.FALLBACK_HOURLY_BUDGET
        )
        self._timestamps: List[float] = []
        self._lock = asyncio.Lock()

    async def check_and_consume(self) -> int:
        """
        Check if request is within budget and record invocation.
        Returns the number of remaining allowed calls in the current hour window.
        Raises LLMQuotaExceededError if limit is reached.
        """
        async with self._lock:
            now = time.time()
            cutoff = now - 3600.0
            # Expire timestamps older than 1 hour
            self._timestamps = [t for t in self._timestamps if t > cutoff]

            if len(self._timestamps) >= self.hourly_limit:
                raise LLMQuotaExceededError(
                    f"Fallback quota exceeded: limit of {self.hourly_limit} calls/hour reached. "
                    "Try again later or check local Ollama health."
                )

            self._timestamps.append(now)
            remaining = self.hourly_limit - len(self._timestamps)
            return remaining

    async def get_usage(self) -> Dict[str, Any]:
        """Get current quota metrics."""
        async with self._lock:
            now = time.time()
            cutoff = now - 3600.0
            active = [t for t in self._timestamps if t > cutoff]
            return {
                "used_in_window": len(active),
                "hourly_limit": self.hourly_limit,
                "remaining": max(0, self.hourly_limit - len(active)),
            }

    async def reset(self) -> None:
        """Reset quota counter (useful in tests)."""
        async with self._lock:
            self._timestamps.clear()


class MockFallbackProvider:
    """
    Deterministic rule parser used as safe fallback or offline development mock.
    Handles common pattern variations, multi-intent separation, and rejects out-of-scope requests.
    """

    name: str = "fallback_mock"

    async def health_check(self) -> bool:
        return True

    def _parse_single_clause(self, text: str) -> Dict[str, Any] | None:
        # Pattern: label emails from <sender> as <label>
        match_from_as = re.search(
            r"(?:label|move|tag|gán nhãn)?\s*(?:emails?|thư)?\s*(?:from|từ)\s+([a-zA-Z0-9_.-]+)\s+(?:as|to|are|is|with label|là|thành)\s+([a-zA-Z0-9_\s-]+)",
            text,
        )
        if match_from_as:
            sender = match_from_as.group(1).strip()
            label = match_from_as.group(2).strip().title()
            return {
                "name": f"Label {sender}",
                "conditions": [
                    {"field": "from", "operator": "contains", "value": sender}
                ],
                "actions": [{"type": "add_label", "label": label}],
                "priority": 1,
                "confidence": 0.95,
            }

        # Pattern: newsletter keywords
        if any(w in text for w in ("newsletter", "digest", "bản tin")):
            return {
                "name": "Newsletters",
                "conditions": [
                    {"field": "from", "operator": "contains", "value": "newsletter"}
                ],
                "actions": [{"type": "add_label", "label": "Newsletters"}],
                "priority": 1,
                "confidence": 0.92,
            }

        # Pattern: shopping / receipt
        if any(w in text for w in ("receipt", "invoice", "shopping", "order", "hoá đơn", "biên lai", "mua sắm", "đơn hàng")):
            return {
                "name": "Receipts & Orders",
                "conditions": [
                    {"field": "subject", "operator": "contains", "value": "order"}
                ],
                "actions": [{"type": "add_label", "label": "Finance"}],
                "priority": 1,
                "confidence": 0.88,
            }

        # Pattern: security / alerts
        if any(w in text for w in ("security", "alert", "bảo mật", "cảnh báo")):
            return {
                "name": "Security Alerts",
                "conditions": [
                    {"field": "subject", "operator": "contains", "value": "security"}
                ],
                "actions": [{"type": "add_label", "label": "Security"}],
                "priority": 1,
                "confidence": 0.89,
            }

        return None

    async def parse_rule_intent(self, natural_language: str) -> Dict[str, Any]:
        text = natural_language.strip().lower()

        # Guard against prompt injection attempting destructive actions
        if any(bad in text for bad in ("delete", "destroy", "trash", "remove all")):
            raise LLMValidationError(
                "Requested rule implies deletion or destruction, which is strictly prohibited."
            )

        # Check if the query is outside email management scope
        if not any(kw in text for kw in _EMAIL_RULE_KEYWORDS):
            raise LLMUnsupportedContentError(
                "Nội dung này không thể hỗ trợ, vui lòng khiếu nại tới admin."
            )

        # Multi-intent compound rule pattern:
        # e.g. "emails from tldr are spam and emails from GitHub are source code"
        multi_matches = re.findall(
            r"(?:emails?\s+from|from|thư\s+từ|từ)\s+([a-zA-Z0-9_.-]+)\s+(?:are|as|to|is|with label|là|thành)\s+([a-zA-Z0-9_\s-]+?)(?=\s+(?:and|và|còn)\s+(?:emails?\s+from|from|thư\s+từ|từ)|$)",
            text,
        )
        if len(multi_matches) > 1:
            rules_list = []
            for sender_raw, label_raw in multi_matches:
                sender = sender_raw.strip()
                label = label_raw.strip().title()
                rules_list.append({
                    "name": f"Label {sender}",
                    "conditions": [
                        {"field": "from", "operator": "contains", "value": sender}
                    ],
                    "actions": [{"type": "add_label", "label": label}],
                    "priority": 1,
                    "confidence": 0.95,
                })
            return {
                "supported": True,
                "rules": rules_list,
            }

        single_rule = self._parse_single_clause(text)
        if single_rule:
            return single_rule

        # Generic fallback rule with lower confidence
        words = [w for w in re.findall(r"\w+", text) if len(w) > 3]
        target_val = words[0] if words else "important"
        return {
            "name": f"Filter {target_val}",
            "conditions": [
                {"field": "snippet", "operator": "contains", "value": target_val}
            ],
            "actions": [{"type": "add_label", "label": target_val.capitalize()}],
            "priority": 2,
            "confidence": 0.60,  # Below threshold -> marks uncertain
        }



class ExternalAPIProvider:
    """External OpenAI-compatible API provider."""

    name: str = "fallback_external"

    def __init__(
        self,
        api_key: str | None = None,
        base_url: str | None = None,
        model: str | None = None,
        timeout: float | None = None,
    ) -> None:
        self.api_key = api_key or settings.EXTERNAL_LLM_API_KEY
        self.base_url = (base_url or settings.EXTERNAL_LLM_BASE_URL).rstrip("/")
        self.model = model or settings.EXTERNAL_LLM_MODEL
        self.timeout = timeout or settings.LLM_TIMEOUT_SECONDS

    async def health_check(self) -> bool:
        return bool(self.api_key)

    async def parse_rule_intent(self, natural_language: str) -> Dict[str, Any]:
        if not self.api_key:
            raise LLMProviderError("External API key not configured")

        prompt = build_safe_rule_parsing_prompt(natural_language)
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": self.model,
            "messages": [
                {
                    "role": "system",
                    "content": "You are a structured JSON extraction assistant. Return valid JSON only.",
                },
                {"role": "user", "content": prompt},
            ],
            "response_format": {"type": "json_object"},
            "temperature": 0.1,
        }

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                res = await client.post(
                    f"{self.base_url}/chat/completions",
                    json=payload,
                    headers=headers,
                )
        except httpx.TimeoutException as exc:
            raise LLMTimeoutError(
                f"External fallback timed out after {self.timeout}s"
            ) from exc
        except Exception as exc:
            raise LLMProviderError(f"External API error: {exc}") from exc

        if res.status_code != 200:
            raise LLMProviderError(
                f"External API HTTP {res.status_code}: {res.text[:200]}"
            )

        try:
            body = res.json()
            content = body["choices"][0]["message"]["content"]
            parsed = json.loads(content)
            if not isinstance(parsed, dict):
                raise LLMValidationError(f"Expected dict, got {type(parsed).__name__}")
            return parsed
        except Exception as exc:
            raise LLMValidationError(f"External response format error: {exc}") from exc


class ResilientLLMService:
    """
    Orchestrates Primary LLM (Ollama) with automatic fallback to secondary provider,
    enforcing timeouts and sliding-window quota budgets.
    """

    def __init__(
        self,
        primary_provider: LLMProvider | None = None,
        fallback_provider: LLMProvider | None = None,
        quota_manager: QuotaManager | None = None,
    ) -> None:
        self.primary = primary_provider
        self.fallback = fallback_provider or (
            MockFallbackProvider()
            if settings.USE_MOCK_FALLBACK or not settings.EXTERNAL_LLM_API_KEY
            else ExternalAPIProvider()
        )
        self.quota_manager = quota_manager or QuotaManager()

    async def parse_rule(self, natural_language: str) -> tuple[Dict[str, Any], str]:
        """
        Attempt rule parsing via primary provider. If timeout or error occurs,
        consume quota and invoke fallback provider.
        Returns: (parsed_dict, provider_name_used)
        """
        # Try primary provider first if available
        if self.primary:
            try:
                result = await self.primary.parse_rule_intent(natural_language)
                return result, self.primary.name
            except LLMUnsupportedContentError:
                raise
            except (LLMTimeoutError, LLMProviderError, LLMValidationError) as exc:
                logger.warning(
                    "Primary LLM (%s) failed (%s: %s). Attempting fallback.",
                    self.primary.name,
                    type(exc).__name__,
                    exc,
                )
            except Exception as exc:
                logger.error("Unexpected error in primary LLM: %s", exc)

        # Fallback path: enforce quota budget first
        await self.quota_manager.check_and_consume()

        # Execute fallback
        try:
            result = await self.fallback.parse_rule_intent(natural_language)
            return result, self.fallback.name
        except (LLMValidationError, LLMQuotaExceededError, LLMUnsupportedContentError):
            raise
        except Exception as exc:
            logger.error("Fallback provider failed: %s", exc)
            raise LLMProviderError(f"All LLM providers failed: {exc}") from exc

