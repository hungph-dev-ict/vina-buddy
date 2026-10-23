from fastapi import APIRouter, HTTPException, status

from app.schemas.auth import (
    AuthSessionResponse,
    GoogleAuthRequest,
    RefreshTokenRequest,
    RevokeResponse,
)
from app.services.auth_service import (
    AuthExpiredError,
    AuthService,
    OAuthDenialError,
)

router = APIRouter(tags=["Auth"])

# Singleton auth service instance
auth_service = AuthService()


@router.post(
    "/auth/google",
    response_model=AuthSessionResponse,
    summary="Exchange Google authorization code for session",
)
async def exchange_google_code(request: GoogleAuthRequest) -> AuthSessionResponse:
    try:
        session_token, email, expires_at = await auth_service.exchange_google_code(
            auth_code=request.auth_code,
            redirect_uri=request.redirect_uri,
        )
        return AuthSessionResponse(
            session_token=session_token,
            email=email,
            expires_at=expires_at,
        )
    except OAuthDenialError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "OAUTH_DENIED", "message": str(exc)},
        ) from exc


@router.post(
    "/auth/refresh",
    response_model=AuthSessionResponse,
    summary="Refresh session token",
)
async def refresh_session(request: RefreshTokenRequest) -> AuthSessionResponse:
    try:
        session = auth_service.get_valid_session(request.session_token)
        token, expires_at = auth_service.refresh_session(request.session_token)
        return AuthSessionResponse(
            session_token=token,
            email=session.email,
            expires_at=expires_at,
        )
    except AuthExpiredError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "AUTH_EXPIRED", "message": str(exc)},
        ) from exc


@router.post(
    "/auth/revoke",
    response_model=RevokeResponse,
    summary="Revoke session and disconnect Gmail",
)
async def revoke_session(request: RefreshTokenRequest) -> RevokeResponse:
    auth_service.revoke_session(request.session_token)
    return RevokeResponse(status="revoked")
