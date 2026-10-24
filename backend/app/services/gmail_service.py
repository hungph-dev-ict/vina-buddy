import asyncio
import logging
from typing import Any, Dict, List, Optional, Set

from datetime import datetime, timezone
import httpx

from app.fixtures.synthetic_emails import get_synthetic_emails
from app.schemas.assistant import (
    EmailCategoryStat,
    EmailClassifyCategory,
    EmailClassifyPayload,
    EmailStatsPayload,
    TopSenderStat,
)
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

    def _is_real_google_token(self, token: Optional[str]) -> bool:
        """Check if access token is a genuine Google OAuth token."""
        return bool(token and not token.startswith("mock_") and not token.startswith("sess_"))

    async def list_labels(
        self, access_token: Optional[str] = None
    ) -> List[GmailLabelItem]:
        """List all Gmail labels (from Google API if live token, or mock)."""
        if self._is_real_google_token(access_token):
            try:
                headers = {"Authorization": f"Bearer {access_token}"}
                async with httpx.AsyncClient(timeout=10.0) as client:
                    res = await client.get("https://gmail.googleapis.com/gmail/v1/users/me/labels", headers=headers)
                    if res.status_code == 200:
                        raw_labels = res.json().get("labels", [])
                        return [
                            GmailLabelItem(
                                id=lbl["id"],
                                name=lbl["name"],
                                type="system" if lbl.get("type") == "system" else "user",
                            )
                            for lbl in raw_labels
                        ]
            except Exception as exc:
                logger.warning("Failed to fetch real labels from Gmail API (%s). Falling back.", exc)

        return list(self._labels.values())

    async def get_or_create_label(
        self, label_name: str, access_token: Optional[str] = None
    ) -> GmailLabelItem:
        """Find existing label by name or create a new user label."""
        if self._is_real_google_token(access_token):
            try:
                headers = {"Authorization": f"Bearer {access_token}"}
                async with httpx.AsyncClient(timeout=10.0) as client:
                    res = await client.get("https://gmail.googleapis.com/gmail/v1/users/me/labels", headers=headers)
                    if res.status_code == 200:
                        raw_labels = res.json().get("labels", [])
                        for lbl in raw_labels:
                            if lbl.get("name", "").lower() == label_name.lower():
                                return GmailLabelItem(
                                    id=lbl["id"],
                                    name=lbl["name"],
                                    type=lbl.get("type", "user"),
                                )
                        # Not found, create it in real Gmail
                        create_res = await client.post(
                            "https://gmail.googleapis.com/gmail/v1/users/me/labels",
                            headers=headers,
                            json={
                                "name": label_name,
                                "labelListVisibility": "labelShow",
                                "messageListVisibility": "show",
                            },
                        )
                        if create_res.status_code in (200, 201):
                            created = create_res.json()
                            return GmailLabelItem(
                                id=created["id"],
                                name=created["name"],
                                type="user",
                            )
            except Exception as exc:
                logger.warning("Failed get_or_create_label on real Gmail API (%s)", exc)

        for label in self._labels.values():
            if label.name.lower() == label_name.lower():
                return label

        # Create new local label
        label_id = f"Label_{label_name.lower().replace(' ', '_')}"
        new_label = GmailLabelItem(id=label_id, name=label_name, type="user")
        self._labels[label_id] = new_label
        logger.info("Created user label: id=%s", label_id)
        return new_label

    async def _fetch_single_message_metadata(
        self, client: httpx.AsyncClient, headers: Dict[str, str], message_id: str
    ) -> Optional[EmailMetadataItem]:
        """Fetch header metadata and snippet only. Enforces ZERO body storage/logging."""
        try:
            url = (
                f"https://gmail.googleapis.com/gmail/v1/users/me/messages/{message_id}?"
                "format=metadata&metadataHeaders=From&metadataHeaders=Subject&metadataHeaders=Date"
            )
            res = await client.get(url, headers=headers)
            if res.status_code != 200:
                return None
            m = res.json()
            p_headers = m.get("payload", {}).get("headers", [])
            h_map = {h.get("name", "").lower(): h.get("value", "") for h in p_headers}

            raw_from = h_map.get("from", "unknown@gmail.com")
            subject = h_map.get("subject", "(Không có tiêu đề)")
            date_str = h_map.get("date", "")

            from_name = raw_from
            from_email = raw_from
            if "<" in raw_from and ">" in raw_from:
                parts = raw_from.split("<")
                from_name = parts[0].strip().strip('"')
                from_email = parts[1].replace(">", "").strip()

            labels = m.get("labelIds", [])
            snippet = m.get("snippet", "")
            thread_id = m.get("threadId", message_id)

            return EmailMetadataItem(
                id=message_id,
                thread_id=thread_id,
                from_email=from_email,
                from_name=from_name,
                subject=subject,
                snippet=snippet,
                date=date_str,
                labels=labels,
                has_attachments=False,
            )
        except Exception as exc:
            logger.warning("Error fetching metadata for msg %s: %s", message_id, exc)
            return None

    async def _fetch_real_gmail_emails(
        self,
        access_token: str,
        max_results: int = 50,
        page_token: Optional[str] = None,
    ) -> tuple[List[EmailMetadataItem], Optional[str]]:
        """Fetch real emails from Google Gmail API."""
        limit = min(max(1, max_results), 20)
        headers = {"Authorization": f"Bearer {access_token}"}
        url = f"https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults={limit}"
        if page_token:
            url += f"&pageToken={page_token}"

        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                res = await client.get(url, headers=headers)
                if res.status_code != 200:
                    logger.warning("Gmail API messages list failed: %d %s", res.status_code, res.text)
                    err_text = res.text
                    if "SERVICE_DISABLED" in err_text or "has not been used" in err_text:
                        raise GmailAPIError(
                            "Gmail API chưa được kích hoạt trong Google Cloud Project của bạn (Project 548888108664).\n\n"
                            "👉 Hãy truy cập link sau và nhấn 'ENABLE' (Bật):\n"
                            "https://console.developers.google.com/apis/api/gmail.googleapis.com/overview?project=548888108664\n\n"
                            "Sau khi bật, đợi 30 giây rồi bấm lại 'Thống kê email' để xem thư thật!"
                        )
                    if res.status_code == 401:
                        raise GmailAPIError("Phiên đăng nhập Google đã hết hạn. Vui lòng đăng nhập lại.")
                    if res.status_code == 403:
                        raise GmailAPIError(
                            "Tài khoản chưa được cấp đủ quyền đọc Gmail. Vui lòng đăng xuất và đăng nhập lại, lưu ý tích chọn tất cả các quyền Gmail."
                        )
                    raise GmailAPIError(f"Google Gmail API trả về mã lỗi {res.status_code}: {res.text}")

                data = res.json()
                msg_items = data.get("messages", [])
                next_page = data.get("nextPageToken")

                if not msg_items:
                    return [], None

                semaphore = asyncio.Semaphore(6)

                async def fetch_sem(mid: str):
                    async with semaphore:
                        return await self._fetch_single_message_metadata(client, headers, mid)

                tasks = [fetch_sem(m["id"]) for m in msg_items[:limit]]
                fetched = await asyncio.gather(*tasks, return_exceptions=True)
                email_records: List[EmailMetadataItem] = []
                for item in fetched:
                    if isinstance(item, EmailMetadataItem):
                        email_records.append(item)
                        # Seed or update mailbox cache with real message metadata
                        self._mailbox[item.id] = {
                            "id": item.id,
                            "thread_id": item.thread_id,
                            "from_email": item.from_email,
                            "from_name": item.from_name,
                            "subject": item.subject,
                            "snippet": item.snippet,
                            "date": item.date,
                            "labels": list(item.labels),
                            "has_attachments": item.has_attachments,
                        }
                if email_records:
                    for k in list(self._mailbox.keys()):
                        if k.startswith("email_0"):
                            del self._mailbox[k]
                logger.info("Fetched %d real Gmail messages from Google API", len(email_records))
                return email_records, next_page
        except GmailAPIError:
            raise
        except Exception as exc:
            logger.error("Exception fetching real Gmail emails: %s", exc)
            raise GmailAPIError(f"Lỗi kết nối tới Google Gmail API: {exc}") from exc

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
        if self._is_real_google_token(access_token):
            return await self._fetch_real_gmail_emails(
                access_token=access_token,
                max_results=max_results,
                page_token=page_token,
            )

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

    async def _apply_real_gmail_actions(
        self,
        rule,
        approved_email_ids: List[str],
        access_token: str,
    ) -> ApplyActionsResponse:
        """Apply approved label actions directly to Gmail via Google API."""
        headers = {"Authorization": f"Bearer {access_token}"}
        results: List[ApplyActionResult] = []
        succeeded_count = 0
        failed_count = 0

        # Resolve or create labels in Gmail
        label_id_map: Dict[str, str] = {}
        for action in rule.actions:
            label_obj = await self.get_or_create_label(action.label, access_token=access_token)
            label_id_map[action.label] = label_obj.id

        async with httpx.AsyncClient(timeout=15.0) as client:
            for email_id in approved_email_ids:
                try:
                    add_label_ids = [label_id_map[a.label] for a in rule.actions if a.type == "add_label"]
                    remove_label_ids = [label_id_map[a.label] for a in rule.actions if a.type == "remove_label"]
                    modify_payload = {
                        "addLabelIds": add_label_ids,
                        "removeLabelIds": remove_label_ids,
                    }
                    mod_res = await client.post(
                        f"https://gmail.googleapis.com/gmail/v1/users/me/messages/{email_id}/modify",
                        json=modify_payload,
                        headers=headers,
                    )
                    if mod_res.status_code == 200:
                        results.append(
                            ApplyActionResult(
                                email_id=email_id,
                                status="success",
                                actions_applied=rule.actions,
                            )
                        )
                        succeeded_count += 1
                        if email_id in self._mailbox:
                            cur_labels = set(self._mailbox[email_id].get("labels", []))
                            for a in rule.actions:
                                if a.type == "add_label":
                                    cur_labels.add(a.label)
                            self._mailbox[email_id]["labels"] = list(cur_labels)
                    else:
                        results.append(
                            ApplyActionResult(
                                email_id=email_id,
                                status="failed",
                                error=f"Gmail API error: HTTP {mod_res.status_code}",
                            )
                        )
                        failed_count += 1
                except Exception as exc:
                    results.append(
                        ApplyActionResult(
                            email_id=email_id,
                            status="failed",
                            error=str(exc),
                        )
                    )
                    failed_count += 1

        return ApplyActionsResponse(
            rule_id=rule.id,
            results=results,
            summary=ApplyActionsSummary(
                total=len(approved_email_ids),
                succeeded=succeeded_count,
                failed=failed_count,
            ),
        )

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

        if self._is_real_google_token(access_token):
            return await self._apply_real_gmail_actions(
                rule=rule,
                approved_email_ids=approved_email_ids,
                access_token=access_token,
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

    async def get_inbox_statistics(
        self, locale: str = "vi", access_token: Optional[str] = None
    ) -> EmailStatsPayload:
        """
        Compute high-level mailbox statistics without storing or logging message bodies.
        Deterministic and privacy-safe.
        """
        if self._is_real_google_token(access_token):
            emails, _ = await self.fetch_recent_emails(
                max_results=20, access_token=access_token
            )
            items = [
                {
                    "id": e.id,
                    "from_email": e.from_email,
                    "from_name": e.from_name,
                    "subject": e.subject,
                    "snippet": e.snippet,
                    "labels": list(e.labels),
                }
                for e in emails
            ]
        else:
            items = list(self._mailbox.values())

        total = len(items)
        unread = sum(1 for item in items if "UNREAD" in item.get("labels", []))
        read = total - unread

        # Category counters
        cat_counts: Dict[str, Dict[str, int]] = {
            "newsletters": {"count": 0, "unread": 0},
            "shopping": {"count": 0, "unread": 0},
            "finance": {"count": 0, "unread": 0},
            "security": {"count": 0, "unread": 0},
            "work": {"count": 0, "unread": 0},
            "other": {"count": 0, "unread": 0},
        }

        # Sender frequencies
        sender_counts: Dict[str, Dict[str, Any]] = {}

        for item in items:
            from_email = item.get("from_email", "").lower()
            from_name = item.get("from_name", "") or from_email
            subject = item.get("subject", "").lower()
            snippet = item.get("snippet", "").lower()
            is_unread = "UNREAD" in item.get("labels", [])

            # Sender stat
            if from_email:
                if from_email not in sender_counts:
                    sender_counts[from_email] = {
                        "name": from_name,
                        "email": from_email,
                        "count": 0,
                    }
                sender_counts[from_email]["count"] += 1

            # Categorize
            assigned = False
            combined_text = f"{from_email} {from_name.lower()} {subject} {snippet}"
            if any(k in combined_text for k in ["newsletter", "brew", "tldr", "digest", "substack"]):
                cat_counts["newsletters"]["count"] += 1
                if is_unread:
                    cat_counts["newsletters"]["unread"] += 1
                assigned = True
            elif any(k in combined_text for k in ["amazon", "order", "shipped", "delivery", "cart"]):
                cat_counts["shopping"]["count"] += 1
                if is_unread:
                    cat_counts["shopping"]["unread"] += 1
                assigned = True
            elif any(k in combined_text for k in ["invoice", "receipt", "payment", "bill", "subscription"]):
                cat_counts["finance"]["count"] += 1
                if is_unread:
                    cat_counts["finance"]["unread"] += 1
                assigned = True
            elif any(k in combined_text for k in ["security", "alert", "verify", "password", "2fa", "vulnerability"]):
                cat_counts["security"]["count"] += 1
                if is_unread:
                    cat_counts["security"]["unread"] += 1
                assigned = True
            elif any(k in combined_text for k in ["sync", "roadmap", "project", "team", "meeting", "review"]):
                cat_counts["work"]["count"] += 1
                if is_unread:
                    cat_counts["work"]["unread"] += 1
                assigned = True

            if not assigned:
                cat_counts["other"]["count"] += 1
                if is_unread:
                    cat_counts["other"]["unread"] += 1

        is_vi = locale.lower() == "vi"

        categories_def = [
            ("newsletters", "Bản tin & Tin tức" if is_vi else "Newsletters", "#6366F1"),
            ("shopping", "Mua sắm & Đơn hàng" if is_vi else "Shopping & Orders", "#EC4899"),
            ("finance", "Hoá đơn & Tài chính" if is_vi else "Receipts & Finance", "#10B981"),
            ("security", "Cảnh báo bảo mật" if is_vi else "Security Alerts", "#EF4444"),
            ("work", "Công việc & Trao đổi" if is_vi else "Work & Team Sync", "#3B82F6"),
            ("other", "Khác" if is_vi else "Other", "#64748B"),
        ]

        categories_res = [
            EmailCategoryStat(
                category_id=cid,
                category_name=cname,
                count=cat_counts[cid]["count"],
                unread=cat_counts[cid]["unread"],
                color_hex=color,
            )
            for cid, cname, color in categories_def
            if cat_counts[cid]["count"] > 0
        ]

        # Top senders sorted by count
        top_senders_sorted = sorted(
            sender_counts.values(), key=lambda s: s["count"], reverse=True
        )[:5]

        top_senders = [
            TopSenderStat(
                sender_name=s["name"],
                sender_email=s["email"],
                count=s["count"],
            )
            for s in top_senders_sorted
        ]

        return EmailStatsPayload(
            total_emails=total,
            unread_emails=unread,
            read_emails=read,
            categories=categories_res,
            top_senders=top_senders,
            last_synced_at=datetime.now(timezone.utc).isoformat(),
        )

    async def get_inbox_classification(
        self, locale: str = "vi", access_token: Optional[str] = None
    ) -> EmailClassifyPayload:
        """
        Classifies recent emails into structured categories with suggested label actions.
        """
        stats = await self.get_inbox_statistics(
            locale=locale, access_token=access_token
        )
        is_vi = locale.lower() == "vi"

        items = list(self._mailbox.values())
        categories: List[EmailClassifyCategory] = []

        # Find sample senders for each
        for cat in stats.categories:
            sample_senders: List[str] = []
            for item in items:
                from_name = item.get("from_name", "") or item.get("from_email", "")
                subject = item.get("subject", "").lower()
                combined = f"{item.get('from_email', '')} {from_name.lower()} {subject}".lower()
                matches = False

                if cat.category_id == "newsletters" and any(k in combined for k in ["newsletter", "brew", "tldr", "digest"]):
                    matches = True
                elif cat.category_id == "shopping" and any(k in combined for k in ["amazon", "order", "shipped"]):
                    matches = True
                elif cat.category_id == "finance" and any(k in combined for k in ["invoice", "receipt", "payment"]):
                    matches = True
                elif cat.category_id == "security" and any(k in combined for k in ["security", "alert"]):
                    matches = True
                elif cat.category_id == "work" and any(k in combined for k in ["sync", "roadmap", "project"]):
                    matches = True

                if matches and from_name not in sample_senders:
                    sample_senders.append(from_name)
                    if len(sample_senders) >= 3:
                        break

            desc = ""
            label = ""
            if cat.category_id == "newsletters":
                desc = "Các email tin tức, bài viết định kỳ từ các nguồn đăng ký" if is_vi else "Newsletters and curated digest subscriptions"
                label = "Newsletters"
            elif cat.category_id == "shopping":
                desc = "Xác nhận mua sắm, trạng thái vận chuyển và thông tin đơn hàng" if is_vi else "E-commerce orders and shipping notifications"
                label = "Shopping"
            elif cat.category_id == "finance":
                desc = "Biên lai thanh toán định kỳ, hoá đơn điện tử" if is_vi else "Payment receipts, invoices and billing statements"
                label = "Finance"
            elif cat.category_id == "security":
                desc = "Cảnh báo bảo mật hệ thống, mã xác thực và đăng nhập" if is_vi else "Security advisories and authentication notices"
                label = "Security"
            elif cat.category_id == "work":
                desc = "Trao đổi công việc nội bộ và cập nhật tiến độ dự án" if is_vi else "Team coordination and work updates"
                label = "Work"
            else:
                desc = "Các thư thông báo và cập nhật hệ thống chung" if is_vi else "General notifications and other messages"
                label = "General"

            categories.append(
                EmailClassifyCategory(
                    category_id=cat.category_id,
                    category_name=cat.category_name,
                    description=desc,
                    matched_count=cat.count,
                    sample_senders=sample_senders,
                    suggested_label=label,
                )
            )

        return EmailClassifyPayload(
            total_analyzed=stats.total_emails,
            categories=categories,
        )

