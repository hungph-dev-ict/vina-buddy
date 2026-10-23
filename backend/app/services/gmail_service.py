import logging
from typing import Dict, List, Optional, Set

from app.fixtures.synthetic_emails import get_synthetic_emails
from app.schemas.gmail import (
    ApplyActionResult,
    ApplyActionsResponse,
    ApplyActionsSummary,
    EmailMetadataItem,
    GmailLabelItem,
)
from app.schemas.rules import RuleAction
from app.services.rules_service import RulesService

logger = logging.getLogger(__name__)


class GmailAPIError(Exception):
    """Exception raised for upstream Gmail API failures."""

    pass


class GmailSecurityError(Exception):
    """Raised when an unauthorized destructive action is attempted on Gmail."""

    pass


class GmailService:
    """
    Service for interacting with Gmail API or local mock mailbox with strict security guardrails.
    Never persists email content long-term and never logs email bodies.
    """

    def __init__(self, rules_service: Optional[RulesService] = None) -> None:
        self.rules_service = rules_service or RulesService()
        # In-memory mailbox state for safe testing and mock sync (simulates Gmail mailbox)
        self._mailbox: Dict[str, Dict] = {}
        self._labels: Dict[str, GmailLabelItem] = {
            "INBOX": GmailLabelItem(id="INBOX", name="INBOX", type="system"),
            "UNREAD": GmailLabelItem(id="UNREAD", name="UNREAD", type="system"),
        }
        self._init_mock_mailbox()

    def _init_mock_mailbox(self) -> None:
        """Seed mailbox with synthetic fixtures."""
        for email in get_synthetic_emails():
            self._mailbox[email.id] = {
                "id": email.id,
                "thread_id": email.thread_id,
                "from_email": email.from_email,
                "from_name": email.from_name,
                "subject": email.subject,
                "snippet": email.snippet,
                "date": email.date,
                "labels": list(email.labels),
                "has_attachments": email.has_attachments,
            }

    async def list_labels(
        self, access_token: Optional[str] = None
    ) -> List[GmailLabelItem]:
        """List all Gmail labels."""
        return list(self._labels.values())

    async def get_or_create_label(
        self, label_name: str, access_token: Optional[str] = None
    ) -> GmailLabelItem:
        """Find existing label by name or create a new user label."""
        for label in self._labels.values():
            if label.name.lower() == label_name.lower():
                return label

        # Create new label
        label_id = f"Label_{label_name.lower().replace(' ', '_')}"
        new_label = GmailLabelItem(id=label_id, name=label_name, type="user")
        self._labels[label_id] = new_label
        logger.info("Created user label: id=%s", label_id)
        return new_label

    async def fetch_recent_emails(
        self,
        max_results: int = 50,
        page_token: Optional[str] = None,
        access_token: Optional[str] = None,
    ) -> tuple[List[EmailMetadataItem], Optional[str]]:
        """
        Fetch limited recent emails (metadata headers and snippet only).
        Guaranteed: Never fetches or stores full message bodies.
        """
        # Cap max_results at 200 for safety
        limit = min(max(1, max_results), 200)

        # In-memory mock mailbox fetch (or Gmail API metadata call if token valid)
        items = list(self._mailbox.values())[:limit]
        result = [
            EmailMetadataItem(
                id=item["id"],
                thread_id=item["thread_id"],
                from_email=item["from_email"],
                from_name=item["from_name"],
                subject=item["subject"],
                snippet=item["snippet"],
                date=item["date"],
                labels=list(item["labels"]),
                has_attachments=item.get("has_attachments", False),
            )
            for item in items
        ]

        logger.info(
            "Fetched %d recent email metadata records (bodies excluded)", len(result)
        )
        return result, None

    async def apply_approved_actions(
        self,
        rule_id: str,
        approved_email_ids: List[str],
        access_token: Optional[str] = None,
        simulate_error_for_id: Optional[str] = None,
    ) -> ApplyActionsResponse:
        """
        Apply approved label changes to Gmail for the explicitly approved message IDs.
        SECURITY GUARANTEES:
        1. Only applies 'add_label' or 'remove_label'.
        2. Strictly blocks and aborts if 'delete' or 'send' is present.
        3. Idempotent: does not duplicate labels if already applied.
        4. Partial failure resilient: one failed message does not abort others.
        5. Privacy: logs only message IDs and action status, never email bodies.
        """
        rule = self.rules_service.get_rule(rule_id)
        if not rule:
            raise GmailAPIError(f"Rule with id '{rule_id}' not found.")

        # STRICT VERIFICATION: Verify no forbidden actions exist in rule
        for action in rule.actions:
            if action.type not in ("add_label", "remove_label"):
                raise GmailSecurityError(
                    f"Forbidden action '{action.type}' cannot be executed on Gmail."
                )

        results: List[ApplyActionResult] = []
        succeeded_count = 0
        failed_count = 0

        for email_id in approved_email_ids:
            # Check for simulated or upstream error on specific message
            if simulate_error_for_id and email_id == simulate_error_for_id:
                logger.warning("Upstream Gmail API error on message_id=%s", email_id)
                results.append(
                    ApplyActionResult(
                        email_id=email_id,
                        status="failed",
                        error="Upstream Gmail API error: rate limit or service unavailable",
                    )
                )
                failed_count += 1
                continue

            if email_id not in self._mailbox:
                results.append(
                    ApplyActionResult(
                        email_id=email_id,
                        status="failed",
                        error=f"Message '{email_id}' not found in mailbox",
                    )
                )
                failed_count += 1
                continue

            email_data = self._mailbox[email_id]
            current_labels: Set[str] = set(email_data.get("labels", []))
            actions_applied: List[RuleAction] = []

            try:
                for action in rule.actions:
                    label_obj = await self.get_or_create_label(
                        action.label, access_token
                    )
                    target_label_name = label_obj.name

                    if action.type == "add_label":
                        # IDEMPOTENCY CHECK: If already has label, skip cleanly without duplicate writes
                        if target_label_name not in current_labels:
                            current_labels.add(target_label_name)
                            actions_applied.append(action)
                        else:
                            logger.info(
                                "Label '%s' already present on message_id=%s. Skipped duplicate.",
                                target_label_name,
                                email_id,
                            )
                    elif action.type == "remove_label":
                        if target_label_name in current_labels:
                            current_labels.remove(target_label_name)
                            actions_applied.append(action)

                # Commit updated labels to in-memory mailbox state
                email_data["labels"] = list(current_labels)

                results.append(
                    ApplyActionResult(
                        email_id=email_id,
                        status="success",
                        actions_applied=actions_applied,
                    )
                )
                succeeded_count += 1
                logger.info(
                    "Applied actions on message_id=%s: applied_count=%d",
                    email_id,
                    len(actions_applied),
                )

            except Exception as exc:
                logger.error(
                    "Failed applying actions to message_id=%s: %s", email_id, exc
                )
                results.append(
                    ApplyActionResult(
                        email_id=email_id,
                        status="failed",
                        error=f"Action execution error: {exc}",
                    )
                )
                failed_count += 1

        summary = ApplyActionsSummary(
            total=len(approved_email_ids),
            succeeded=succeeded_count,
            failed=failed_count,
        )

        return ApplyActionsResponse(
            rule_id=rule.id,
            results=results,
            summary=summary,
        )
