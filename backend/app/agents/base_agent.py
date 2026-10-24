import json
import logging
import re
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from app.agents.models import AgentDefinition, IntentScopeResult

logger = logging.getLogger(__name__)


class BaseAgent:
    """
    Base class for all vnverse agents.
    Encapsulates definition, permissions, capabilities, system prompt,
    LLM intent classification, and response generation.
    """

    def __init__(self, agent_dir: Path):
        self.agent_dir = agent_dir
        self.definition = self._load_definition()
        self.system_prompt = self._load_system_prompt()

    @property
    def id(self) -> str:
        return self.definition.id

    @property
    def default_name(self) -> str:
        return self.definition.default_name

    @property
    def required_permissions(self) -> List[str]:
        return self.definition.required_permissions

    def _load_definition(self) -> AgentDefinition:
        def_file = self.agent_dir / "definition.json"
        if not def_file.exists():
            raise FileNotFoundError(f"Missing definition.json in {self.agent_dir}")
        with open(def_file, "r", encoding="utf-8") as f:
            data = json.load(f)
        return AgentDefinition.model_validate(data)

    def _load_system_prompt(self) -> str:
        prompt_file = self.agent_dir / "system_prompt.txt"
        if prompt_file.exists():
            with open(prompt_file, "r", encoding="utf-8") as f:
                return f.read().strip()
        return f"Bạn là {self.definition.default_name}, nhân viên chuyên nghiệp tại công ty ảo vnverse."

    async def classify_scope(self, user_message: str, llm_service: Any) -> IntentScopeResult:
        """
        Uses LLM to classify whether user query is within this agent's defined capabilities.
        Falls back to keyword matching if LLM fails or is in mock mode.
        """
        # 1. Hard Platform Limitations Guardrail (Strict Security & Capability Boundary)
        hard_limitation = self._check_hard_limitations(user_message)
        if hard_limitation is not None:
            return hard_limitation

        capabilities_summary = [
            {
                "id": cap.id,
                "name": cap.name,
                "description": cap.description,
                "sample_queries": cap.sample_queries,
            }
            for cap in self.definition.capabilities
        ]

        prompt = (
            f"Bạn là bộ phân loại Intent cho Nhân viên: \"{self.definition.default_name}\" trong hệ thống vnverse.\n"
            f"Hãy phân tích câu hỏi của Giám đốc và chấm điểm xác suất (từ 0.0 đến 1.0) cho từng khả năng (capability) của nhân viên này, cùng khả năng 'other' (nếu ngoài chuyên môn).\n\n"
            f"DANH SÁCH KHẢ NĂNG (CAPABILITIES):\n"
            f"{json.dumps(capabilities_summary, ensure_ascii=False, indent=2)}\n\n"
            f"GIỚI HẠN (LIMITATIONS):\n"
            f"{json.dumps(self.definition.limitations, ensure_ascii=False, indent=2)}\n\n"
            f"CÂU HỎI CỦA GIÁM ĐỐC:\n"
            f"\"{user_message}\"\n\n"
            f"YÊU CẦU: Trả về DUY NHẤT một chuỗi JSON hợp lệ theo đúng cấu trúc sau (không kèm markdown thừa):\n"
            f"{{\n"
            f"  \"scores\": {{\n"
            f"    \"<capability_id_1>\": 0.05,\n"
            f"    \"<capability_id_2>\": 0.95,\n"
            f"    \"other\": 0.02\n"
            f"  }},\n"
            f"  \"in_scope\": true hoặc false,\n"
            f"  \"matched_capability_id\": \"id capability có điểm cao nhất (nếu in_scope=true), hoặc null\",\n"
            f"  \"user_intent_summary\": \"tóm tắt ngắn gọn ý định của Giám đốc bằng tiếng Việt\",\n"
            f"  \"confidence\": 0.95,\n"
            f"  \"reason\": \"lý do ngắn gọn\"\n"
            f"}}"
        )

        try:
            raw_output = None
            if hasattr(llm_service, "primary") and llm_service.primary:
                raw_output = await llm_service.primary._send_prompt(prompt)

            if raw_output:
                json_match = re.search(r"\{.*\}", raw_output, re.DOTALL)
                if json_match:
                    parsed = json.loads(json_match.group(0))
                    raw_scores = parsed.get("scores", {})
                    # Ensure all capabilities exist in scores
                    scores: Dict[str, float] = {}
                    for cap in self.definition.capabilities:
                        scores[cap.id] = float(raw_scores.get(cap.id, 0.02))
                    scores["other"] = float(raw_scores.get("other", 0.02 if parsed.get("in_scope") else 0.95))

                    return IntentScopeResult(
                        in_scope=bool(parsed.get("in_scope", False)),
                        matched_capability_id=parsed.get("matched_capability_id"),
                        user_intent_summary=parsed.get("user_intent_summary", user_message),
                        confidence=float(parsed.get("confidence", 0.95)),
                        reason=parsed.get("reason", ""),
                        capability_scores=scores,
                    )
        except Exception as e:
            logger.warning("LLM scope classification exception for %s: %s", self.id, e)

        # Deterministic fallback based on capabilities and limitations
        return self._fallback_classify_scope(user_message)

    def _check_hard_limitations(self, user_message: str) -> Optional[IntentScopeResult]:
        lower = user_message.lower().strip()
        scores: Dict[str, float] = {cap.id: 0.01 for cap in self.definition.capabilities}
        scores["other"] = 0.98

        for lim in self.definition.limitations:
            lim_lower = lim.lower()
            if ("email" in lim_lower or "hộp thư" in lim_lower) and any(
                k in lower for k in ["gmail", "email", "hòm thư", "dọn thư", "dọn email"]
            ):
                return IntentScopeResult(
                    in_scope=False,
                    matched_capability_id=None,
                    user_intent_summary="Dọn dẹp và quản lý hộp thư email",
                    confidence=0.99,
                    reason="Vi phạm giới hạn: không can thiệp email",
                    capability_scores=scores,
                )
            if ("vé máy bay" in lim_lower or "khách sạn" in lim_lower or "du lịch" in lim_lower) and any(
                k in lower for k in ["vé máy bay", "khách sạn", "du lịch", "gym"]
            ):
                return IntentScopeResult(
                    in_scope=False,
                    matched_capability_id=None,
                    user_intent_summary="Đặt vé máy bay / khách sạn / dịch vụ ngoài",
                    confidence=0.99,
                    reason="Vi phạm giới hạn: dịch vụ ngoài phạm vi",
                    capability_scores=scores,
                )
            if ("google calendar" in lim_lower or "calendar" in lim_lower or "lịch" in lim_lower) and any(
                k in lower for k in [
                    "google calendar",
                    "apple calendar",
                    "lịch google",
                    "đồng bộ calendar",
                    "đọc lịch google",
                    "calendar",
                    "google cal",
                ]
            ):
                return IntentScopeResult(
                    in_scope=False,
                    matched_capability_id=None,
                    user_intent_summary="Đọc hoặc đồng bộ Google Calendar",
                    confidence=0.99,
                    reason="Vi phạm giới hạn hệ thống: vnverse chỉ gửi tin nhắn trong app và thông báo thiết bị, không liên kết Google Calendar",
                    capability_scores=scores,
                )
            if ("gọi điện" in lim_lower or "sms" in lim_lower) and any(
                k in lower for k in ["gọi điện", "gọi điện thoại", "nhắn sms", "gửi sms"]
            ):
                return IntentScopeResult(
                    in_scope=False,
                    matched_capability_id=None,
                    user_intent_summary="Gọi điện thoại hoặc gửi SMS viễn thông",
                    confidence=0.99,
                    reason="Vi phạm giới hạn hệ thống: không hỗ trợ gọi điện thoại hoặc gửi SMS",
                    capability_scores=scores,
                )

        return None

    def _fallback_classify_scope(self, user_message: str) -> IntentScopeResult:
        hard_limitation = self._check_hard_limitations(user_message)
        if hard_limitation is not None:
            return hard_limitation

        lower = user_message.lower().strip()
        scores: Dict[str, float] = {cap.id: 0.01 for cap in self.definition.capabilities}
        scores["other"] = 0.01
        if "reminder" in [c.id for c in self.definition.capabilities]:
            # Non-spiritual reminders belong to other agents
            if any(w in lower for w in ["họp", "ban giám đốc", "check email", "gửi báo cáo", "hạn nộp"]):
                scores["other"] = 0.95
                return IntentScopeResult(
                    in_scope=False,
                    matched_capability_id=None,
                    user_intent_summary="Nhắc nhở lịch họp / công việc phi tâm linh",
                    confidence=0.95,
                    reason="Ngoài chuyên môn Thầy Cúng (thuộc agent đặt lịch họp/công việc)",
                    capability_scores=scores,
                )

            # If user asks to remind OR provides reminder slot-filling details (date, occasion, time)
            has_explicit_remind = any(k in lower for k in ["nhắc", "hẹn giờ", "báo thức", "lên lịch nhắc", "cài đặt nhắc", "tự động thông báo"])
            has_spiritual_keywords = any(w in lower for w in ["thắp hương", "mùng 1", "rằm", "giỗ", "sóc", "vọng", "âm lịch", "cúng", "lễ"])
            has_date_pattern = bool(re.search(r"\b\d{1,2}[/-]\d{1,2}\b", lower) or re.search(r"(?:ngày|mùng)\s*\d{1,2}", lower))

            if (has_explicit_remind and has_spiritual_keywords) or (has_spiritual_keywords and has_date_pattern) or (has_date_pattern and any(w in lower for w in ["lúc", "giờ", "giỗ", "cụ", "ông", "bà", "mẹ", "bố", "lễ"])):
                scores["reminder"] = 0.95
                scores["other"] = 0.02
                return IntentScopeResult(
                    in_scope=True,
                    matched_capability_id="reminder",
                    user_intent_summary="Nhắc nhở ngày sóc vọng & giỗ chạp tự động",
                    confidence=0.95,
                    reason="Khớp capability reminder của Thầy Cúng",
                    capability_scores=scores,
                )

        # Check capabilities
        for cap in self.definition.capabilities:
            for sample in cap.sample_queries:
                sample_lower = sample.lower()
                if sample_lower in lower or any(w in lower for w in sample_lower.split() if len(w) > 3):
                    scores[cap.id] = 0.95
                    scores["other"] = 0.02
                    return IntentScopeResult(
                        in_scope=True,
                        matched_capability_id=cap.id,
                        user_intent_summary=cap.name,
                        confidence=0.95,
                        reason=f"Khớp capability {cap.id}",
                        capability_scores=scores,
                    )

        # Special keywords for Thầy Cúng workplace rituals
        if any(k in lower for k in ["bài cúng", "văn khấn", "cúng", "mâm lễ", "thắp hương", "cháy", "dự án"]):
            for cap in self.definition.capabilities:
                if "traditional" in cap.id or "prayer" in cap.id:
                    scores[cap.id] = 0.95
                    scores["other"] = 0.02
                    return IntentScopeResult(
                        in_scope=True,
                        matched_capability_id=cap.id,
                        user_intent_summary=cap.name,
                        confidence=0.95,
                        reason=f"Khớp capability {cap.id}",
                        capability_scores=scores,
                    )

        # Default greeting / general questions about this agent
        if any(k in lower for k in ["chào", "bạn là ai", "làm được gì", "giúp gì", "hello", "hi"]):
            first_cap_id = self.definition.capabilities[0].id if self.definition.capabilities else None
            if first_cap_id:
                scores[first_cap_id] = 0.70
            scores["other"] = 0.10
            return IntentScopeResult(
                in_scope=True,
                matched_capability_id=first_cap_id,
                user_intent_summary="Chào hỏi và tìm hiểu năng lực nhân viên",
                confidence=0.95,
                reason="Chào hỏi cơ bản nhân viên",
                capability_scores=scores,
            )

        scores["other"] = 0.95
        return IntentScopeResult(
            in_scope=False,
            matched_capability_id=None,
            user_intent_summary=user_message,
            confidence=0.85,
            reason="Không khớp bất kỳ capability nào",
            capability_scores=scores,
        )

    async def handle_in_scope_message(
        self,
        user_message: str,
        scope_result: IntentScopeResult,
        llm_service: Any,
        context: Optional[Dict[str, Any]] = None,
    ) -> str:
        """
        Generates in-scope answer using agent system prompt and persona.
        Subclasses can override for domain-specific programmatic processing.
        """
        prompt = (
            f"{self.system_prompt}\n\n"
            f"Bối cảnh: Giám đốc đang trò chuyện trực tiếp với bạn ({self.definition.default_name}).\n"
            f"Khả năng đang thực hiện: {scope_result.matched_capability_id or 'Hỗ trợ nghiệp vụ'}\n"
            f"Câu hỏi của Giám đốc: \"{user_message}\"\n\n"
            f"Hãy xưng hô kính cẩn (thưa Giám đốc/sếp, xưng em), thể hiện đúng phong cách và chuyên môn của bạn."
        )

        try:
            if hasattr(llm_service, "primary") and llm_service.primary:
                resp = await llm_service.primary._send_prompt(prompt)
                if resp and len(resp.strip()) > 10:
                    return resp.strip()
        except Exception as e:
            logger.warning("LLM response generation failed for %s: %s", self.id, e)

        return (
            f"Dạ thưa Giám đốc! Em là {self.definition.default_name}. "
            f"Em đã nhận yêu cầu: \"{user_message}\". "
            f"Về phần việc này em luôn sẵn sàng phục vụ sếp chu đáo nhất ạ!"
        )
