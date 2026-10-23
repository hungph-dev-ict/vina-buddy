import pytest

from app.llm import MockFallbackProvider, ResilientLLMService
from app.schemas.rules import CreateRuleRequest, RuleAction
from app.services.rules_service import RulesService


@pytest.fixture
def mock_rules_service():
    service = ResilientLLMService(fallback_provider=MockFallbackProvider())
    return RulesService(llm_service=service)


@pytest.mark.asyncio
async def test_create_valid_newsletter_rule(mock_rules_service):
    request = CreateRuleRequest(
        natural_language="Move newsletters to Newsletters label"
    )
    rule = await mock_rules_service.create_rule_from_text(request)

    assert rule.id.startswith("rule_")
    assert rule.name == "Newsletters"
    assert len(rule.conditions) == 1
    assert rule.conditions[0].field == "from"
    assert rule.conditions[0].operator == "contains"
    assert rule.conditions[0].value == "newsletter"
    assert len(rule.actions) == 1
    assert rule.actions[0].type == "add_label"
    assert rule.actions[0].label == "Newsletters"
    assert rule.is_uncertain is False


@pytest.mark.asyncio
async def test_create_rule_flags_uncertainty_for_low_confidence(mock_rules_service):
    # Short generic prompt that mock provider assigns 0.60 confidence to (< 0.70 threshold)
    request = CreateRuleRequest(natural_language="organize my random stuff")
    rule = await mock_rules_service.create_rule_from_text(request)

    assert rule.llm_confidence < 0.70
    assert rule.is_uncertain is True


def test_rule_action_rejects_delete_action():
    with pytest.raises(ValueError, match="strictly prohibited"):
        RuleAction(type="delete", label="Trash")


def test_rule_action_rejects_send_action():
    with pytest.raises(ValueError, match="strictly prohibited"):
        RuleAction(type="send", label="Outbox")


def test_rule_action_rejects_archive_action():
    with pytest.raises(ValueError, match="strictly prohibited"):
        RuleAction(type="archive", label="Archive")


@pytest.mark.asyncio
async def test_rule_crud_operations(mock_rules_service):
    request = CreateRuleRequest(
        natural_language="Label emails from amazon.com as Shopping"
    )
    rule = await mock_rules_service.create_rule_from_text(request)

    # Get by ID
    retrieved = mock_rules_service.get_rule(rule.id)
    assert retrieved is not None
    assert retrieved.id == rule.id

    # List rules
    all_rules = mock_rules_service.list_rules()
    assert len(all_rules) >= 1

    # Toggle enabled
    toggled = mock_rules_service.toggle_rule(rule.id, enabled=False)
    assert toggled is not None
    assert toggled.enabled is False

    # Delete
    deleted = mock_rules_service.delete_rule(rule.id)
    assert deleted is True
    assert mock_rules_service.get_rule(rule.id) is None
