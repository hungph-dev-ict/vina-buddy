from fastapi import APIRouter, HTTPException, status

from app.routers.rules import rules_service
from app.schemas.classification import PreviewRequest, PreviewResponse
from app.schemas.gmail import ApplyActionsRequest, ApplyActionsResponse
from app.services.classification_service import ClassificationService
from app.services.gmail_service import (
    GmailAPIError,
    GmailSecurityError,
    GmailService,
)

router = APIRouter(tags=["Classification"])

classification_service = ClassificationService()
gmail_service = GmailService(rules_service=rules_service)


@router.post(
    "/classify/preview",
    response_model=PreviewResponse,
    summary="Preview matching emails and proposed actions for a rule",
)
async def preview_rule(request: PreviewRequest) -> PreviewResponse:
    rule = rules_service.get_rule(request.rule_id)
    if not rule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "code": "NOT_FOUND",
                "message": f"Rule with id '{request.rule_id}' was not found",
            },
        )

    return classification_service.preview_rule(rule)


@router.post(
    "/classify/apply",
    response_model=ApplyActionsResponse,
    summary="Apply user-approved Gmail actions (labels only)",
)
async def apply_actions(request: ApplyActionsRequest) -> ApplyActionsResponse:
    try:
        return await gmail_service.apply_approved_actions(
            rule_id=request.rule_id,
            approved_email_ids=request.approved_email_ids,
        )
    except GmailSecurityError as exc:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "FORBIDDEN", "message": str(exc)},
        ) from exc
    except GmailAPIError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "NOT_FOUND", "message": str(exc)},
        ) from exc
