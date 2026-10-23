from .base import (
    LLMProvider,
    LLMProviderError,
    LLMQuotaExceededError,
    LLMTimeoutError,
    LLMUnsupportedContentError,
    LLMValidationError,
)
from .fallback import (
    ExternalAPIProvider,
    MockFallbackProvider,
    QuotaManager,
    ResilientLLMService,
)
from .lmstudio import LMStudioProvider
from .ollama import OllamaProvider


def get_default_primary_provider() -> LLMProvider:
    """Return primary local LLM provider based on settings."""
    from app.config import settings

    if settings.PRIMARY_LLM_PROVIDER.lower() == "lmstudio":
        return LMStudioProvider()
    return OllamaProvider()


__all__ = [
    "LLMProvider",
    "LLMProviderError",
    "LLMTimeoutError",
    "LLMValidationError",
    "LLMQuotaExceededError",
    "LLMUnsupportedContentError",
    "LMStudioProvider",
    "OllamaProvider",
    "QuotaManager",
    "MockFallbackProvider",
    "ExternalAPIProvider",
    "ResilientLLMService",
    "get_default_primary_provider",
]
