from datetime import datetime, timezone
from typing import List, Optional

from pydantic import BaseModel, Field

from app.schemas.rules import RuleAction


class EmailMetadataItem(BaseModel):
    id: str
    thread_id: str
    from_email: str
    from_name: str
    subject: str
    snippet: str
    date: str
    labels: List[str] = Field(default_factory=list)
    has_attachments: bool = False


class SyncEmailsRequest(BaseModel):
    max_results: int = Field(
        default=50, ge=1, le=200, description="Max emails to fetch"
    )
    page_token: Optional[str] = Field(
        default=None, description="Optional pagination token"
    )


class SyncEmailsResponse(BaseModel):
    emails: List[EmailMetadataItem]
    total_count: int
    next_page_token: Optional[str] = None
    synced_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )


class GmailLabelItem(BaseModel):
    id: str
    name: str
    type: str = "user"


class GmailLabelsResponse(BaseModel):
    labels: List[GmailLabelItem]


class ApplyActionsRequest(BaseModel):
    rule_id: str = Field(..., description="ID of the approved rule to apply")
    approved_email_ids: List[str] = Field(
        ..., min_length=1, description="List of email IDs explicitly approved by user"
    )


class ApplyActionResult(BaseModel):
    email_id: str
    status: str = Field(..., description="success | failed | skipped_already_applied")
    actions_applied: List[RuleAction] = Field(default_factory=list)
    error: Optional[str] = None


class ApplyActionsSummary(BaseModel):
    total: int
    succeeded: int
    failed: int


class ApplyActionsResponse(BaseModel):
    rule_id: str
    results: List[ApplyActionResult]
    summary: ApplyActionsSummary
