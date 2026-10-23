from .auth import router as auth_router
from .classify import router as classify_router
from .gmail import router as gmail_router
from .health import router as health_router
from .rules import router as rules_router

__all__ = [
    "health_router",
    "rules_router",
    "classify_router",
    "auth_router",
    "gmail_router",
]
