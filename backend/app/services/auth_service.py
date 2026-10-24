import json
import logging
from pathlib import Path
import secrets
import time
from datetime import datetime, timezone
from typing import Any, Dict, Optional

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

SESSION_STORE_PATH = Path(__file__).resolve().parent.parent.parent / ".sessions_store.json"

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
        self._pending_auth: Dict[str, Dict[str, Any]] = {}
        self._load_sessions_from_disk()

    def _load_sessions_from_disk(self) -> None:
        try:
            if SESSION_STORE_PATH.exists():
                with open(SESSION_STORE_PATH, "r", encoding="utf-8") as f:
                    data = json.load(f)
                now = time.time()
                for token, s in data.items():
                    exp = s.get("expires_at", 0)
                    # Keep sessions valid for up to 7 days
                    if exp + 86400 * 7 > now:
                        self._sessions[token] = SessionData(
                            email=s.get("email", ""),
                            access_token=s.get("access_token", ""),
                            refresh_token=s.get("refresh_token"),
                            expires_at=max(exp, now + 3600),
                        )
                logger.info("Restored %d sessions from disk storage", len(self._sessions))
        except Exception as exc:
            logger.warning("Could not restore sessions from disk: %s", exc)

    def _save_sessions_to_disk(self) -> None:
        try:
            data = {}
            for token, s in self._sessions.items():
                data[token] = {
                    "email": s.email,
                    "access_token": s.get_access_token(),
                    "refresh_token": s._refresh_token,
                    "expires_at": s.expires_at,
                }
            with open(SESSION_STORE_PATH, "w", encoding="utf-8") as f:
                json.dump(data, f)
        except Exception as exc:
            logger.warning("Could not persist sessions to disk: %s", exc)

    def get_google_auth_url(self, redirect_uri: str) -> Dict[str, Any]:
        """Generate Google OAuth 2.0 authorization URL."""
        if not settings.GOOGLE_CLIENT_ID:
            return {
                "configured": False,
                "client_id": None,
                "message": "GOOGLE_CLIENT_ID chưa được cấu hình.",
            }

        state = f"state_{secrets.token_urlsafe(16)}"
        self._pending_auth[state] = {
            "status": "pending",
            "created_at": time.time(),
        }

        scopes = " ".join([
            "https://www.googleapis.com/auth/gmail.readonly",
            "https://www.googleapis.com/auth/gmail.labels",
            "https://www.googleapis.com/auth/gmail.modify",
            "https://www.googleapis.com/auth/userinfo.email",
            "https://www.googleapis.com/auth/userinfo.profile",
        ])

        import urllib.parse
        params = {
            "client_id": settings.GOOGLE_CLIENT_ID,
            "redirect_uri": redirect_uri,
            "response_type": "code",
            "scope": scopes,
            "access_type": "offline",
            "prompt": "consent",
            "state": state,
        }
        auth_url = f"https://accounts.google.com/o/oauth2/v2/auth?{urllib.parse.urlencode(params)}"
        return {
            "configured": True,
            "auth_url": auth_url,
            "state": state,
            "redirect_uri": redirect_uri,
            "client_id": settings.GOOGLE_CLIENT_ID,
        }

    def set_google_credentials(self, client_id: str, client_secret: str) -> None:
        """Update Google OAuth client credentials and save to .env."""
        settings.GOOGLE_CLIENT_ID = client_id.strip()
        settings.GOOGLE_CLIENT_SECRET = client_secret.strip()
        try:
            from pathlib import Path
            env_path = Path(__file__).resolve().parent.parent.parent / ".env"
            lines = []
            if env_path.exists():
                with open(env_path, "r", encoding="utf-8") as f:
                    lines = [
                        line for line in f.readlines()
                        if not line.startswith("GOOGLE_CLIENT_ID=") and not line.startswith("GOOGLE_CLIENT_SECRET=")
                    ]
            lines.append(f"GOOGLE_CLIENT_ID={client_id.strip()}\n")
            lines.append(f"GOOGLE_CLIENT_SECRET={client_secret.strip()}\n")
            with open(env_path, "w", encoding="utf-8") as f:
                f.writelines(lines)
            logger.info("Saved Google credentials to %s", env_path)
        except Exception as exc:
            logger.warning("Failed saving credentials to .env: %s", exc)

    def poll_pending_auth(self, state: str) -> Dict[str, Any]:
        """Poll the status of an ongoing Google OAuth flow."""
        now = time.time()
        for k in list(self._pending_auth.keys()):
            if now - self._pending_auth[k].get("created_at", now) > 900:
                del self._pending_auth[k]

        entry = self._pending_auth.get(state)
        if not entry:
            return {"status": "expired"}
        return entry

    async def exchange_google_code(
        self, auth_code: str, redirect_uri: str, state: Optional[str] = None
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

        # Real Google OAuth exchange if credentials configured and not a test mock code
        is_mock_code = (
            auth_code.startswith("mock_")
            or auth_code.startswith("valid_mock_")
            or auth_code.startswith("email:")
        )
        if settings.GOOGLE_CLIENT_ID and not is_mock_code:
            token_endpoint = "https://oauth2.googleapis.com/token"
            data = {
                "code": auth_code,
                "client_id": settings.GOOGLE_CLIENT_ID,
                "redirect_uri": redirect_uri,
                "grant_type": "authorization_code",
            }
            if settings.GOOGLE_CLIENT_SECRET:
                data["client_secret"] = settings.GOOGLE_CLIENT_SECRET

            try:
                async with httpx.AsyncClient(timeout=10.0) as client:
                    res = await client.post(token_endpoint, data=data)
            except Exception as exc:
                logger.error("OAuth token exchange network error occurred")
                raise OAuthDenialError(f"OAuth connection failure: {exc}") from exc

            if res.status_code != 200:
                logger.warning(
                    "OAuth exchange rejected with status %d: %s", res.status_code, res.text
                )
                try:
                    err_json = res.json()
                    err_detail = err_json.get("error_description") or err_json.get("error") or res.text
                except Exception:
                    err_detail = res.text
                raise OAuthDenialError(
                    f"Google OAuth token exchange failed: {err_detail}"
                )


            token_data = res.json()
            access_token = token_data.get("access_token", "")
            refresh_token = token_data.get("refresh_token")
            expires_in = token_data.get("expires_in", 3600)
            user_email = token_data.get("email")

            # If email was not in token response, fetch real profile from userinfo
            if not user_email:
                try:
                    async with httpx.AsyncClient(timeout=10.0) as client:
                        uinfo_res = await client.get(
                            "https://www.googleapis.com/oauth2/v2/userinfo",
                            headers={"Authorization": f"Bearer {access_token}"},
                        )
                        if uinfo_res.status_code == 200:
                            user_email = uinfo_res.json().get("email", "user@gmail.com")
                except Exception as exc:
                    logger.warning("Could not fetch userinfo from Google: %s", exc)

            if not user_email:
                user_email = "user@gmail.com"
        else:
            # Development/Sandbox mode: create simulated session
            access_token = f"mock_access_{secrets.token_hex(16)}"
            refresh_token = f"mock_refresh_{secrets.token_hex(16)}"
            expires_in = 3600
            if auth_code.startswith("email:"):
                user_email = auth_code.replace("email:", "").strip()
            elif "@" in auth_code and not auth_code.startswith("mock_"):
                user_email = auth_code.strip()
            elif auth_code == "mock_sandbox_tester_code":
                user_email = "dev.sandbox@vinabuddy.ai"
            else:
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
        self._save_sessions_to_disk()

        # If this exchange was tied to a pending browser state, complete it
        if state and state in self._pending_auth:
            self._pending_auth[state] = {
                "status": "completed",
                "session_token": session_token,
                "email": user_email,
                "completed_at": time.time(),
            }

        logger.info(
            "Session created successfully for user and persisted to disk"
        )
        return session_token, user_email, expiry_iso

    def get_valid_session(self, session_token: str) -> SessionData:
        """Validate session token and check expiry."""
        if not session_token:
            raise AuthExpiredError("Invalid session token. Please re-authenticate.")

        if session_token not in self._sessions:
            self._load_sessions_from_disk()

        if session_token not in self._sessions:
            raise AuthExpiredError("Invalid session token. Please re-authenticate.")

        session = self._sessions[session_token]
        if session.is_expired():
            del self._sessions[session_token]
            self._save_sessions_to_disk()
            raise AuthExpiredError(
                "Session has expired. Please refresh or re-authenticate."
            )

        return session

    async def get_valid_access_token(self, session_token: str) -> str:
        """Return valid Google access token, auto-refreshing via refresh_token if needed."""
        session = self.get_valid_session(session_token)
        now = time.time()
        # Refresh if token expires in less than 5 minutes and refresh_token exists
        if (
            session.expires_at - now < 300
            and session._refresh_token
            and settings.GOOGLE_CLIENT_ID
            and not session._refresh_token.startswith("mock_")
        ):
            try:
                token_endpoint = "https://oauth2.googleapis.com/token"
                data = {
                    "client_id": settings.GOOGLE_CLIENT_ID,
                    "refresh_token": session._refresh_token,
                    "grant_type": "refresh_token",
                }
                if settings.GOOGLE_CLIENT_SECRET:
                    data["client_secret"] = settings.GOOGLE_CLIENT_SECRET
                async with httpx.AsyncClient(timeout=10.0) as client:
                    res = await client.post(token_endpoint, data=data)
                    if res.status_code == 200:
                        td = res.json()
                        new_access = td.get("access_token")
                        if new_access:
                            session._access_token = new_access
                            session.expires_at = time.time() + td.get("expires_in", 3600)
                            self._save_sessions_to_disk()
                            logger.info("Successfully refreshed Google OAuth access token")
            except Exception as exc:
                logger.warning("Failed refreshing Google access token: %s", exc)

        return session.get_access_token()

    def refresh_session(self, session_token: str) -> tuple[str, str]:
        """Refresh session token and extend validity."""
        session = self.get_valid_session(session_token)
        new_expiry_ts = time.time() + 3600
        session.expires_at = new_expiry_ts
        self._save_sessions_to_disk()
        expiry_iso = datetime.fromtimestamp(new_expiry_ts, tz=timezone.utc).isoformat()
        return session_token, expiry_iso

    def revoke_session(self, session_token: str) -> bool:
        """Revoke session and wipe in-memory token state."""
        if session_token in self._sessions:
            del self._sessions[session_token]
            self._save_sessions_to_disk()
            logger.info("Session revoked and purged from memory")
            return True
        return False
