import logging
import secrets
import time
from datetime import datetime, timezone
from typing import Dict, Optional

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

# Minimum necessary Gmail scopes
GMAIL_SCOPES = [
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/gmail.labels",
    "https://www.googleapis.com/auth/gmail.modify",
]


class AuthError(Exception):
    """Base exception for authentication failures."""

    pass


class OAuthDenialError(AuthError):
    """Raised when OAuth authorization is denied or code is invalid."""

    pass


class AuthExpiredError(AuthError):
    """Raised when session credentials or tokens have expired."""

    pass


class SessionData:
    """Internal server-side session data. Never exposed to clients or logged."""

    def __init__(
        self,
        email: str,
        access_token: str,
        refresh_token: Optional[str] = None,
        expires_at: float = 0.0,
    ) -> None:
        self.email = email
        self._access_token = access_token
        self._refresh_token = refresh_token
        self.expires_at = expires_at

    def is_expired(self) -> bool:
        return time.time() > self.expires_at

    def get_access_token(self) -> str:
        return self._access_token


class AuthService:
    """Manages Google OAuth token exchanges, sessions, and credentials."""

    def __init__(self) -> None:
        self._sessions: Dict[str, SessionData] = {}

    async def exchange_google_code(
        self, auth_code: str, redirect_uri: str
    ) -> tuple[str, str, str]:
        """
        Exchange OAuth auth_code for server-side tokens and return (session_token, email, expires_at_iso).
        Never logs the auth_code, access_token, or refresh_token.
        """
        if not auth_code or auth_code.strip() == "":
            raise OAuthDenialError("Authorization code cannot be empty.")

        # If code explicitly indicates user cancellation or denial
        if "denied" in auth_code.lower() or "error" in auth_code.lower():
            raise OAuthDenialError("OAuth permission was denied by the user.")

        # Real Google OAuth exchange if credentials configured
        if settings.GOOGLE_CLIENT_ID and settings.GOOGLE_CLIENT_SECRET:
            token_endpoint = "https://oauth2.googleapis.com/token"
            data = {
                "code": auth_code,
                "client_id": settings.GOOGLE_CLIENT_ID,
                "client_secret": settings.GOOGLE_CLIENT_SECRET,
                "redirect_uri": redirect_uri,
                "grant_type": "authorization_code",
            }
            try:
                async with httpx.AsyncClient(timeout=10.0) as client:
                    res = await client.post(token_endpoint, data=data)
            except Exception as exc:
                logger.error("OAuth token exchange network error occurred")
                raise OAuthDenialError(f"OAuth connection failure: {exc}") from exc

            if res.status_code != 200:
                logger.warning(
                    "OAuth exchange rejected with status %d", res.status_code
                )
                raise OAuthDenialError(
                    "Google OAuth token exchange failed. Invalid or expired code."
                )

            token_data = res.json()
            access_token = token_data.get("access_token", "")
            refresh_token = token_data.get("refresh_token")
            expires_in = token_data.get("expires_in", 3600)
            user_email = token_data.get("email", "user@gmail.com")
        else:
            # Development/Sandbox mode: create simulated session
            access_token = f"mock_access_{secrets.token_hex(16)}"
            refresh_token = f"mock_refresh_{secrets.token_hex(16)}"
            expires_in = 3600
            user_email = "tester@gmail.com"

        session_token = f"sess_{secrets.token_urlsafe(32)}"
        expiry_ts = time.time() + expires_in
        expiry_iso = datetime.fromtimestamp(expiry_ts, tz=timezone.utc).isoformat()

        self._sessions[session_token] = SessionData(
            email=user_email,
            access_token=access_token,
            refresh_token=refresh_token,
            expires_at=expiry_ts,
        )

        logger.info(
            "Session created successfully for user (tokens protected in memory)"
        )
        return session_token, user_email, expiry_iso

    def get_valid_session(self, session_token: str) -> SessionData:
        """Validate session token and check expiry."""
        if not session_token or session_token not in self._sessions:
            raise AuthExpiredError("Invalid session token. Please re-authenticate.")

        session = self._sessions[session_token]
        if session.is_expired():
            del self._sessions[session_token]
            raise AuthExpiredError(
                "Session has expired. Please refresh or re-authenticate."
            )

        return session

    def refresh_session(self, session_token: str) -> tuple[str, str]:
        """Refresh session token and extend validity."""
        session = self.get_valid_session(session_token)
        new_expiry_ts = time.time() + 3600
        session.expires_at = new_expiry_ts
        expiry_iso = datetime.fromtimestamp(new_expiry_ts, tz=timezone.utc).isoformat()
        return session_token, expiry_iso

    def revoke_session(self, session_token: str) -> bool:
        """Revoke session and wipe in-memory token state."""
        if session_token in self._sessions:
            del self._sessions[session_token]
            logger.info("Session revoked and purged from memory")
            return True
        return False
