from app.fixtures.synthetic_emails import SYNTHETIC_EMAILS
from app.schemas.rules import RuleAction, RuleCondition, RuleResponse
from app.services.classification_service import ClassificationService


def test_classify_newsletter_rule():
    service = ClassificationService(email_fixtures=SYNTHETIC_EMAILS)
    rule = RuleResponse(
        id="rule_news_test",
        name="Newsletters",
        natural_language="Tag newsletters",
        conditions=[
            RuleCondition(field="from", operator="contains", value="newsletter")
        ],
        actions=[RuleAction(type="add_label", label="Newsletters")],
        llm_confidence=0.95,
        llm_provider="test",
        is_uncertain=False,
    )

    preview = service.preview_rule(rule)
    assert preview.rule_id == "rule_news_test"
    assert preview.total_matches == 1
    assert preview.matches[0].email_id == "email_news_001"
    assert preview.matches[0].proposed_actions[0].label == "Newsletters"
    assert preview.evaluation_time_ms >= 0


def test_classify_shopping_order_rule():
    service = ClassificationService(email_fixtures=SYNTHETIC_EMAILS)
    rule = RuleResponse(
        id="rule_shop_test",
        name="Amazon Orders",
        natural_language="Label orders from amazon",
        conditions=[
            RuleCondition(field="from", operator="contains", value="amazon.com"),
            RuleCondition(field="subject", operator="contains", value="shipped"),
        ],
        actions=[RuleAction(type="add_label", label="Shopping")],
        llm_confidence=0.96,
        llm_provider="test",
        is_uncertain=False,
    )

    preview = service.preview_rule(rule)
    assert preview.total_matches == 1
    assert preview.matches[0].email_id == "email_shop_001"
    assert preview.matches[0].subject == "Your order #112-9842109 has shipped"


def test_classify_security_rule():
    service = ClassificationService(email_fixtures=SYNTHETIC_EMAILS)
    rule = RuleResponse(
        id="rule_sec_test",
        name="Security Alerts",
        natural_language="Label security alerts",
        conditions=[
            RuleCondition(field="subject", operator="contains", value="security")
        ],
        actions=[RuleAction(type="add_label", label="Security")],
        llm_confidence=0.90,
        llm_provider="test",
        is_uncertain=False,
    )

    preview = service.preview_rule(rule)
    assert preview.total_matches == 1
    assert preview.matches[0].email_id == "email_dev_001"
