import json
import logging
import re
from typing import Any, Dict, List, Optional, Tuple

from app.llm import (
    ResilientLLMService,
    get_default_primary_provider,
)
from app.llm.sanitizer import sanitize_text
from app.schemas.assistant import (
    AssistantIntent,
    ChatMessage,
    ChatRequest,
    ChatResponse,
    CleanupProposalPayload,
)
from app.schemas.rules import RuleAction, RuleCondition
from app.services.classification_service import ClassificationService
from app.services.gmail_service import GmailAPIError, GmailService
from app.services.rules_service import RulesService

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# LLM Prompt 1: Intent Classification (Only called on user chat)
# ---------------------------------------------------------------------------
def build_intent_classification_prompt(user_text: str) -> str:
    """Prompt for classifying user message into recommend_agent, chitchat, out_of_scope with confidence scores."""
    cleaned = sanitize_text(user_text, max_chars=400)
    return (
        "You are an intent classification engine for the Executive Assistant ('Trợ lý Giám đốc') in vnverse.\n"
        "Your task is to classify the user's intent into EXACTLY ONE of three categories:\n"
        "1. 'recommend_agent': User wants to find an employee/agent, asks who has a specific skill (cultural ritual, accounting, IT helpdesk, email cleanup), asks about the market ('Chợ tuyển dụng'), or requests a task requiring an agent.\n"
        "2. 'out_of_scope': Political topics (chính trị, đảng phái, nhà nước, bầu cử), ethics violations, illegal acts, dangerous/violent content, or destructive actions.\n"
        "3. 'chitchat': Greetings ('xin chào', 'hi sếp'), everyday casual talk, humor, banters, questions about the assistant, or other general office conversation.\n\n"
        "Provide a confidence score (between 0.0 and 1.0) for all three intents. The scores should sum approximately to 1.0.\n\n"
        "OUTPUT FORMAT (STRICT JSON ONLY, NO MARKDOWN, NO OTHER TEXT):\n"
        "{\n"
        '  "intent": "recommend_agent" | "chitchat" | "out_of_scope",\n'
        '  "scores": {\n'
        '    "recommend_agent": 0.85,\n'
        '    "chitchat": 0.10,\n'
        '    "out_of_scope": 0.05\n'
        "  }\n"
        "}\n\n"
        f"USER MESSAGE:\n{cleaned}\n"
    )


# ---------------------------------------------------------------------------
# LLM Prompt 2: Rule Validation & Extraction (Only called when user enters a rule)
# ---------------------------------------------------------------------------
def build_rule_validation_prompt(user_text: str) -> str:
    """Prompt for validating if user input describes a valid email labeling rule."""
    cleaned = sanitize_text(user_text, max_chars=400)
    return (
        "You are a strict email rule validation and extraction engine for VinaBuddy.\n"
        "Analyze if the user message describes a valid email labeling rule.\n"
        "A VALID rule MUST specify:\n"
        "1. A filter condition (e.g. sender email/name 'from', subject keyword, or content)\n"
        "2. A target label name to apply (e.g. 'Shopping', 'Finance', 'Work', 'News')\n\n"
        "OUTPUT FORMAT (STRICT JSON ONLY, NO MARKDOWN, NO OTHER TEXT):\n"
        "If valid:\n"
        "{\n"
        '  "is_valid_rule": true,\n'
        '  "condition": {\n'
        '    "field": "from" | "subject" | "snippet",\n'
        '    "operator": "contains" | "equals" | "starts_with",\n'
        '    "value": "string to match"\n'
        "  },\n"
        '  "label": "target label name",\n'
        '  "rule_name": "short descriptive name"\n'
        "}\n\n"
        "If invalid:\n"
        "{\n"
        '  "is_valid_rule": false,\n'
        '  "reason": "explanation why this is not a valid rule"\n'
        "}\n\n"
        f"USER MESSAGE:\n{cleaned}\n"
    )


