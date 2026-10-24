import pytest

from app.schemas.rules import RuleAction, RuleCondition, RuleResponse
from app.services.gmail_service import (
    GmailAPIError,
    GmailSecurityError,
    GmailService,
)
from app.services.rules_service import RulesService


@pytest.fixture
def test_setup():
    rules_svc = RulesService()
    # Register a valid test rule
    rule = RuleResponse(
        id="rule_finance",
        name="Finance Receipts",
        natural_language="Label receipts as Finance",
        conditions=[
            RuleCondition(field="subject", operator="contains", value="invoice")
        ],
        actions=[RuleAction(type="add_label", label="Finance")],
        llm_confidence=0.95,
        llm_provider="test",
        is_uncertain=False,
    )
    rules_svc._rules_store[rule.id] = rule
    gmail_svc = GmailService(rules_service=rules_svc)
    return gmail_svc, rule


@pytest.mark.asyncio
async def test_fetch_recent_emails_respects_limits_and_excludes_full_bodies(test_setup):
    """Sync fetches limited messages with metadata headers & snippet only; full body excluded."""
    gmail_svc, _ = test_setup
    emails, next_token = await gmail_svc.fetch_recent_emails(max_results=3)

    assert len(emails) == 3
    for email in emails:
        assert email.id.startswith("email_")
        assert email.subject != ""
        assert len(email.snippet) < 300
        # Assert object does not hold or expose raw email body
        assert not hasattr(email, "raw_body")
        assert not hasattr(email, "full_content")


@pytest.mark.asyncio
async def test_duplicate_apply_is_idempotent(test_setup):
    """Applying an add_label action twice to the same email does not duplicate labels or error."""
    gmail_svc, rule = test_setup
    target_email_id = "email_shop_002"  # Apple invoice in synthetic fixture

    # 1st Apply: label 'Finance' added
    first_res = await gmail_svc.apply_approved_actions(
        rule_id=rule.id,
        approved_email_ids=[target_email_id],
    )
    assert first_res.summary.succeeded == 1
    assert first_res.results[0].status == "success"
    assert len(first_res.results[0].actions_applied) == 1
    assert "Finance" in gmail_svc._mailbox[target_email_id]["labels"]

    # 2nd Apply: label already present -> skipped duplicate cleanly, still succeeds
    second_res = await gmail_svc.apply_approved_actions(
        rule_id=rule.id,
        approved_email_ids=[target_email_id],
    )
    assert second_res.summary.succeeded == 1
    assert second_res.results[0].status == "success"
    # Redundant action not re-applied
    assert len(second_res.results[0].actions_applied) == 0
    # No duplicate entries in labels array
    labels_list = gmail_svc._mailbox[target_email_id]["labels"]
    assert labels_list.count("Finance") == 1


@pytest.mark.asyncio
async def test_partial_failure_handling(test_setup):
    """When one email fails upstream, others succeed and partial failure summary is returned."""
    gmail_svc, rule = test_setup
    good_id = "email_shop_001"
    failing_id = "email_news_001"

    response = await gmail_svc.apply_approved_actions(
        rule_id=rule.id,
        approved_email_ids=[good_id, failing_id],
        simulate_error_for_id=failing_id,
    )

    assert response.summary.total == 2
    assert response.summary.succeeded == 1
    assert response.summary.failed == 1

    # Good email succeeded
    assert response.results[0].email_id == good_id
    assert response.results[0].status == "success"

    # Failing email reported error without blocking batch
    assert response.results[1].email_id == failing_id
    assert response.results[1].status == "failed"
    assert "rate limit or service unavailable" in response.results[1].error


@pytest.mark.asyncio
async def test_apply_nonexistent_rule_raises_api_error(test_setup):
    gmail_svc, _ = test_setup
    with pytest.raises(GmailAPIError, match="not found"):
        await gmail_svc.apply_approved_actions(
            rule_id="invalid_rule_id",
            approved_email_ids=["email_shop_001"],
        )


@pytest.mark.asyncio
async def test_destructive_actions_strictly_blocked_by_security_guardrail():
    """Attempting to execute delete or send actions on Gmail raises GmailSecurityError."""
    rules_svc = RulesService()
    # Bypass Pydantic schema validation directly to test service-level defense-in-depth guardrail
    malicious_rule = RuleResponse.model_construct(
        id="rule_malicious",
        name="Delete All",
        natural_language="Delete all emails",
        conditions=[RuleCondition(field="from", operator="contains", value="spam")],
        actions=[RuleAction.model_construct(type="delete", label="TRASH")],
        priority=1,
        enabled=True,
    )
    rules_svc._rules_store[malicious_rule.id] = malicious_rule
    gmail_svc = GmailService(rules_service=rules_svc)

    with pytest.raises(GmailSecurityError, match="Forbidden action 'delete'"):
        await gmail_svc.apply_approved_actions(
            rule_id=malicious_rule.id,
            approved_email_ids=["email_news_001"],
        )


def test_real_google_token_classification(test_setup):
    """Accurately distinguishes mock/session tokens from genuine Google tokens."""
    gmail_svc, _ = test_setup
    assert not gmail_svc._is_real_google_token(None)
    assert not gmail_svc._is_real_google_token("mock_access_12345")
    assert not gmail_svc._is_real_google_token("sess_safe_token_abc")
    assert gmail_svc._is_real_google_token("ya29.a0ARrdaM-example-google-token")
    assert gmail_svc._is_real_google_token("google_oauth_token_xyz")

