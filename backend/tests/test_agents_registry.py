import pytest
from httpx import ASGITransport, AsyncClient
from app.main import app
from app.agents.registry import AgentRegistry


def test_agent_registry_discovers_all_agents():
    registry = AgentRegistry()
    agents = registry.list_agents()
    assert len(agents) >= 4

    agent_ids = [a.id for a in agents]
    assert "thay_cung" in agent_ids
    assert "thu_ky_email" in agent_ids
    assert "ke_toan_chi_tieu" in agent_ids
    assert "it_support" in agent_ids


def test_agent_definition_contains_permissions_and_capabilities():
    registry = AgentRegistry()
    thay_cung = registry.get_agent("thay_cung")
    assert thay_cung is not None
    assert thay_cung.default_name == "Thầy Cúng"
    assert thay_cung.required_permissions == []
    assert len(thay_cung.definition.capabilities) >= 3

    thu_ky = registry.get_agent("thu_ky_email")
    assert thu_ky is not None
    assert len(thu_ky.required_permissions) > 0
    assert "https://www.googleapis.com/auth/gmail.modify" in thu_ky.required_permissions


@pytest.mark.asyncio
async def test_api_list_agents_endpoint():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.get("/api/v1/assistant/agents")
        assert res.status_code == 200
        agents_data = res.json()
        assert isinstance(agents_data, list)
        assert len(agents_data) >= 4
        ids = [a["id"] for a in agents_data]
        assert "thay_cung" in ids
        assert "thu_ky_email" in ids
