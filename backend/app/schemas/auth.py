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
