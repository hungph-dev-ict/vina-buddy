import json
import logging
import re
from typing import Any, Dict

import httpx

from app.config import settings
from app.llm.base import (
    LLMProviderError,
    LLMTimeoutError,
    LLMUnsupportedContentError,
    LLMValidationError,
)
from app.llm.sanitizer import build_safe_rule_parsing_prompt

logger = logging.getLogger(__name__)


class LMStudioProvider:
    """Primary local LLM provider connecting to LM Studio's OpenAI-compatible API."""

    name: str = "lmstudio"

    def __init__(
        self,
        base_url: str | None = None,
        model: str | None = None,
        timeout: float | None = None,
    ) -> None:
        self.base_url = (base_url or settings.LM_STUDIO_BASE_URL).rstrip("/")
        self.model = model or settings.LM_STUDIO_MODEL
        self.timeout = timeout or settings.LLM_TIMEOUT_SECONDS

    async def health_check(self) -> bool:
        """Verify LM Studio server is reachable."""
        try:
            async with httpx.AsyncClient(timeout=2.0) as client:
                res = await client.get(f"{self.base_url}/models")
                return res.status_code == 200
        except Exception:
            return False

    async def parse_rule_intent(self, natural_language: str) -> Dict[str, Any]:
        """Send prompt to LM Studio OpenAI API and parse structured rule JSON."""
        prompt = build_safe_rule_parsing_prompt(natural_language)
        payload = {
            "model": self.model,
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You are an assistant that outputs strictly valid JSON only. "
                        "Never output markdown backticks, conversational preamble, or commentary."
                    ),
                },
                {"role": "user", "content": prompt},
            ],
            "temperature": 0.1,
        }

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                res = await client.post(
                    f"{self.base_url}/chat/completions",
                    json=payload,
                    headers={"Content-Type": "application/json"},
                )
        except httpx.TimeoutException as exc:
            raise LLMTimeoutError(f"LM Studio timed out after {self.timeout}s") from exc
        except Exception as exc:
            raise LLMProviderError(f"LM Studio connection error: {exc}") from exc

        if res.status_code != 200:
            raise LLMProviderError(f"LM Studio error {res.status_code}: {res.text[:200]}")

        try:
            data = res.json()
            raw_content = data["choices"][0]["message"]["content"].strip()

            # Clean markdown codeblocks if model outputs ```json ... ```
            clean_json = raw_content
            if "```" in clean_json:
                clean_json = re.sub(r"^```(?:json)?\s*", "", clean_json, flags=re.MULTILINE)
                clean_json = re.sub(r"\s*```$", "", clean_json, flags=re.MULTILINE)

            parsed = json.loads(clean_json.strip())
            if not isinstance(parsed, dict):
                raise LLMValidationError(f"Expected dict, got {type(parsed).__name__}")
            if parsed.get("supported") is False:
                msg = parsed.get("message") or "Nội dung này không thể hỗ trợ, vui lòng khiếu nại tới admin."
                raise LLMUnsupportedContentError(msg)
            return parsed
        except (LLMUnsupportedContentError, LLMValidationError):
            raise
        except json.JSONDecodeError as exc:
            raise LLMValidationError(f"Invalid JSON from LM Studio: {exc}") from exc
        except Exception as exc:
            raise LLMValidationError(f"Error parsing LM Studio response: {exc}") from exc
