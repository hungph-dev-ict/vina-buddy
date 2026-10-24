from pydantic import BaseModel, Field


class GoogleAuthRequest(BaseModel):
    auth_code: str = Field(
        ..., min_length=1, description="Google OAuth authorization code"
    )
    redirect_uri: str = Field(
        ..., min_length=1, description="OAuth redirect URI registered in Google Console"
    )


class AuthSessionResponse(BaseModel):
    session_token: str = Field(..., description="Opaque session bearer token")
    email: str = Field(..., description="Authenticated user Gmail address")
    expires_at: str = Field(..., description="ISO UTC expiration timestamp")


class RefreshTokenRequest(BaseModel):
    session_token: str = Field(..., description="Current session token to refresh")


class RevokeResponse(BaseModel):
    status: str = Field(default="revoked", description="Session revocation status")


class GoogleAuthConfigRequest(BaseModel):
    client_id: str = Field(..., min_length=5, description="Google OAuth 2.0 Client ID")
    client_secret: str = Field(..., min_length=5, description="Google OAuth 2.0 Client Secret")


class GoogleAuthUrlResponse(BaseModel):
    configured: bool
    auth_url: str | None = None
    state: str | None = None
    redirect_uri: str | None = None
    client_id: str | None = None
    message: str | None = None


class GoogleAuthPollResponse(BaseModel):
    status: str = Field(..., description="'pending', 'completed', or 'expired'")
    session_token: str | None = None
    email: str | None = None

