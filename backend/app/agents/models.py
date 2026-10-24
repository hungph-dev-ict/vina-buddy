from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class AgentPersonality(BaseModel):
    tone: str = "friendly"
    style: str = "office_humor"


class AgentCapability(BaseModel):
    id: str
    name: str
    description: str
    supported_intents: List[str] = Field(default_factory=list)
    sample_queries: List[str] = Field(default_factory=list)
    requires_external_permission: bool = False


class AgentDefinition(BaseModel):
    id: str
    default_name: str
    category: str
    avatar_symbol: str = "🤖"
    description: str
    required_permissions: List[str] = Field(default_factory=list)
    personality: AgentPersonality = Field(default_factory=AgentPersonality)
    capabilities: List[AgentCapability] = Field(default_factory=list)
    limitations: List[str] = Field(default_factory=list)
    version: int = 1
    is_placeholder: bool = False


class IntentScopeResult(BaseModel):
    in_scope: bool
    matched_capability_id: Optional[str] = None
    user_intent_summary: str = ""
    confidence: float = 0.95
    reason: str = ""
    capability_scores: Dict[str, float] = Field(default_factory=dict)
