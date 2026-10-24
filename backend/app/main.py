from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers.assistant import router as assistant_router
from app.routers.auth import router as auth_router
from app.routers.classify import router as classify_router
from app.routers.gmail import router as gmail_router
from app.routers.health import router as health_router
from app.routers.reminders import router as reminders_router
from app.routers.reports import router as reports_router
from app.routers.rules import router as rules_router

app = FastAPI(
    title="Vina Buddy Backend",
    version=settings.APP_VERSION,
    description="Backend service for Vina Buddy Android application",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS Middleware
origins = (
    [origin.strip() for origin in settings.ALLOWED_ORIGINS.split(",")]
    if settings.ALLOWED_ORIGINS != "*"
    else ["*"]
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount all routers across root, /v1, and /api/v1 for broad client compatibility
for prefix in ("", "/v1", "/api/v1"):
    app.include_router(health_router, prefix=prefix)
    app.include_router(assistant_router, prefix=prefix)
    app.include_router(auth_router, prefix=prefix)
    app.include_router(gmail_router, prefix=prefix)
    app.include_router(rules_router, prefix=prefix)
    app.include_router(classify_router, prefix=prefix)
    app.include_router(reports_router, prefix=prefix)
    app.include_router(reminders_router, prefix=prefix)

