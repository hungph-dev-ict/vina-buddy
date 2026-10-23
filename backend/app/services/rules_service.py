import logging
import uuid
from datetime import datetime, timezone
from typing import Dict, List, Optional

from app.config import settings
from app.llm import (
    LLMUnsupportedContentError,
    LLMValidationError,
    ResilientLLMService,
    get_default_primary_provider,
)
from app.schemas.rules import (
    CreateRuleRequest,
    RuleAction,
    RuleCondition,
    RuleResponse,
)

logger = logging.getLogger(__name__)


class RulesService:
    """Manages rule creation, parsing, validation, and storage."""

    def __init__(self, llm_service: Optional[ResilientLLMService] = None) -> None:
        self.llm = llm_service or ResilientLLMService(
            primary_provider=get_default_primary_provider(),
        )
        self._rules_store: Dict[str, RuleResponse] = {}

    async def create_rule_from_text(self, request: CreateRuleRequest) -> RuleResponse:
        """
        Parse natural language into structured, validated rule(s).
        Enforces multi-intent separation, strict schema validation, and uncertainty flagging.
        """
        text = request.natural_language.strip()
        raw_dict, provider_name = await self.llm.parse_rule(text)

        if raw_dict.get("supported") is False:
            msg = raw_dict.get("message") or "Nội dung này không thể hỗ trợ, vui lòng khiếu nại tới admin."
            raise LLMUnsupportedContentError(msg)

        # Extract rules list or single rule
        raw_rules_list: List[Dict] = []
        if "rules" in raw_dict and isinstance(raw_dict["rules"], list):
            raw_rules_list = raw_dict["rules"]
        else:
            # Guardrail: If a single output has multiple conditions and matching multiple actions,
            # decouple them so condition 1 maps to action 1, and condition 2 maps to action 2.
            raw_c = raw_dict.get("conditions", [])
            raw_a = raw_dict.get("actions", [])
            if len(raw_c) > 1 and len(raw_c) == len(raw_a):
                for c, a in zip(raw_c, raw_a):
                    val = c.get("value", "item")
                    raw_rules_list.append({
                        "name": f"Label {val}",
                        "conditions": [c],
                        "actions": [a],
                        "priority": raw_dict.get("priority", 1),
                        "confidence": raw_dict.get("confidence", 0.95),
                    })
            else:
                raw_rules_list = [raw_dict]

        if not raw_rules_list:
            raise LLMValidationError("Rule output contains no valid rules.")

        created_rules: List[RuleResponse] = []
        now = datetime.now(timezone.utc).isoformat()

        for idx, item in enumerate(raw_rules_list):
            try:
                name = str(item.get("name", f"Custom Rule {idx + 1}")).strip() or "Custom Rule"
                raw_conditions = item.get("conditions", [])
                raw_actions = item.get("actions", [])
                confidence = float(item.get("confidence", 0.90))

                if not raw_conditions:
                    raise LLMValidationError("Rule must contain at least one condition.")
                if not raw_actions:
                    raise LLMValidationError("Rule must contain at least one action.")

                validated_conditions = [RuleCondition(**c) for c in raw_conditions]
                validated_actions = [RuleAction(**a) for a in raw_actions]

                priority = int(item.get("priority", 1))
                is_uncertain = confidence < settings.MIN_CONFIDENCE_THRESHOLD
                rule_id = f"rule_{uuid.uuid4().hex[:8]}"

                rule = RuleResponse(
                    id=rule_id,
                    name=name,
                    natural_language=text,
                    conditions=validated_conditions,
                    actions=validated_actions,
                    priority=priority,
                    enabled=True,
                    llm_confidence=confidence,
                    llm_provider=provider_name,
                    is_uncertain=is_uncertain,
                    created_at=now,
                    updated_at=now,
                )
                self._rules_store[rule_id] = rule
                created_rules.append(rule)
                logger.info("Rule created successfully: id=%s name='%s'", rule_id, name)
            except (ValueError, TypeError) as exc:
                raise LLMValidationError(f"Invalid rule output structure: {exc}") from exc

        primary_rule = created_rules[0]
        if len(created_rules) > 1:
            primary_rule.sub_rules = created_rules[1:]

        return primary_rule


    def get_rule(self, rule_id: str) -> Optional[RuleResponse]:
        """Retrieve rule by ID."""
        return self._rules_store.get(rule_id)

    def list_rules(self) -> List[RuleResponse]:
        """List all rules."""
        return list(self._rules_store.values())

    def delete_rule(self, rule_id: str) -> bool:
        """Delete rule by ID."""
        if rule_id in self._rules_store:
            del self._rules_store[rule_id]
            return True
        return False

    def toggle_rule(self, rule_id: str, enabled: bool) -> Optional[RuleResponse]:
        """Toggle rule enabled status."""
        rule = self._rules_store.get(rule_id)
        if not rule:
            return None
        updated = rule.model_copy(
            update={
                "enabled": enabled,
                "updated_at": datetime.now(timezone.utc).isoformat(),
            }
        )
        self._rules_store[rule_id] = updated
        return updated
