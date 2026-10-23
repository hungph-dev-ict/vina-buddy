import json

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from app.routers.reports import REPORTS_FILE
from app.schemas.rules import CreateRuleRequest
from app.services.rules_service import RulesService


@pytest.mark.asyncio
async def test_multi_intent_rule_separation():
    """
    Verify compound request with multiple conditions/actions is separated into
    distinct rules:
    'emails from tldr are spam and emails from GitHub are source code'
    -> Rule 1: from tldr -> Spam
    -> Rule 2: from GitHub -> Source Code
    """
    service = RulesService()
    request = CreateRuleRequest(
        natural_language="emails from tldr are spam and emails from GitHub are source code"
    )
    rule = await service.create_rule_from_text(request)

    # Primary rule corresponds to condition 1 & label 1
    assert rule.id.startswith("rule_")
    assert len(rule.conditions) == 1
    assert rule.conditions[0].field == "from"
    assert rule.conditions[0].value == "tldr"
    assert len(rule.actions) == 1
    assert rule.actions[0].label.lower() == "spam"

    # Sub-rule corresponds to condition 2 & label 2
    assert len(rule.sub_rules) == 1
    sub_rule = rule.sub_rules[0]
    assert sub_rule.id.startswith("rule_")
    assert sub_rule.id != rule.id
    assert len(sub_rule.conditions) == 1
    assert sub_rule.conditions[0].field == "from"
    assert sub_rule.conditions[0].value.lower() == "github"
    assert len(sub_rule.actions) == 1
    assert sub_rule.actions[0].label.lower() in ("source code", "source_code")

    # Both rules are persisted in the service store
    all_rules = service.list_rules()
    assert len(all_rules) == 2
    rule_ids = [r.id for r in all_rules]
    assert rule.id in rule_ids
    assert sub_rule.id in rule_ids


@pytest.mark.asyncio
async def test_out_of_scope_input_returns_unsupported_content_error():
    """
    Verify out-of-scope input returns 422 with UNSUPPORTED_CONTENT.
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.post(
            "/api/v1/rules",
            json={"natural_language": "thời tiết hôm nay thế nào"},
        )
        assert res.status_code == 422
        data = res.json()
        assert data["detail"]["code"] == "UNSUPPORTED_CONTENT"
        assert "không thể hỗ trợ" in data["detail"]["message"]
        assert "admin" in data["detail"]["message"].lower()


@pytest.mark.asyncio
async def test_submit_admin_report_persists_to_file():
    """
    Verify POST /api/v1/reports saves report record to server-side JSONL file.
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        payload = {
            "user_input": "thời tiết hôm nay thế nào",
            "reason": "unsupported_content",
            "user_notes": "Tôi muốn thêm tính năng dự báo thời tiết trong app",
            "user_email": "tester@example.com",
        }
        res = await client.post("/api/v1/reports", json=payload)
        assert res.status_code == 201
        data = res.json()
        assert data["id"].startswith("report_")
        assert data["status"] == "received"

        # Check that file exists and contains the entry
        assert REPORTS_FILE.exists()
        with open(REPORTS_FILE, "r", encoding="utf-8") as f:
            lines = [json.loads(line) for line in f if line.strip()]
        matching = [rec for rec in lines if rec["id"] == data["id"]]
        assert len(matching) == 1
        assert matching[0]["user_input"] == payload["user_input"]
        assert matching[0]["user_email"] == payload["user_email"]
        assert matching[0]["user_notes"] == payload["user_notes"]
