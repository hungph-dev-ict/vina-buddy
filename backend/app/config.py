from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

_env_file = Path(__file__).resolve().parent.parent / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=_env_file,
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    APP_VERSION: str = "0.1.0"

    # CORS
    ALLOWED_ORIGINS: str = "*"

    # Primary Local LLM Provider ("lmstudio" or "ollama")
    PRIMARY_LLM_PROVIDER: str = "lmstudio"

    # LM Studio (OpenAI-compatible)
    LM_STUDIO_BASE_URL: str = "http://localhost:1234/v1"
    LM_STUDIO_MODEL: str = "qwen/qwen3-4b-2507"

    # Ollama
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "qwen2.5:3b"

    # External LLM Fallback & Quotas
    LLM_TIMEOUT_SECONDS: float = 8.0
    FALLBACK_HOURLY_BUDGET: int = 20
    MIN_CONFIDENCE_THRESHOLD: float = 0.70
    EXTERNAL_LLM_API_KEY: str = ""
    EXTERNAL_LLM_BASE_URL: str = "https://api.openai.com/v1"
    EXTERNAL_LLM_MODEL: str = "gpt-4o-mini"
    USE_MOCK_FALLBACK: bool = True

    # Google OAuth (Server Side)
    GOOGLE_CLIENT_ID: str = ""
    GOOGLE_CLIENT_SECRET: str = ""
    GOOGLE_REDIRECT_URI: str = "com.vinabuddy.smartinbox:/oauth2callback"

    # Session
    SESSION_SECRET_KEY: str = "default-dev-secret-key-32-chars-min"


settings = Settings()
