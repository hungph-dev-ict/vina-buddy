from typing import List

from pydantic import BaseModel, Field

from app.schemas.rules import RuleAction


class ClassifiedMatch(BaseModel):
    email_id: str
    subject: str
    from_email: str
    proposed_actions: List[RuleAction]
    confidence: float = Field(ge=0.0, le=1.0)
    is_uncertain: bool = False
    matched_conditions: List[str] = Field(default_factory=list)


class PreviewRequest(BaseModel):
    rule_id: str = Field(..., description="ID of the rule to preview against emails")


class PreviewResponse(BaseModel):
    rule_id: str
    rule_name: str
    matches: List[ClassifiedMatch]
    total_matches: int
    total_emails_evaluated: int
    evaluation_time_ms: int
    provider_used: str
