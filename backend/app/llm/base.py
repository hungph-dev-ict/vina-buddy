from typing import Any, Dict, Protocol


class LLMProviderError(Exception):
    """Base error for LLM provider operations."""

    pass


class LLMTimeoutError(LLMProviderError):
    """Raised when LLM provider exceeds response timeout."""

    pass


class LLMValidationError(LLMProviderError):
    """Raised when LLM output violates schema requirements."""

    pass


class LLMQuotaExceededError(LLMProviderError):
    """Raised when fallback provider hourly budget limit is exceeded."""

    pass


class LLMUnsupportedContentError(LLMProviderError):
    """Raised when input content is outside the scope of supported email actions."""

    pass



class LLMProvider(Protocol):
    """Protocol interface for replaceable LLM providers."""

    name: str

    async def parse_rule_intent(self, natural_language: str) -> Dict[str, Any]:
        """Convert natural language rule into structured rule dict."""
        ...

    async def health_check(self) -> bool:
        """Check if provider is operational."""
        ...
