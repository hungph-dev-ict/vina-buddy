from fastapi import APIRouter, Header, HTTPException, status

from app.routers.auth import auth_service
from app.routers.rules import rules_service
from app.schemas.gmail import (
    GmailLabelsResponse,
    SyncEmailsRequest,
    SyncEmailsResponse,
)
from app.services.auth_service import AuthExpiredError
from app.services.gmail_service import GmailAPIError, GmailService

router = APIRouter(tags=["Gmail"])

# Shared Gmail service instance wired with rules service
gmail_service = GmailService(rules_service=rules_service)


def get_token_from_header(authorization: str | None) -> str | None:
    """Extract session token from Authorization: Bearer <token> header."""
    if not authorization:
        return None
    parts = authorization.split()
    if len(parts) == 2 and parts[0].lower() == "bearer":
        return parts[1]
    return authorization


@router.post(
    "/gmail/sync",
    response_model=SyncEmailsResponse,
    summary="Fetch limited recent emails metadata from Gmail",
)
async def sync_emails(
    request: SyncEmailsRequest,
    authorization: str | None = Header(None),
) -> SyncEmailsResponse:
    # Validate session token if provided
    session_token = get_token_from_header(authorization)
    access_token = None
    if session_token:
        try:
            access_token = await auth_service.get_valid_access_token(session_token)
        except AuthExpiredError as exc:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={"code": "AUTH_EXPIRED", "message": str(exc)},
            ) from exc

    try:
        emails, next_token = await gmail_service.fetch_recent_emails(
            max_results=request.max_results,
            page_token=request.page_token,
            access_token=access_token,
        )
        return SyncEmailsResponse(
            emails=emails,
            total_count=len(emails),
            next_page_token=next_token,
        )
    except GmailAPIError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"code": "GMAIL_API_ERROR", "message": str(exc)},
        ) from exc


@router.get(
    "/gmail/labels",
    response_model=GmailLabelsResponse,
    summary="List available Gmail labels",
)
async def list_labels(
    authorization: str | None = Header(None),
) -> GmailLabelsResponse:
    session_token = get_token_from_header(authorization)
    access_token = None
    if session_token:
        try:
            access_token = await auth_service.get_valid_access_token(session_token)
        except AuthExpiredError as exc:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={"code": "AUTH_EXPIRED", "message": str(exc)},
            ) from exc

    labels = await gmail_service.list_labels(access_token)
    return GmailLabelsResponse(labels=labels)
