from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class ReminderSchedule(BaseModel):
    type: str = Field(..., description="Schedule type: lunar_monthly, lunar_yearly, solar_weekly, solar_monthly, solar_once")
    days: List[int] = Field(default_factory=list, description="Days of month or lunar month, e.g. [1, 15]")
    month: Optional[int] = Field(None, description="Month (for yearly reminders, e.g. 3 for 15/3)")
    weekday: Optional[int] = Field(None, description="Day of week (1=Mon, 7=Sun)")


class ReminderCreate(BaseModel):
    agent_id: str = Field(..., description="ID of the agent responsible for this reminder")
    title: str = Field(..., description="Human readable title of reminder")
    description: str = Field(..., description="Detailed description")
    schedule: ReminderSchedule = Field(..., description="Schedule details")
    target_time: str = Field(default="07:00", description="Time of day in HH:mm format, e.g. 07:00")
    occasion: Optional[str] = Field(None, description="Name of occasion/event, e.g. Giỗ cụ")
    custom_payload: Dict[str, Any] = Field(default_factory=dict, description="Agent-specific custom metadata")
    is_enabled: bool = Field(default=True, description="Whether this reminder is active")


class ReminderUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    schedule: Optional[ReminderSchedule] = None
    target_time: Optional[str] = None
    occasion: Optional[str] = None
    custom_payload: Optional[Dict[str, Any]] = None
    is_enabled: Optional[bool] = None


class ReminderResponse(BaseModel):
    id: str
    agent_id: str
    title: str
    description: str
    schedule: ReminderSchedule
    target_time: str
    occasion: Optional[str] = None
    custom_payload: Dict[str, Any] = Field(default_factory=dict)
    is_enabled: bool
    created_at: str
    last_run_at: Optional[str] = None


class ReminderTestRunResponse(BaseModel):
    reminder_id: str
    agent_id: str
    triggered_at: str
    simulated_message: str
    notification_title: str
    notification_body: str