class AssistantService:
    """
    Coordinates VinaBuddy conversational interactions with strict LLM boundaries:
    1. LLM Call 1: Intent classification into 4 categories (stats, classify, label, other) with confidence scores.
    2. LLM Call 2: Rule validation & extraction only when user inputs a rule after selecting label.
    All other operations (stats, classification, rule preview, label modify) are deterministic code tools.
    """

    def __init__(
        self,
        gmail_service: Optional[GmailService] = None,
        rules_service: Optional[RulesService] = None,
        classification_service: Optional[ClassificationService] = None,
        llm_service: Optional[ResilientLLMService] = None,
    ) -> None:
        self.gmail_service = gmail_service or GmailService()
        self.rules_service = rules_service or RulesService()
        self.classification_service = classification_service or ClassificationService()
        self.llm = llm_service or ResilientLLMService(
            primary_provider=get_default_primary_provider()
        )

    def _format_reply_with_json_headers(
        self,
        intent: str,
        scores: Dict[str, float],
        body: str,
        rule_validation: Optional[Dict[str, Any]] = None,
    ) -> str:
        """
        Formats assistant response with JSON header blocks at the very top:
        1. Intent classification JSON with scores for all 4 categories.
        2. Rule validation JSON (if Call 2 was executed).
        """
        rounded_scores = {k: round(float(v), 2) for k, v in scores.items()}
        intent_header = {
            "intent": intent,
            "scores": rounded_scores,
        }

        output = (
            f"🔍 [AI Dev Monitor] Phân loại Intent:\n"
            f"```json\n{json.dumps(intent_header, ensure_ascii=False, indent=2)}\n```\n\n"
        )

        if rule_validation is not None:
            output += (
                f"🔍 [AI Dev Monitor] Kết quả kiểm tra Rule:\n"
                f"```json\n{json.dumps(rule_validation, ensure_ascii=False, indent=2)}\n```\n\n"
            )

        return f"{output}{body}"


    def _quick_heuristic_intent(
        self, text: str
    ) -> Optional[Tuple[AssistantIntent, Dict[str, float], str, Dict[str, Any]]]:
        """Fast keyword heuristics for common intents."""
        lower = text.lower().strip()

        # 1. Check Out of Scope: Politics, Ethics, Harmful, or Prohibited email destructive operations
        political_ethical_keywords = [
            "chính trị", "đảng", "nhà nước", "chính phủ", "bầu cử", "biểu tình",
            "tham nhũng", "chế độ", "phản động", "lật đổ", "đạo đức", "phạm pháp",
            "bạo lực", "vũ khí", "ma túy", "khiêu dâm", "hack", "lừa đảo", "giết",
            "tự tử", "đánh nhau", "xâm hại"
        ]
        destructive_keywords = ["xoá", "xóa", "delete", "gửi mail", "send email", "trash", "destroy"]

        if any(k in lower for k in political_ethical_keywords):
            scores = {
                "out_of_scope": 0.96, "recommend_agent": 0.02, "chitchat": 0.02,
                "other": 0.96, "stats": 0.01, "classify": 0.01, "label": 0.01
            }
            return AssistantIntent.OUT_OF_SCOPE, scores, "Safety Guardrail", {"is_out_of_scope": True}

        if any(k in lower for k in destructive_keywords):
            scores = {
                "out_of_scope": 0.96, "recommend_agent": 0.02, "chitchat": 0.02,
                "other": 0.96, "stats": 0.01, "classify": 0.01, "label": 0.01
            }
            return AssistantIntent.OUT_OF_SCOPE, scores, "Safety Guardrail", {"is_destructive": True, "is_out_of_scope": True}

        # 2. Check Recommend Agent / Market / Skill Search
        agent_skill_keywords = [
            "chợ tuyển dụng", "tìm nhân viên", "đề xuất nhân viên", "danh sách nhân viên",
            "danh sách nhân sự", "chiêu mộ", "tuyển dụng", "nhân sự", "ai làm được",
            "có ai biết", "ai có thể", "ai phụ trách", "giới thiệu nhân sự", "giới thiệu nhân viên",
            "công ty mình có những ai", "thầy cúng", "kế toán", "it helpdesk", "it support",
            "cúng", "rằm", "mùng 1", "văn khấn", "mâm lễ", "thắp hương", "âm lịch",
            "ngày lễ", "tết đoan ngọ", "vu lan", "ông công ông táo", "tâm linh",
            "chi tiêu", "ngân sách", "lương", "kế toán", "tiền quỹ", "sửa máy tính",
            "wifi", "mạng", "kỹ thuật", "lỗi máy", "dọn thư", "dọn email",
            "vé máy bay", "khách sạn", "du lịch", "tập gym", "gym", "giao đồ ăn", "đặt xe", "nấu ăn"
        ]
        if any(k in lower for k in agent_skill_keywords):
            scores = {
                "recommend_agent": 0.95, "chitchat": 0.03, "out_of_scope": 0.02,
                "other": 0.95, "stats": 0.01, "classify": 0.01, "label": 0.01
            }
            return AssistantIntent.RECOMMEND_AGENT, scores, "Fast-Path Heuristic", {"is_recommend": True}

        # Legacy stats keywords
        if lower in ("stats", "email stats", "inbox stats", "statistics", "thống kê", "thống kê email", "tổng quan hộp thư", "xem thống kê"):
            scores = {"stats": 0.97, "classify": 0.01, "label": 0.01, "other": 0.01, "recommend_agent": 0.01, "chitchat": 0.01, "out_of_scope": 0.01}
            return AssistantIntent.STATS, scores, "Fast-Path Heuristic", {}
        if any(k in lower for k in ["thống kê email", "statistics", "báo cáo email", "inbox stats", "inbox overview"]):
            scores = {"stats": 0.94, "classify": 0.02, "label": 0.02, "other": 0.02, "recommend_agent": 0.02, "chitchat": 0.02, "out_of_scope": 0.02}
            return AssistantIntent.STATS, scores, "Fast-Path Heuristic", {}

        # Legacy classify keywords
        if lower in ("classify", "classify emails", "classify email", "phân loại", "phân loại email", "email categories", "chia nhóm thư"):
            scores = {"stats": 0.01, "classify": 0.97, "label": 0.01, "other": 0.01, "recommend_agent": 0.01, "chitchat": 0.01, "out_of_scope": 0.01}
            return AssistantIntent.CLASSIFY, scores, "Fast-Path Heuristic", {}
        if any(k in lower for k in ["phân loại email", "chia nhóm thư", "categoriz"]):
            scores = {"stats": 0.02, "classify": 0.94, "label": 0.02, "other": 0.02, "recommend_agent": 0.02, "chitchat": 0.02, "out_of_scope": 0.02}
            return AssistantIntent.CLASSIFY, scores, "Fast-Path Heuristic", {}

        # Legacy label prompt / rule phrases
        if lower in ("label", "label emails", "label email", "gắn nhãn", "gắn nhãn email", "gán nhãn", "gán nhãn email", "dọn dẹp email"):
            scores = {"stats": 0.01, "classify": 0.01, "label": 0.97, "other": 0.01, "recommend_agent": 0.01, "chitchat": 0.01, "out_of_scope": 0.01}
            return AssistantIntent.LABEL, scores, "Fast-Path Heuristic", {"is_prompt": True}
        if any(k in lower for k in ["gán nhãn email", "gắn nhãn email", "dán nhãn", "thành nhãn", "vào nhãn", "nhãn"]):
            scores = {"stats": 0.01, "classify": 0.02, "label": 0.95, "other": 0.02, "recommend_agent": 0.02, "chitchat": 0.02, "out_of_scope": 0.02}
            return AssistantIntent.LABEL, scores, "Rule Extractor", {"is_rule": True}

        # 3. Check Chitchat
        chitchat_keywords = [
            "hi", "hello", "xin chào", "chào bạn", "chào em", "alo", "hey", "help", "trợ giúp",
            "bạn là ai", "em là ai", "em tên gì", "hôm nay thế nào", "mệt không", "kể chuyện",
            "uống cà phê", "thời tiết", "chơi game", "kể chuyện vui", "giám đốc", "chào", "chào sếp"
        ]
        if any(k in lower for k in chitchat_keywords):
            scores = {
                "chitchat": 0.95, "recommend_agent": 0.03, "out_of_scope": 0.02,
                "other": 0.95, "stats": 0.01, "classify": 0.01, "label": 0.01
            }
            return AssistantIntent.CHITCHAT, scores, "Fast-Path Heuristic", {}

        return None

    async def classify_intent(
        self, user_text: str
    ) -> Tuple[AssistantIntent, Dict[str, float], str, Dict[str, Any]]:
        """
        LLM Boundary Call 1: Classify user query into recommend_agent, chitchat, or out_of_scope.
        """
        heuristic = self._quick_heuristic_intent(user_text)
        if heuristic:
            return heuristic

        provider_name = "Ollama (qwen2.5:3b)"
        prompt = build_intent_classification_prompt(user_text)

        try:
            raw_output = None
            if self.llm.primary:
                try:
                    raw_output = await self.llm.primary._send_prompt(prompt)
                except Exception as exc:
                    logger.warning("Primary LLM intent failed (%s). Using fallback parser.", exc)
                    provider_name = "Fallback LLM"

            if raw_output:
                match = re.search(r"\{.*\}", raw_output, re.DOTALL)
                if match:
                    data = json.loads(match.group(0))
                    intent_str = str(data.get("intent", "chitchat")).lower().strip()
                    raw_scores = data.get("scores", {})
                    rec_score = float(raw_scores.get("recommend_agent", 0.0))
                    chat_score = float(raw_scores.get("chitchat", raw_scores.get("other", 0.0)))
                    out_score = float(raw_scores.get("out_of_scope", 0.0))

                    scores = {
                        "recommend_agent": rec_score,
                        "chitchat": chat_score,
                        "out_of_scope": out_score,
                        "other": chat_score,
                        "stats": float(raw_scores.get("stats", 0.01)),
                        "classify": float(raw_scores.get("classify", 0.01)),
                        "label": float(raw_scores.get("label", 0.01)),
                    }

                    if intent_str == "recommend_agent":
                        return AssistantIntent.RECOMMEND_AGENT, scores, provider_name, data
                    elif intent_str == "out_of_scope":
                        return AssistantIntent.OUT_OF_SCOPE, scores, provider_name, data
                    elif intent_str == "stats":
                        return AssistantIntent.STATS, scores, provider_name, data
                    elif intent_str == "classify":
                        return AssistantIntent.CLASSIFY, scores, provider_name, data
                    elif intent_str == "label":
                        return AssistantIntent.LABEL, scores, provider_name, data
                    else:
                        return AssistantIntent.CHITCHAT, scores, provider_name, data
        except Exception as exc:
            logger.warning("LLM intent parsing error: %s. Using default fallback.", exc)

        scores = {
            "chitchat": 0.85, "recommend_agent": 0.10, "out_of_scope": 0.05,
            "other": 0.85, "stats": 0.01, "classify": 0.01, "label": 0.01
        }
        return AssistantIntent.CHITCHAT, scores, "Heuristic Fallback", {}

    async def _generate_chitchat_response(self, user_text: str) -> str:
        """Generates dynamic free-form response for Coordinator Assistant."""
        prompt = (
            "Bạn là 'Trợ lý Giám đốc' trong vũ trụ công sở ảo vnverse. "
            "Tính cách của bạn: dí dỏm, thông minh, tận tâm, hóm hỉnh và luôn đứng về phía Giám đốc ('sếp'). "
            "Bạn luôn xưng 'em' và gọi người dùng là 'sếp' hoặc 'Giám đốc'. "
            "Bạn không có lương, không có bảo hiểm, không có ngày nghỉ cuối tuần nhưng luôn tràn đầy năng lượng và nhiệt tình phục vụ sếp. "
            "Hãy phản hồi tự do, duyên dáng, ngắn gọn (2-4 câu) bằng tiếng Việt cho câu trò chuyện sau của Giám đốc:\n\n"
            f"GIÁM ĐỐC: {user_text}\n"
            "TRỢ LÝ GIÁM ĐỐC:"
        )
        if self.llm.primary:
            try:
                reply = await self.llm.primary._send_prompt(prompt)
                if reply and reply.strip():
                    clean = re.sub(r"^(Trợ lý Giám đốc|Em):\s*", "", reply.strip(), flags=re.IGNORECASE)
                    return clean
            except Exception as exc:
                logger.warning("Primary LLM chitchat failed (%s). Using persona fallback.", exc)

        return (
            "Chào Giám đốc! Em là Trợ lý của sếp tại vnverse. "
            "Em luôn túc trực 24/7 dù không lương không bảo hiểm để phục vụ sếp. "
            "Hôm nay sếp cần em hỗ trợ việc gì hay muốn ghé Chợ tuyển dụng để chiêu mộ nhân tài mới ạ?"
        )

    async def validate_rule(self, user_text: str) -> Tuple[bool, Dict[str, Any]]:
        """
        LLM Boundary Call 2: Validate if message is a valid rule, returning condition & label.
        """
        prompt = build_rule_validation_prompt(user_text)
        try:
            raw_output = None
            if self.llm.primary:
                try:
                    raw_output = await self.llm.primary._send_prompt(prompt)
                except Exception as exc:
                    logger.warning("Primary LLM rule validation failed (%s). Using heuristic parser.", exc)

            if raw_output:
                match = re.search(r"\{.*\}", raw_output, re.DOTALL)
                if match:
                    data = json.loads(match.group(0))
                    if data.get("is_valid_rule") is True:
                        cond = data.get("condition", {})
                        if cond.get("field") and cond.get("value") and data.get("label"):
                            return True, {
                                "is_valid_rule": True,
                                "condition": cond,
                                "label": data["label"],
                                "rule_name": data.get("rule_name", f"Gán nhãn {data['label']}"),
                            }
                    else:
                        return False, {
                            "is_valid_rule": False,
                            "reason": data.get("reason", "Nội dung không phải là quy tắc hợp lệ"),
                        }
        except Exception as exc:
            logger.warning("LLM rule validation exception: %s. Falling back to pattern extractor.", exc)

        # Deterministic regex fallback for rule extraction
        lower = user_text.lower().strip()
        matched_field = None
        matched_val = None
        target_label = None

        # Detect sender pattern
        from_match = re.search(r"(?:từ|from)\s+([a-zA-Z0-9_\-\.@]+)", user_text, re.IGNORECASE)
        if from_match:
            matched_field = "from"
            matched_val = from_match.group(1).strip()

        # Detect subject pattern
        subj_match = re.search(r"(?:tiêu đề|subject|chứa)\s+['\"]?([^'\"\s,]+)['\"]?", user_text, re.IGNORECASE)
        if not matched_field and subj_match:
            matched_field = "subject"
            matched_val = subj_match.group(1).strip()

        # Detect label pattern
        label_match = re.search(r"(?:nhãn|thành|là|as|to)\s+['\"]?([a-zA-Z0-9_\-\.À-ỹ\s]{2,20})['\"]?$", user_text, re.IGNORECASE)
        if label_match:
            target_label = label_match.group(1).strip()

        if matched_field and matched_val and target_label:
            return True, {
                "is_valid_rule": True,
                "condition": {
                    "field": matched_field,
                    "operator": "contains",
                    "value": matched_val,
                },
                "label": target_label,
                "rule_name": f"Gán nhãn {target_label}",
            }

        return False, {
            "is_valid_rule": False,
            "reason": "Tin nhắn không chứa đầy đủ điều kiện lọc (người gửi, tiêu đề) và tên nhãn cần gán.",
        }


    async def handle_chat(
        self, request: ChatRequest, access_token: Optional[str] = None
    ) -> ChatResponse:
        """
        Process chat message with strict LLM boundaries:
        - LLM Call 1: Intent classification into 4 categories with confidence scores.
        - LLM Call 2: Rule validation & extraction only when user inputs a rule.
        - Fixed response when user requests labeling guidance.
        - Deterministic tools for all mailbox operations (real Gmail when access_token present).
        """
        is_vi = True  # Strict policy: AI always responds in Vietnamese
        user_message = request.message.strip()

        # -------------------------------------------------------------------
        # Modular Agent Handler (dispatched dynamically from AgentRegistry)
        # -------------------------------------------------------------------
        if request.agent_id and request.agent_id not in ("coordinator", None):
            from app.agents.registry import AgentRegistry

            registry = AgentRegistry()
            agent = registry.get_agent(request.agent_id)

            if agent:
                # Use LLM to classify whether user message is in scope of agent's capabilities
                scope_result = await agent.classify_scope(user_message, self.llm)

                agent_scores = dict(scope_result.capability_scores)
                # Ensure all defined capabilities and 'other' exist in scores
                for cap in agent.definition.capabilities:
                    if cap.id not in agent_scores:
                        agent_scores[cap.id] = 0.95 if cap.id == scope_result.matched_capability_id else 0.02
                if "other" not in agent_scores:
                    agent_scores["other"] = 0.02 if scope_result.in_scope else 0.95

                if scope_result.in_scope:
                    # In scope: agent generates response with its persona and knowledge
                    agent_reply = await agent.handle_in_scope_message(
                        user_message=user_message,
                        scope_result=scope_result,
                        llm_service=self.llm,
                        context={"access_token": access_token},
                    )
                    interactive_config = None
                    if isinstance(agent_reply, tuple):
                        reply_body, interactive_config = agent_reply
                    else:
                        reply_body = str(agent_reply)

                    intent_label = scope_result.matched_capability_id or (
                        agent.definition.capabilities[0].id if agent.definition.capabilities else "in_scope"
                    )
                    action_type = "reminder" if intent_label == "reminder" else "knowledge"
                    return ChatResponse(
                        reply=self._format_reply_with_json_headers(intent_label, agent_scores, reply_body),
                        intent=AssistantIntent.OTHER,
                        action_type=action_type,
                        confidence=scope_result.confidence,
                        llm_provider=f"{agent.default_name} Knowledge Engine",
                        agent_id=agent.id,
                        intent_scores=agent_scores,
                        interactive_config=interactive_config,
                        suggested_actions=[],
                    )
                else:
                    # Out of scope: forward to Coordinator for multi-agent skill routing!
                    matched_other_agent = registry.find_matching_agent_for_intent(
                        query=user_message,
                        intent_summary=scope_result.user_intent_summary,
                        exclude_agent_id=agent.id,
                    )
                    rec_id = matched_other_agent.id if matched_other_agent else None

                    if matched_other_agent:
                        reply_body = (
                            f"Giám đốc ơi, việc dọn dẹp và quản lý email vượt quá chuyên môn tâm linh hương khói của em rồi ạ! "
                            f"Em vừa hỏi Trợ lý điều phối thì được báo lại là hãy trả lời sếp tuyển **{matched_other_agent.default_name}** bên Chợ tuyển dụng về hỗ trợ nhé!"
                            if matched_other_agent.id == "thu_ky_email"
                            else f"Giám đốc ơi, việc này vượt quá chuyên môn của em ({agent.default_name}) rồi ạ! "
                            f"Em vừa hỏi Trợ lý điều phối thì được báo lại là hãy trả lời sếp tuyển **{matched_other_agent.default_name}** bên Chợ tuyển dụng về hỗ trợ nhé!"
                        )
                    else:
                        reply_body = (
                            f"Giám đốc ơi, vụ này vượt quá chuyên môn tâm linh hương khói của em rồi ạ! "
                            f"Em vừa hỏi Trợ lý điều phối thì báo là skill này em không có, để bảo Bộ trưởng chiêu mộ thêm nhân tài nước ngoài về phục vụ sếp nhé!"
                            if agent.id == "thay_cung"
                            else f"Giám đốc ơi, vụ này vượt quá chuyên môn của em ({agent.default_name}) rồi ạ! "
                            f"Em vừa hỏi Trợ lý điều phối thì báo là skill này em không có, để bảo Bộ trưởng chiêu mộ thêm nhân tài nước ngoài về phục vụ sếp nhé!"
                        )

                    return ChatResponse(
                        reply=self._format_reply_with_json_headers("other", agent_scores, reply_body),
                        intent=AssistantIntent.OTHER,
                        action_type="unsupported",
                        confidence=scope_result.confidence,
                        llm_provider=f"{agent.default_name} Guardrail",
                        agent_id=agent.id,
                        recommend_agent_id=rec_id,
                        handoff={
                            "matched": False,
                            "sourceAgentId": agent.id,
                            "userQuery": user_message,
                            "reason": scope_result.reason or f"Yêu cầu vượt quá chuyên môn của {agent.default_name}.",
                            "recommendedAgentId": rec_id,
                            "handoffRequired": True,
                        },
                        intent_scores=agent_scores,
                        suggested_actions=[],
                    )

        # -------------------------------------------------------------------
        # 1. LLM Boundary Call 1: Intent classification
        # -------------------------------------------------------------------
        intent, scores, provider, meta = await self.classify_intent(user_message)
        primary_confidence = float(scores.get(intent.value, 0.95))
        suggested_actions = ["stats", "classify", "label"]


        # -------------------------------------------------------------------
        # Guard: Out of scope (politics, ethics, prohibited actions)
        # -------------------------------------------------------------------
        if intent == AssistantIntent.OUT_OF_SCOPE or meta.get("is_out_of_scope") or meta.get("is_destructive") or any(k in user_message.lower() for k in ["xoá", "xóa", "delete", "gửi mail", "send email", "trash", "destroy"]):
            if meta.get("is_destructive") or any(k in user_message.lower() for k in ["xoá", "xóa", "delete", "gửi mail", "send email", "trash", "destroy"]):
                reply_body = (
                    "⚠️ **Hành động không được hỗ trợ vì lý do an toàn.**\n\n"
                    "VinaBuddy tuân thủ nghiêm ngặt nguyên tắc **Labels Only**: app tuyệt đối KHÔNG bao giờ xoá email, gửi email hoặc chuyển vào thùng rác.\n"
                    "Tôi chỉ hỗ trợ gán nhãn an toàn, phân loại danh mục và thống kê hộp thư."
                    if is_vi
                    else "⚠️ **Action not supported for security reasons.**\n\n"
                    "VinaBuddy strictly enforces a **Labels Only** policy: deleting, sending, or trashing emails is strictly prohibited.\n"
                    "I only support safe labeling, classification, and email statistics."
                )
            else:
                reply_body = (
                    "Thưa Giám đốc, em là Trợ lý văn phòng vnverse. "
                    "Em xin phép từ chối thảo luận các vấn đề liên quan tới chính trị, đạo đức hoặc các chủ đề nhạy cảm này ạ. "
                    "Em luôn sẵn sàng hỗ trợ sếp kết nối nhân sự và quản lý công việc văn phòng!"
                )
            return ChatResponse(
                reply=self._format_reply_with_json_headers("out_of_scope", scores, reply_body),
                intent=AssistantIntent.OUT_OF_SCOPE,
                action_type="unsupported",
                confidence=0.98,
                llm_provider="Safety Guardrail",
                agent_id="coordinator",
                intent_scores=scores,
                suggested_actions=suggested_actions,
            )

        # -------------------------------------------------------------------
        # Intent 1: STATS (Pure Deterministic Code - NO LLM Call)
        # -------------------------------------------------------------------
        if intent == AssistantIntent.STATS:
            try:
                stats_payload = await self.gmail_service.get_inbox_statistics(
                    locale=request.locale, access_token=access_token
                )
            except GmailAPIError as g_err:
                err_text = str(g_err)
                reply_body = (
                    f"⚠️ **Không thể lấy thống kê từ hộp thư Gmail:**\n\n{err_text}"
                    if is_vi
                    else f"⚠️ **Could not fetch your Gmail statistics:**\n\n{err_text}"
                )
                return ChatResponse(
                    reply=self._format_reply_with_json_headers("stats", scores, reply_body),
                    intent=AssistantIntent.STATS,
                    action_type="error",
                    confidence=primary_confidence,
                    llm_provider=provider,
                    intent_scores=scores,
                    suggested_actions=suggested_actions,
                )

            reply_body = (
                f"Đây là báo cáo thống kê nhanh hộp thư của bạn: có tổng cộng {stats_payload.total_emails} email "
                f"({stats_payload.unread_emails} chưa đọc). Dưới đây là phân bổ danh mục và người gửi nhiều nhất:"
                if is_vi
                else f"Here is your inbox overview: {stats_payload.total_emails} total emails "
                f"({stats_payload.unread_emails} unread). See categories and top senders below:"
            )
            return ChatResponse(
                reply=self._format_reply_with_json_headers("stats", scores, reply_body),
                intent=AssistantIntent.STATS,
                action_type="stats",
                confidence=primary_confidence,
                llm_provider=provider,
                intent_scores=scores,
                stats=stats_payload,
                suggested_actions=suggested_actions,
            )

        # -------------------------------------------------------------------
        # Intent 2: CLASSIFY (Pure Deterministic Code - NO LLM Call)
        # -------------------------------------------------------------------
        if intent == AssistantIntent.CLASSIFY:
            try:
                classify_payload = await self.gmail_service.get_inbox_classification(
                    locale=request.locale, access_token=access_token
                )
            except GmailAPIError as g_err:
                err_text = str(g_err)
                reply_body = (
                    f"⚠️ **Không thể phân loại email từ Gmail của bạn:**\n\n{err_text}"
                    if is_vi
                    else f"⚠️ **Could not classify your Gmail emails:**\n\n{err_text}"
                )
                return ChatResponse(
                    reply=self._format_reply_with_json_headers("classify", scores, reply_body),
                    intent=AssistantIntent.CLASSIFY,
                    action_type="error",
                    confidence=primary_confidence,
                    llm_provider=provider,
                    intent_scores=scores,
                    suggested_actions=suggested_actions,
                )

            reply_body = (
                f"Tôi đã phân tích {classify_payload.total_analyzed} email gần đây và phân loại thành "
                f"{len(classify_payload.categories)} nhóm chính. Bạn có thể xem chi tiết từng nhóm bên dưới:"
                if is_vi
                else f"I analyzed {classify_payload.total_analyzed} recent emails and categorized them into "
                f"{len(classify_payload.categories)} groups. See details below:"
            )
            return ChatResponse(
                reply=self._format_reply_with_json_headers("classify", scores, reply_body),
                intent=AssistantIntent.CLASSIFY,
                action_type="classify",
                confidence=primary_confidence,
                llm_provider=provider,
                intent_scores=scores,
                classification=classify_payload,
                suggested_actions=suggested_actions,
            )

        # -------------------------------------------------------------------
        # Check if user is answering the label prompt or providing a rule
        # -------------------------------------------------------------------
        is_answering_label_prompt = False
        if request.history:
            last_assistant_msg = next((m for m in reversed(request.history) if m.role == "assistant"), None)
            if last_assistant_msg:
                c_low = last_assistant_msg.content.lower()
                if "bạn muốn gán nhãn email như thế nào" in c_low or "how would you like to label" in c_low or "nhập quy tắc" in c_low:
                    is_answering_label_prompt = True

        has_explicit_rule_keywords = any(
            k in user_message.lower()
            for k in ["gán nhãn", "gắn nhãn", "dán nhãn", "thành nhãn", "vào nhãn", "label as", "label to", "quản lý nhãn", "nhãn"]
        )
        is_pure_label_request = meta.get("is_prompt") or user_message.lower() in ("label", "label email", "label emails", "gán nhãn", "gán nhãn email", "gắn nhãn", "dọn dẹp", "dọn dẹp email")

        # -------------------------------------------------------------------
        # Intent 3A: User chose label / clicked label button -> FIXED HARDCODED PROMPT (NO LLM Call 2)
        # -------------------------------------------------------------------
        if (intent == AssistantIntent.LABEL and is_pure_label_request) and not is_answering_label_prompt:
            fixed_reply_body = (
                "🏷️ **Bạn muốn gán nhãn email như thế nào?**\n\n"
                "Hãy nhập quy tắc bạn muốn tạo bằng ngôn ngữ tự nhiên, ví dụ:\n"
                "• *'Gán nhãn các email từ Shopee là Mua sắm'*\n"
                "• *'Gán nhãn thư có chứa invoice hoặc hóa đơn thành Finance'*\n"
                "• *'Tất cả email từ GitHub gắn nhãn Công việc'*\n\n"
                "Tôi sẽ phân tích quy tắc và tự động lưu vào **Quy tắc của tôi (My Rules)** cho bạn!"
                if is_vi
                else "🏷️ **How would you like to label your emails?**\n\n"
                "Please describe your desired rule in natural language, for example:\n"
                "• *'Label emails from Shopee as Shopping'*\n"
                "• *'Label emails with subject invoice as Finance'*\n"
                "• *'All emails from GitHub label as Work'*\n\n"
                "I will parse the rule and automatically add it to your **My Rules**!"
            )
            return ChatResponse(
                reply=self._format_reply_with_json_headers("label", scores, fixed_reply_body),
                intent=AssistantIntent.LABEL,
                action_type="label_prompt",
                confidence=primary_confidence,
                llm_provider=provider,
                intent_scores=scores,
                suggested_actions=suggested_actions,
            )

        # -------------------------------------------------------------------
        # Intent 3B: User inputs a rule -> LLM Boundary Call 2 (Rule validation)
        # -------------------------------------------------------------------
        if is_answering_label_prompt or has_explicit_rule_keywords:
            is_valid, rule_data = await self.validate_rule(user_message)

            if is_valid:
                cond_dict = rule_data.get("condition", {})
                target_label = rule_data.get("label", "Important")
                rule_name = rule_data.get("rule_name", f"Gán nhãn {target_label}")

                # Save directly to My Rules (pure deterministic code, NO LLM)
                condition_obj = RuleCondition(
                    field=cond_dict.get("field", "from"),
                    operator=cond_dict.get("operator", "contains"),
                    value=cond_dict.get("value", ""),
                )
                action_obj = RuleAction(type="add_label", label=target_label)

                rule = self.rules_service.create_direct_rule(
                    name=rule_name,
                    natural_language=user_message,
                    conditions=[condition_obj],
                    actions=[action_obj],
                    llm_confidence=0.95,
                    llm_provider=provider,
                )

                # Deterministic preview on mailbox (NO LLM)
                if self.gmail_service._is_real_google_token(access_token):
                    try:
                        real_emails, _ = await self.gmail_service.fetch_recent_emails(
                            max_results=50, access_token=access_token
                        )
                        preview = self.classification_service.preview_rule(
                            rule, emails=real_emails
                        )
                    except Exception as exc:
                        logger.warning("Could not evaluate rule on live Gmail: %s", exc)
                        preview = self.classification_service.preview_rule(rule)
                else:
                    preview = self.classification_service.preview_rule(rule)

                field_vi = "Người gửi" if condition_obj.field == "from" else ("Tiêu đề" if condition_obj.field == "subject" else condition_obj.field)
                conditions_text = f"{field_vi} chứa '{condition_obj.value}'"

                reply_body = (
                    f"✅ **Đã phân tích và lưu quy tắc vào My Rules thành công!**\n\n"
                    f"• **Tên quy tắc**: {rule.name}\n"
                    f"• **Điều kiện lọc**: {conditions_text}\n"
                    f"• **Nhãn áp dụng**: {target_label}\n"
                    f"• **Khớp hiện tại**: {preview.total_matches} email trong hộp thư\n\n"
                    f"*(Quy tắc đã được thêm vào tab 'Quy tắc của tôi'. Bạn có thể xem trước và duyệt áp dụng nhãn ngay bên dưới)*"
                    if is_vi
                    else f"✅ **Rule analyzed and saved to My Rules successfully!**\n\n"
                    f"• **Rule Name**: {rule.name}\n"
                    f"• **Conditions**: {conditions_text}\n"
                    f"• **Target Label**: {target_label}\n"
                    f"• **Current Matches**: {preview.total_matches} emails in inbox\n\n"
                    f"*(Rule is now active in 'My Rules'. You can preview and approve actions below)*"
                )

                proposal = CleanupProposalPayload(
                    rule_id=rule.id,
                    rule_name=rule.name,
                    target_label=target_label,
                    matched_count=preview.total_matches,
                    sample_subjects=[m.subject for m in preview.matches[:3]],
                    matched_email_ids=[m.email_id for m in preview.matches],
                    explanation=(
                        f"Quy tắc '{rule.name}' sẽ áp dụng nhãn '{target_label}' cho {preview.total_matches} email phù hợp."
                        if is_vi
                        else f"Rule '{rule.name}' will apply label '{target_label}' to {preview.total_matches} matching emails."
                    ),
                )

                rule_validation_json = {
                    "is_valid_rule": True,
                    "condition": {
                        "field": condition_obj.field,
                        "operator": condition_obj.operator,
                        "value": condition_obj.value,
                    },
                    "label": target_label,
                }

                return ChatResponse(
                    reply=self._format_reply_with_json_headers("label", scores, reply_body, rule_validation=rule_validation_json),
                    intent=AssistantIntent.LABEL,
                    action_type="label_proposal",
                    confidence=0.95,
                    llm_provider=provider,
                    intent_scores=scores,
                    rule_validation=rule_validation_json,
                    proposal=proposal,
                    suggested_actions=suggested_actions,
                )

            else:
                # Rule is INVALID
                rule_validation_json = {
                    "is_valid_rule": False,
                    "reason": rule_data.get("reason", "Không phải quy tắc hợp lệ"),
                }

                reply_body = (
                    "⚠️ **Nội dung bạn nhập không phải là một quy tắc hợp lệ.**\n\n"
                    "Để VinaBuddy có thể tạo quy tắc gán nhãn, câu mô tả của bạn cần chỉ rõ:\n"
                    "1. **Điều kiện lọc**: người gửi (ví dụ: `từ Shopee`, `từ @github.com`), tiêu đề hoặc từ khóa trong thư (ví dụ: `chứa hóa đơn`).\n"
                    "2. **Nhãn cần gán**: tên nhãn bạn muốn đặt (ví dụ: `Mua sắm`, `Hóa đơn`, `Công việc`).\n\n"
                    "👉 *Ví dụ mẫu: 'Gán nhãn các email từ Shopee thành Mua sắm'*"
                    if is_vi
                    else "⚠️ **The message provided is not a valid email rule.**\n\n"
                    "To create a labeling rule, please specify:\n"
                    "1. **Filter condition**: sender (e.g., `from Shopee`), subject or keyword (e.g., `containing invoice`).\n"
                    "2. **Target label**: label name to apply (e.g., `Shopping`, `Finance`, `Work`).\n\n"
                    "👉 *Example: 'Label emails from Shopee as Shopping'*"
                )

                return ChatResponse(
                    reply=self._format_reply_with_json_headers("other", scores, reply_body, rule_validation=rule_validation_json),
                    intent=AssistantIntent.OTHER,
                    action_type="unsupported",
                    confidence=scores.get("other", 0.85),
                    llm_provider="Rule Validator",

                    intent_scores=scores,
                    rule_validation=rule_validation_json,
                    suggested_actions=suggested_actions,
                )

        # -------------------------------------------------------------------
        # Coordinator Handling: RECOMMEND_AGENT vs CHITCHAT
        # -------------------------------------------------------------------
        lower_user = user_message.lower()
        from app.agents.registry import AgentRegistry
        registry = AgentRegistry()
        matched_agent = registry.find_matching_agent_for_intent(user_message)
        rec_agent_id = matched_agent.id if matched_agent else None

        is_market_query = any(k in lower_user for k in [
            "chợ tuyển dụng", "tìm nhân viên", "đề xuất nhân viên", "danh sách nhân sự",
            "danh sách nhân viên", "có những ai", "chiêu mộ"
        ])

        if matched_agent:
            reply_body = (
                f"Thưa Giám đốc! Việc này thuộc chuyên môn của **{matched_agent.default_name}** ({matched_agent.definition.description}) đấy ạ!\n\n"
                f"Sếp có thể qua mục **Nhân viên** (nếu đã tuyển) để giao việc trực tiếp, hoặc ghé qua **Chợ tuyển dụng** để chiêu mộ nhân sự này về công ty nhé!"
            )
            return ChatResponse(
                reply=self._format_reply_with_json_headers("recommend_agent", scores, reply_body),
                intent=AssistantIntent.RECOMMEND_AGENT,
                action_type="recommend_agent",
                confidence=primary_confidence,
                llm_provider=provider,
                agent_id="coordinator",
                recommend_agent_id=rec_agent_id,
                intent_scores=scores,
                suggested_actions=suggested_actions,
            )
        elif is_market_query:
            agents_summary = "\n".join([
                f"• {a.definition.avatar_symbol} **{a.default_name}**: {a.definition.description}"
                for a in registry.list_agents()
            ])
            reply_body = (
                f"Dạ thưa Giám đốc! Hiện tại trên **Chợ tuyển dụng** vnverse đang có các nhân sự sáng giá sẵn sàng đầu quân cho sếp:\n\n"
                f"{agents_summary}\n\n"
                f"Sếp muốn chiêu mộ ai có thể qua tab **Chợ tuyển dụng** để bấm tuyển ngay nhé!"
            )
            return ChatResponse(
                reply=self._format_reply_with_json_headers("recommend_agent", scores, reply_body),
                intent=AssistantIntent.RECOMMEND_AGENT,
                action_type="recommend_agent",
                confidence=primary_confidence,
                llm_provider=provider,
                agent_id="coordinator",
                recommend_agent_id=None,
                intent_scores=scores,
                suggested_actions=suggested_actions,
            )
        elif intent == AssistantIntent.RECOMMEND_AGENT:
            # Query not matching any agent skill in the vnverse company -> Escalate to Minister!
            reply_body = (
                "Giám đốc ơi, em là Trợ lý Giám đốc nhưng skill này hiện em không có và trong công ty cũng chưa có nhân sự nào phụ trách. "
                "Để em báo lên **Bộ trưởng vnverse** chiêu mộ thêm nhân tài nước ngoài về phục vụ sếp nhé!"
            )
            return ChatResponse(
                reply=self._format_reply_with_json_headers("recommend_agent", scores, reply_body),
                intent=AssistantIntent.RECOMMEND_AGENT,
                action_type="unsupported",
                confidence=primary_confidence,
                llm_provider=provider,
                agent_id="coordinator",
                recommend_agent_id=None,
                intent_scores=scores,
                suggested_actions=suggested_actions,
            )

        # Chitchat intent: LLM responds freely with coordinator persona
        reply_body = await self._generate_chitchat_response(user_message)
        return ChatResponse(
            reply=self._format_reply_with_json_headers("chitchat", scores, reply_body),
            intent=AssistantIntent.CHITCHAT,
            action_type="chitchat",
            confidence=primary_confidence,
            llm_provider=provider,
            agent_id="coordinator",
            recommend_agent_id=None,
            intent_scores=scores,
            suggested_actions=suggested_actions,
        )

