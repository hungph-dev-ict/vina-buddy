from datetime import datetime, timezone
from typing import List, Literal

from pydantic import BaseModel, Field, field_validator

AllowedConditionField = Literal["from", "subject", "snippet", "label", "date"]
AllowedConditionOperator = Literal[
    "equals", "contains", "starts_with", "ends_with", "regex", "before", "after"
]
AllowedActionType = Literal["add_label", "remove_label"]


class RuleCondition(BaseModel):
    field: AllowedConditionField = Field(
        ...,
        description="Target email field to match against",
        examples=["from"],
    )
    operator: AllowedConditionOperator = Field(
        ...,
        description="Matching operator",
        examples=["contains"],
    )
    value: str = Field(
        ...,
        min_length=1,
        max_length=200,
        description="Value to compare against",
        examples=["newsletter"],
    )


class RuleAction(BaseModel):
    type: AllowedActionType = Field(
        ...,
        description="Safe label action to apply (delete/send forbidden)",
        examples=["add_label"],
    )
    label: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="Name of the Gmail label to add or remove",
        examples=["Newsletters"],
    )

    @field_validator("type", mode="before")
    @classmethod
    def reject_destructive_actions(cls, v: str) -> str:
        prohibited = {"delete", "send", "archive", "trash", "mark_read", "spam"}
        if isinstance(v, str) and v.lower() in prohibited:
            raise ValueError(
                f"Destructive action '{v}' is strictly prohibited by security policy."
            )
        if v not in ("add_label", "remove_label"):
            raise ValueError(
                f"Invalid action type '{v}'. Allowed types: 'add_label', 'remove_label'."
            )
        return v


class CreateRuleRequest(BaseModel):
    natural_language: str = Field(
        ...,
        min_length=3,
        max_length=500,
        description="User natural-language instruction for managing emails",
        examples=["Label emails from amazon.com as Shopping"],
    )


class RuleResponse(BaseModel):
    id: str
    name: str
    natural_language: str
    conditions: List[RuleCondition]
    actions: List[RuleAction]
    priority: int = 1
    enabled: bool = True
    llm_confidence: float = Field(default=1.0, ge=0.0, le=1.0)
    llm_provider: str = "mock"
    is_uncertain: bool = False
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
    updated_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
    sub_rules: List["RuleResponse"] = Field(default_factory=list)



class RuleListResponse(BaseModel):
    rules: List[RuleResponse]
    total: int
