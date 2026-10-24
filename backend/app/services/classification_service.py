import logging
import re
import time
from typing import Any, List, Optional

from app.fixtures.synthetic_emails import SyntheticEmail, get_synthetic_emails
from app.schemas.classification import ClassifiedMatch, PreviewResponse
from app.schemas.rules import RuleCondition, RuleResponse

logger = logging.getLogger(__name__)


class ClassificationService:
    """Evaluates emails against structured rules using synthetic fixtures."""

    def __init__(self, email_fixtures: List[SyntheticEmail] | None = None) -> None:
        self.emails = email_fixtures or get_synthetic_emails()

    def evaluate_condition(
        self, condition: RuleCondition, email: SyntheticEmail
    ) -> bool:
        """Evaluate a single rule condition against an email."""
        field_name = condition.field
        op = condition.operator
        val = condition.value.lower()

        # Extract target field text
        if field_name == "from":
            target = f"{email.from_email} {email.from_name}".lower()
        elif field_name == "subject":
            target = email.subject.lower()
        elif field_name == "snippet":
            target = email.snippet.lower()
        elif field_name == "label":
            target = " ".join(email.labels).lower()
        elif field_name == "date":
            target = email.date.lower()
        else:
            return False

        # Apply operator
        if op == "contains":
            return val in target
        elif op == "equals":
            return val == target.strip()
        elif op == "starts_with":
            return target.strip().startswith(val)
        elif op == "ends_with":
            return target.strip().endswith(val)
        elif op == "regex":
            try:
                return bool(re.search(condition.value, target, re.IGNORECASE))
            except re.error:
                return False
        return False

    def preview_rule(
        self,
        rule: RuleResponse,
        emails: Optional[List[Any]] = None,
    ) -> PreviewResponse:
        """
        Evaluate rule against emails (real metadata or synthetic set) and return preview with proposed actions.
        Enforces privacy: NEVER logs email bodies. Logs only email IDs.
        """
        start_time = time.perf_counter()
        matches: List[ClassifiedMatch] = []
        target_emails = emails if emails is not None else self.emails

        for email in target_emails:
            matched_conditions = []
            for cond in rule.conditions:
                if self.evaluate_condition(cond, email):
                    matched_conditions.append(
                        f"{cond.field} {cond.operator} '{cond.value}'"
                    )

            # In rule evaluation, all conditions must match (AND semantics)
            if matched_conditions and len(matched_conditions) == len(rule.conditions):
                matches.append(
                    ClassifiedMatch(
                        email_id=email.id,
                        subject=email.subject,
                        from_email=email.from_email,
                        proposed_actions=rule.actions,
                        confidence=rule.llm_confidence,
                        is_uncertain=rule.is_uncertain,
                        matched_conditions=matched_conditions,
                    )
                )

        elapsed_ms = int((time.perf_counter() - start_time) * 1000)
        logger.info(
            "Rule preview evaluated: rule_id=%s matches=%d/%d elapsed_ms=%d",
            rule.id,
            len(matches),
            len(target_emails),
            elapsed_ms,
        )

        return PreviewResponse(
            rule_id=rule.id,
            rule_name=rule.name,
            matches=matches,
            total_matches=len(matches),
            total_emails_evaluated=len(target_emails),
            evaluation_time_ms=elapsed_ms,
            provider_used=rule.llm_provider,
        )
