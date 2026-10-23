import httpx
from fastapi import APIRouter

from app.config import settings
from app.schemas.health import HealthResponse

router = APIRouter(tags=["Health"])


@router.get("/health", response_model=HealthResponse)
@router.get("/v1/health", response_model=HealthResponse)
async def check_health() -> HealthResponse:
    llm_status = "disconnected"
    try:
        async with httpx.AsyncClient(timeout=0.8) as client:
            if settings.PRIMARY_LLM_PROVIDER.lower() == "lmstudio":
                res = await client.get(f"{settings.LM_STUDIO_BASE_URL}/models")
                if res.status_code == 200:
                    llm_status = "connected"
            else:
                res = await client.get(f"{settings.OLLAMA_BASE_URL}/api/version")
                if res.status_code == 200:
                    llm_status = "connected"
    except Exception:
        llm_status = "disconnected"

    return HealthResponse(
        status="healthy",
        ollama=llm_status,
        version=settings.APP_VERSION,
    )
