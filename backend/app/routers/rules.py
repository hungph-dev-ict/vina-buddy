from fastapi import APIRouter, HTTPException, status

from app.llm.base import (
    LLMProviderError,
    LLMQuotaExceededError,
    LLMTimeoutError,
    LLMUnsupportedContentError,
    LLMValidationError,
)
from app.schemas.rules import (
    CreateRuleRequest,
    RuleListResponse,
    RuleResponse,
)
from app.services.rules_service import RulesService

router = APIRouter(tags=["Rules"])

# Shared service instance for in-memory PoC state
rules_service = RulesService()


@router.post(
    "/rules",
    response_model=RuleResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create rule from natural language description",
)
async def create_rule(request: CreateRuleRequest) -> RuleResponse:
    try:
        return await rules_service.create_rule_from_text(request)
    except LLMUnsupportedContentError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "UNSUPPORTED_CONTENT", "message": str(exc)},
        ) from exc
    except LLMQuotaExceededError as exc:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={"code": "RATE_LIMITED", "message": str(exc)},
        ) from exc
    except LLMTimeoutError as exc:
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail={"code": "LLM_TIMEOUT", "message": str(exc)},
        ) from exc
    except LLMValidationError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "VALIDATION_ERROR", "message": str(exc)},
        ) from exc
    except LLMProviderError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"code": "LLM_ERROR", "message": str(exc)},
        ) from exc



@router.get(
    "/rules",
    response_model=RuleListResponse,
    summary="List all rules",
)
async def list_rules() -> RuleListResponse:
    rules = rules_service.list_rules()
    return RuleListResponse(rules=rules, total=len(rules))


@router.get(
    "/rules/{rule_id}",
    response_model=RuleResponse,
    summary="Get rule by ID",
)
async def get_rule(rule_id: str) -> RuleResponse:
    rule = rules_service.get_rule(rule_id)
    if not rule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "NOT_FOUND", "message": f"Rule '{rule_id}' not found"},
        )
    return rule


@router.delete(
    "/rules/{rule_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete rule by ID",
)
async def delete_rule(rule_id: str) -> None:
    deleted = rules_service.delete_rule(rule_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "NOT_FOUND", "message": f"Rule '{rule_id}' not found"},
        )


@router.patch(
    "/rules/{rule_id}",
    response_model=RuleResponse,
    summary="Enable or disable a rule",
)
async def toggle_rule(rule_id: str, enabled: bool) -> RuleResponse:
    updated = rules_service.toggle_rule(rule_id, enabled)
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "NOT_FOUND", "message": f"Rule '{rule_id}' not found"},
        )
    return updated
