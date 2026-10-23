import json
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


class OllamaProvider:
    """Primary local LLM provider connecting to Ollama."""

    name: str = "ollama"

    def __init__(
        self,
        base_url: str | None = None,
        model: str | None = None,
        timeout: float | None = None,
    ) -> None:
        self.base_url = (base_url or settings.OLLAMA_BASE_URL).rstrip("/")
        self.model = model or settings.OLLAMA_MODEL
        self.timeout = timeout or settings.LLM_TIMEOUT_SECONDS

    async def health_check(self) -> bool:
        """Verify Ollama server is reachable."""
        try:
            async with httpx.AsyncClient(timeout=1.0) as client:
                res = await client.get(f"{self.base_url}/api/version")
                return res.status_code == 200
        except Exception:
            return False

    async def parse_rule_intent(self, natural_language: str) -> Dict[str, Any]:
        """Send prompt to Ollama with format=json and parse output."""
        prompt = build_safe_rule_parsing_prompt(natural_language)
        payload = {
            "model": self.model,
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You are an assistant that outputs strictly valid JSON only. "
                        "Never output markdown backticks or commentary."
                    ),
                },
                {"role": "user", "content": prompt},
            ],
            "stream": False,
            "format": "json",
            "options": {
                "temperature": 0.1,
            },
        }

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/api/chat",
                    json=payload,
                )
        except httpx.TimeoutException as exc:
            raise LLMTimeoutError(
                f"Ollama request timed out after {self.timeout}s"
            ) from exc
        except Exception as exc:
            raise LLMProviderError(f"Ollama network error: {exc}") from exc

        if response.status_code != 200:
            raise LLMProviderError(
                f"Ollama error {response.status_code}: {response.text[:200]}"
            )

        try:
            data = response.json()
            raw_content = data.get("message", {}).get("content", "")
            parsed = json.loads(raw_content)
            if not isinstance(parsed, dict):
                raise LLMValidationError(
                    f"Expected JSON object, got {type(parsed).__name__}"
                )
            if parsed.get("supported") is False:
                msg = parsed.get("message") or "Nội dung này không thể hỗ trợ, vui lòng khiếu nại tới admin."
                raise LLMUnsupportedContentError(msg)
            return parsed
        except (LLMUnsupportedContentError, LLMValidationError):
            raise
        except json.JSONDecodeError as exc:
            raise LLMValidationError(
                f"Ollama response could not be parsed as JSON: {exc}"
            ) from exc
