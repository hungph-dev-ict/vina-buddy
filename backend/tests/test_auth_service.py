import time

import pytest

from app.services.auth_service import (
    AuthExpiredError,
    AuthService,
    OAuthDenialError,
    SessionData,
)


@pytest.fixture
def auth_service():
    return AuthService()


@pytest.mark.asyncio
async def test_oauth_denial_empty_code(auth_service):
    """Empty or whitespace authorization code is rejected immediately."""
    with pytest.raises(OAuthDenialError, match="cannot be empty"):
        await auth_service.exchange_google_code(
            auth_code="", redirect_uri="com.test:/oauth"
        )


@pytest.mark.asyncio
async def test_oauth_denial_user_cancelled(auth_service):
    """User denying Google OAuth consent raises OAuthDenialError."""
    with pytest.raises(OAuthDenialError, match="denied"):
        await auth_service.exchange_google_code(
            auth_code="error_access_denied",
            redirect_uri="com.test:/oauth",
        )


@pytest.mark.asyncio
async def test_oauth_exchange_success_creates_session(auth_service):
    """Valid OAuth code creates opaque session token without leaking raw credentials."""
    session_token, email, expires_at = await auth_service.exchange_google_code(
        auth_code="valid_mock_code_12345",
        redirect_uri="com.test:/oauth",
    )

    assert session_token.startswith("sess_")
    assert "@" in email
    assert "T" in expires_at

    # Raw access tokens / refresh tokens are kept inside server memory only
    session = auth_service.get_valid_session(session_token)
    assert session.email == email
    assert session.get_access_token().startswith("mock_access_")


def test_expired_credentials_detection(auth_service):
    """Expired credentials trigger AuthExpiredError."""
    expired_token = "sess_expired_123"
    # Seed an already expired session (expiry 10s in the past)
    auth_service._sessions[expired_token] = SessionData(
        email="expired@gmail.com",
        access_token="token",
        expires_at=time.time() - 10,
    )

    with pytest.raises(AuthExpiredError, match="expired"):
        auth_service.get_valid_session(expired_token)


def test_refresh_session_extends_validity(auth_service):
    """Active session can be refreshed, extending expiration timestamp."""
    token = "sess_active_123"
    current_time = time.time()
    auth_service._sessions[token] = SessionData(
        email="active@gmail.com",
        access_token="token",
        expires_at=current_time + 500,
    )

    refreshed_token, new_expiry = auth_service.refresh_session(token)
    assert refreshed_token == token
    assert auth_service._sessions[token].expires_at > current_time + 3000


def test_revoke_session_purges_tokens(auth_service):
    """Revoking session purges credentials completely from memory."""
    token = "sess_to_revoke"
    auth_service._sessions[token] = SessionData(
        email="user@gmail.com",
        access_token="token",
        expires_at=time.time() + 3600,
    )

    revoked = auth_service.revoke_session(token)
    assert revoked is True
    assert token not in auth_service._sessions

    with pytest.raises(AuthExpiredError):
        auth_service.get_valid_session(token)


def test_google_auth_url_configured_behavior(auth_service):
    """Generates valid OAuth consent URL when configured, or configured=False when empty."""
    from app.config import settings

    orig_id = settings.GOOGLE_CLIENT_ID
    orig_secret = settings.GOOGLE_CLIENT_SECRET
    try:
        # When unconfigured
        settings.GOOGLE_CLIENT_ID = ""
        settings.GOOGLE_CLIENT_SECRET = ""
        res_unconf = auth_service.get_google_auth_url("http://localhost:8000/callback")
        assert res_unconf["configured"] is False

        # When configured in-memory
        settings.GOOGLE_CLIENT_ID = "test-client-id.apps.googleusercontent.com"
        settings.GOOGLE_CLIENT_SECRET = "test-secret"
        res_conf = auth_service.get_google_auth_url("http://localhost:8000/callback")
        assert res_conf["configured"] is True
        assert "accounts.google.com" in res_conf["auth_url"]
        assert "test-client-id" in res_conf["auth_url"]
        assert res_conf["state"] is not None

        # Test state polling
        state = res_conf["state"]
        poll_initial = auth_service.poll_pending_auth(state)
        assert poll_initial["status"] == "pending"

        # Simulate completed login via callback
        auth_service._pending_auth[state] = {
            "status": "completed",
            "session_token": "sess_12345",
            "email": "realuser@gmail.com",
        }
        poll_after = auth_service.poll_pending_auth(state)
        assert poll_after["status"] == "completed"
        assert poll_after["email"] == "realuser@gmail.com"
    finally:
        settings.GOOGLE_CLIENT_ID = orig_id
        settings.GOOGLE_CLIENT_SECRET = orig_secret




