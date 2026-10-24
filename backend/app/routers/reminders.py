import logging
from typing import List, Optional
from fastapi import APIRouter, HTTPException, Query, status

from app.schemas.reminders import (
    ReminderCreate,
    ReminderResponse,
    ReminderTestRunResponse,
    ReminderUpdate,
)
from app.services.reminders_service import get_reminders_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1", tags=["Reminders"])


@router.get("/agents/{agent_id}/reminders", response_model=List[ReminderResponse])
async def list_agent_reminders(agent_id: str) -> List[ReminderResponse]:
    """Retrieve all background reminders registered for a specific agent."""
    svc = get_reminders_service()
    return svc.list_reminders(agent_id=agent_id)


@router.post("/agents/{agent_id}/reminders", response_model=ReminderResponse, status_code=status.HTTP_201_CREATED)
async def create_agent_reminder(agent_id: str, payload: ReminderCreate) -> ReminderResponse:
    """Register a new autonomous background reminder for an agent."""
    if payload.agent_id != agent_id:
        payload.agent_id = agent_id
    svc = get_reminders_service()
    return svc.create_reminder(payload)


@router.get("/reminders/{reminder_id}", response_model=ReminderResponse)
async def get_reminder(reminder_id: str) -> ReminderResponse:
    """Fetch details of a single reminder by ID."""
    svc = get_reminders_service()
    reminder = svc.get_reminder(reminder_id)
    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")
    return reminder


@router.patch("/reminders/{reminder_id}", response_model=ReminderResponse)
async def update_reminder(reminder_id: str, payload: ReminderUpdate) -> ReminderResponse:
    """Update reminder status (toggle on/off) or configuration fields."""
    svc = get_reminders_service()
    updated = svc.update_reminder(reminder_id, payload)
    if not updated:
        raise HTTPException(status_code=404, detail="Reminder not found")
    return updated


@router.delete("/reminders/{reminder_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_reminder(reminder_id: str) -> None:
    """Delete a reminder by ID."""
    svc = get_reminders_service()
    deleted = svc.delete_reminder(reminder_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Reminder not found")


@router.post("/reminders/{reminder_id}/test-run", response_model=ReminderTestRunResponse)
async def test_run_reminder(reminder_id: str) -> ReminderTestRunResponse:
    """Simulate reminder execution immediately, producing agent proactive message and notification payload."""
    svc = get_reminders_service()
    res = svc.execute_test_run(reminder_id)
    if not res:
        raise HTTPException(status_code=404, detail="Reminder not found")
    return res
