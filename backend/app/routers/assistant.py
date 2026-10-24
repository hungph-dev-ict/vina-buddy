import logging
from fastapi import APIRouter, Header, HTTPException, status

from app.routers.rules import rules_service
from app.schemas.assistant import ChatRequest, ChatResponse
from app.services.assistant_service import AssistantService

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Assistant"])

# Shared assistant service instance sharing rules_service singleton
assistant_service = AssistantService(rules_service=rules_service)



@router.post(
    "/assistant/chat",
    response_model=ChatResponse,
    status_code=status.HTTP_200_OK,
    summary="Chat with VinaBuddy AI Assistant",
)
async def chat_with_assistant(
    request: ChatRequest,
    authorization: str | None = Header(None),
) -> ChatResponse:
    """
    VinaBuddy conversational endpoint.
    Strict LLM boundary:
    - Intent classified into stats, classify, label, or other.
    - Dispatches to safe Gmail API tools (uses live Google access_token if authenticated).
    - If other, returns polite unsupported rejection with 3 action buttons.
    """
    from app.routers.auth import auth_service
    from app.routers.gmail import get_token_from_header
    from app.services.auth_service import AuthExpiredError

    access_token = None
    session_token = get_token_from_header(authorization)
    if session_token:
        try:
            access_token = await auth_service.get_valid_access_token(session_token)
        except AuthExpiredError as exc:
            logger.warning("Session token not found or expired in assistant chat: %s", exc)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={"code": "AUTH_EXPIRED", "message": "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."},
            ) from exc
        except Exception as exc:
            logger.debug("Session error in assistant chat: %s", exc)

    try:
        return await assistant_service.handle_chat(
            request, access_token=access_token
        )
    except Exception as exc:
        logger.error("Error processing assistant chat: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"code": "ASSISTANT_ERROR", "message": str(exc)},
        ) from exc


@router.get(
    "/assistant/agents",
    summary="List all available vnverse agents",
    status_code=status.HTTP_200_OK,
)
def list_available_agents():
    """Returns definitions and capabilities for all modular agents in vnverse."""
    from app.agents.registry import AgentRegistry

    registry = AgentRegistry()
    return [agent.definition.model_dump() for agent in registry.list_agents()]
