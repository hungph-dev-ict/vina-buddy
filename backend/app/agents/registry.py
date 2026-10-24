import importlib.util
import logging
from pathlib import Path
from typing import Dict, List, Optional

from app.agents.base_agent import BaseAgent

logger = logging.getLogger(__name__)


class AgentRegistry:
    """
    Central registry that discovers, loads, and manages all vnverse agents.
    Allows adding new agents simply by creating a new folder with definition.json!
    """

    _instance: Optional["AgentRegistry"] = None

    def __new__(cls) -> "AgentRegistry":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._agents: Dict[str, BaseAgent] = {}
            cls._instance._load_all_agents()
        return cls._instance

    def _load_all_agents(self) -> None:
        agents_root = Path(__file__).parent
        for item in agents_root.iterdir():
            if item.is_dir() and (item / "definition.json").exists():
                try:
                    agent = self._load_agent_from_dir(item)
                    self._agents[agent.id] = agent
                    logger.info("Registered vnverse agent: %s (%s)", agent.id, agent.default_name)
                except Exception as e:
                    logger.error("Failed to load agent from %s: %s", item, e)

    def _load_agent_from_dir(self, agent_dir: Path) -> BaseAgent:
        # Check if specialized handler.py exists
        handler_file = agent_dir / "handler.py"
        if handler_file.exists():
            spec = importlib.util.spec_from_file_location(
                f"app.agents.{agent_dir.name}.handler", handler_file
            )
            if spec and spec.loader:
                module = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(module)
                # Look for a class ending with 'Agent' that subclasses BaseAgent
                for attr_name in dir(module):
                    attr = getattr(module, attr_name)
                    if (
                        isinstance(attr, type)
                        and issubclass(attr, BaseAgent)
                        and attr is not BaseAgent
                    ):
                        return attr(agent_dir)

        # Fallback to standard BaseAgent instance
        return BaseAgent(agent_dir)

    def get_agent(self, agent_id: str) -> Optional[BaseAgent]:
        return self._agents.get(agent_id)

    def list_agents(self) -> List[BaseAgent]:
        return list(self._agents.values())

    def find_matching_agent_for_intent(
        self, query: str, intent_summary: str = "", exclude_agent_id: Optional[str] = None
    ) -> Optional[BaseAgent]:
        """
        Finds an agent in the registry capable of handling this query or intent.
        Excludes the inquiring agent.
        """
        lower_q = f"{query} {intent_summary}".lower()

        # 1. First check queries clearly outside vnverse company scope (escalate to Minister)
        if any(
            k in lower_q
            for k in [
                "vé máy bay",
                "khách sạn",
                "du lịch",
                "tập gym",
                "gym",
                "giao đồ ăn",
                "đặt xe",
                "mua vé",
            ]
        ):
            return None

        # 2. Email / Mailbox tasks prioritize Thư ký Email
        if any(
            k in lower_q
            for k in [
                "gmail",
                "email",
                "hòm thư",
                "dọn thư",
                "dọn email",
                "gán nhãn",
                "lọc email",
                "lọc thư",
                "thư rác",
            ]
        ):
            if exclude_agent_id != "thu_ky_email":
                return self.get_agent("thu_ky_email")

        # 3. Check capabilities of each agent in registry
        for agent in self._agents.values():
            if exclude_agent_id and agent.id == exclude_agent_id:
                continue

            for cap in agent.definition.capabilities:
                for sample in cap.sample_queries:
                    if sample.lower() in lower_q:
                        return agent
                if cap.name.lower() in lower_q:
                    return agent

        # 4. Keyword heuristics for specialized categories
        if any(k in lower_q for k in ["tiền", "chi tiêu", "ngân sách", "lương", "kế toán"]):
            if exclude_agent_id != "ke_toan_chi_tieu":
                return self.get_agent("ke_toan_chi_tieu") or self.get_agent("ke_toan")
        if any(k in lower_q for k in ["máy tính", "wifi", "mạng", "kỹ thuật", "lỗi máy"]):
            if exclude_agent_id != "it_support":
                return self.get_agent("it_support")
        if any(k in lower_q for k in ["rằm", "mùng 1", "âm lịch", "văn khấn", "cúng", "lễ"]):
            if exclude_agent_id != "thay_cung":
                return self.get_agent("thay_cung")

        return None
