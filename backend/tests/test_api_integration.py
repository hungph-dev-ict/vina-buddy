import pytest
from httpx import ASGITransport, AsyncClient

from app.llm import MockFallbackProvider, ResilientLLMService
from app.main import app
from app.routers.rules import rules_service


@pytest.fixture(autouse=True)
def setup_mock_service():
    """Ensure in-memory rules service uses mock fallback provider for fast, isolated tests."""
    rules_service._rules_store.clear()
    rules_service.llm = ResilientLLMService(fallback_provider=MockFallbackProvider())


@pytest.mark.asyncio
async def test_api_create_rule_preview_and_apply_flow():
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        # 1. Authenticate
        auth_res = await client.post(
            "/api/v1/auth/google",
            json={
                "auth_code": "mock_code_abc",
                "redirect_uri": "com.vinabuddy.smartinbox:/oauth2callback",
            },
        )
        assert auth_res.status_code == 200
        session_token = auth_res.json()["session_token"]
        headers = {"Authorization": f"Bearer {session_token}"}

        # 2. Sync recent emails
        sync_res = await client.post(
            "/api/v1/gmail/sync",
            json={"max_results": 10},
            headers=headers,
        )
        assert sync_res.status_code == 200
        sync_data = sync_res.json()
        assert sync_data["total_count"] >= 1
        assert len(sync_data["emails"]) >= 1

        # 3. Create a rule
        create_res = await client.post(
            "/api/v1/rules",
            json={"natural_language": "Move newsletters to Newsletters label"},
            headers=headers,
        )
        assert create_res.status_code == 201
        rule_data = create_res.json()
        rule_id = rule_data["id"]

        # 4. Preview rule matches
        preview_res = await client.post(
            "/api/v1/classify/preview",
            json={"rule_id": rule_id},
            headers=headers,
        )
        assert preview_res.status_code == 200
        preview_data = preview_res.json()
        assert preview_data["total_matches"] == 1
        matching_email_id = preview_data["matches"][0]["email_id"]

        # 5. Apply approved actions explicitly
        apply_res = await client.post(
            "/api/v1/classify/apply",
            json={
                "rule_id": rule_id,
                "approved_email_ids": [matching_email_id],
            },
            headers=headers,
        )
        assert apply_res.status_code == 200
        apply_data = apply_res.json()
        assert apply_data["summary"]["succeeded"] == 1
        assert apply_data["summary"]["failed"] == 0
        assert apply_data["results"][0]["email_id"] == matching_email_id
        assert apply_data["results"][0]["status"] == "success"

        # 6. Duplicate apply test: re-applying the exact same approved action
        dup_res = await client.post(
            "/api/v1/classify/apply",
            json={
                "rule_id": rule_id,
                "approved_email_ids": [matching_email_id],
            },
            headers=headers,
        )
        assert dup_res.status_code == 200
        dup_data = dup_res.json()
        assert dup_data["summary"]["succeeded"] == 1
        assert dup_data["summary"]["failed"] == 0


@pytest.mark.asyncio
async def test_api_preview_nonexistent_rule_returns_404():
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        res = await client.post(
            "/api/v1/classify/preview",
            json={"rule_id": "nonexistent_rule_id"},
        )
        assert res.status_code == 404
        assert res.json()["detail"]["code"] == "NOT_FOUND"


@pytest.mark.asyncio
async def test_api_create_rule_empty_rejected_422():
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        res = await client.post(
            "/api/v1/rules",
            json={"natural_language": "a"},  # min length is 3
        )
        assert res.status_code == 422


@pytest.mark.asyncio
async def test_api_oauth_denied_returns_401():
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        res = await client.post(
            "/api/v1/auth/google",
            json={
                "auth_code": "error_user_denied",
                "redirect_uri": "com.vinabuddy.smartinbox:/oauth2callback",
            },
        )
        assert res.status_code == 401
        assert res.json()["detail"]["code"] == "OAUTH_DENIED"
