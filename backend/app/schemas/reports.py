from datetime import datetime, timezone
from typing import Optional

from pydantic import BaseModel, Field


class CreateReportRequest(BaseModel):
    user_input: str = Field(
        ...,
        min_length=1,
        max_length=1000,
        description="The natural language input that could not be supported",
    )
    reason: Optional[str] = Field(
        default="unsupported_content",
        max_length=200,
        description="Reason or categorization of the report",
    )
    user_notes: Optional[str] = Field(
        default=None,
        max_length=1000,
        description="Optional additional notes from the user for the admin",
    )
    user_email: Optional[str] = Field(
        default=None,
        max_length=200,
        description="Email of user submitting report",
    )


class ReportResponse(BaseModel):
    id: str
    status: str = "received"
    message: str
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
