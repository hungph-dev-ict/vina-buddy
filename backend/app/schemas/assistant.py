from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class AssistantIntent(str, Enum):
    RECOMMEND_AGENT = "recommend_agent"
    CHITCHAT = "chitchat"
    OUT_OF_SCOPE = "out_of_scope"
    STATS = "stats"
    CLASSIFY = "classify"
    LABEL = "label"
    OTHER = "other"


class EmailCategoryStat(BaseModel):
    category_id: str
    category_name: str
    count: int
    unread: int
    color_hex: str


class TopSenderStat(BaseModel):
    sender_name: str
    sender_email: str
    count: int


class EmailStatsPayload(BaseModel):
    total_emails: int
    unread_emails: int
    read_emails: int
    categories: List[EmailCategoryStat] = Field(default_factory=list)
    top_senders: List[TopSenderStat] = Field(default_factory=list)
    last_synced_at: Optional[str] = None


class EmailClassifyCategory(BaseModel):
    category_id: str
    category_name: str
    description: str
    matched_count: int
    sample_senders: List[str] = Field(default_factory=list)
    suggested_label: str


class EmailClassifyPayload(BaseModel):
    total_analyzed: int
    categories: List[EmailClassifyCategory] = Field(default_factory=list)


class CleanupProposalPayload(BaseModel):
    rule_id: str
    rule_name: str
    target_label: str
    matched_count: int
    sample_subjects: List[str] = Field(default_factory=list)
    explanation: str
    matched_email_ids: List[str] = Field(default_factory=list)


class ChatMessage(BaseModel):
    role: str  # "user" | "assistant"
    content: str
    timestamp: Optional[str] = None


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000)
    session_id: Optional[str] = None
    agent_id: Optional[str] = "coordinator"
    history: List[ChatMessage] = Field(default_factory=list)
    locale: str = "vi"  # "vi" or "en"


class ChatResponse(BaseModel):
    reply: str
    intent: AssistantIntent
    action_type: str  # "stats" | "classify" | "label_proposal" | "label_prompt" | "unsupported" | "rule_created"
    confidence: float = Field(default=0.95, description="LLM classification confidence score (0.0 to 1.0)")
    llm_provider: str = Field(default="Ollama (qwen2.5:3b)", description="LLM provider and model name")
    agent_id: Optional[str] = "coordinator"
    recommend_agent_id: Optional[str] = None
    handoff: Optional[Dict[str, Any]] = None
    stats: Optional[EmailStatsPayload] = None
    classification: Optional[EmailClassifyPayload] = None
    proposal: Optional[CleanupProposalPayload] = None
    intent_scores: Optional[Dict[str, float]] = Field(
        default=None, description="Confidence scores for all 4 intents: stats, classify, label, other"
    )
    rule_validation: Optional[Dict[str, Any]] = Field(
        default=None, description="Rule validation result: is_valid_rule, condition, label"
    )
    interactive_config: Optional[Dict[str, Any]] = Field(
        default=None, description="Interactive multi-checkbox or option prompt for slot-filling"
    )
    suggested_actions: List[str] = Field(
        default_factory=lambda: ["stats", "classify", "label"]
    )


