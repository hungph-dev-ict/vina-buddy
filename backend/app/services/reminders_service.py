import json
import logging
import os
import uuid
from datetime import datetime
from typing import Dict, List, Optional

from app.schemas.reminders import (
    ReminderCreate,
    ReminderResponse,
    ReminderSchedule,
    ReminderTestRunResponse,
    ReminderUpdate,
)

logger = logging.getLogger(__name__)

STORE_FILE = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), ".reminders_store.json")


class RemindersService:
    """
    Core System Reminder Engine.
    Manages scheduling, CRUD, and proactive message execution for all agents in vnverse.
    """

    def __init__(self, store_file: str = STORE_FILE) -> None:
        self.store_file = store_file
        self._reminders: Dict[str, Dict] = {}
        self._load_store()
        self._seed_default_reminders_if_empty()

    def _load_store(self) -> None:
        if os.path.exists(self.store_file):
            try:
                with open(self.store_file, "r", encoding="utf-8") as f:
                    self._reminders = json.load(f)
            except Exception as e:
                logger.warning("Failed to load reminders store (%s). Initializing fresh.", e)
                self._reminders = {}

    def _save_store(self) -> None:
        try:
            with open(self.store_file, "w", encoding="utf-8") as f:
                json.dump(self._reminders, f, ensure_ascii=False, indent=2)
        except Exception as e:
            logger.error("Failed to save reminders store: %s", e)

    def _seed_default_reminders_if_empty(self) -> None:
        if not self._reminders:
            default_tc_reminder = {
                "id": "rem_tc_default_01",
                "agent_id": "thay_cung",
                "title": "Nhắc thắp hương Mùng 1 & Ngày Rằm",
                "description": "Nhắc Giám đốc thắp hương ngày Mùng 1 (sóc) và Ngày rằm 15 (vọng)",
                "schedule": {
                    "type": "lunar_monthly",
                    "days": [1, 15],
                    "month": None,
                    "weekday": None,
                },
                "target_time": "07:00",
                "occasion": "Lễ sóc vọng hàng tháng",
                "custom_payload": {
                    "spiritual_type": "altar_incense",
                    "recommended_offering": "hương hoa trà quả thanh tịnh",
                },
                "is_enabled": True,
                "created_at": datetime.now().isoformat(),
                "last_run_at": None,
            }
            self._reminders[default_tc_reminder["id"]] = default_tc_reminder
            self._save_store()

    def list_reminders(self, agent_id: Optional[str] = None) -> List[ReminderResponse]:
        items = list(self._reminders.values())
        if agent_id:
            items = [r for r in items if r.get("agent_id") == agent_id]
        # Sort by created_at desc
        items.sort(key=lambda x: x.get("created_at", ""), reverse=True)
        return [ReminderResponse(**item) for item in items]

    def get_reminder(self, reminder_id: str) -> Optional[ReminderResponse]:
        item = self._reminders.get(reminder_id)
        if not item:
            return None
        return ReminderResponse(**item)

    def create_reminder(self, data: ReminderCreate) -> ReminderResponse:
        rem_id = f"rem_{data.agent_id}_{uuid.uuid4().hex[:8]}"
        record = {
            "id": rem_id,
            "agent_id": data.agent_id,
            "title": data.title,
            "description": data.description,
            "schedule": data.schedule.model_dump(),
            "target_time": data.target_time,
            "occasion": data.occasion,
            "custom_payload": data.custom_payload,
            "is_enabled": data.is_enabled,
            "created_at": datetime.now().isoformat(),
            "last_run_at": None,
        }
        self._reminders[rem_id] = record
        self._save_store()
        logger.info("Created reminder %s for agent %s", rem_id, data.agent_id)
        return ReminderResponse(**record)

    def update_reminder(self, reminder_id: str, data: ReminderUpdate) -> Optional[ReminderResponse]:
        record = self._reminders.get(reminder_id)
        if not record:
            return None
        if data.title is not None:
            record["title"] = data.title
        if data.description is not None:
            record["description"] = data.description
        if data.schedule is not None:
            record["schedule"] = data.schedule.model_dump()
        if data.target_time is not None:
            record["target_time"] = data.target_time
        if data.occasion is not None:
            record["occasion"] = data.occasion
        if data.custom_payload is not None:
            record["custom_payload"] = data.custom_payload
        if data.is_enabled is not None:
            record["is_enabled"] = data.is_enabled
        self._save_store()
        return ReminderResponse(**record)

    def delete_reminder(self, reminder_id: str) -> bool:
        if reminder_id in self._reminders:
            del self._reminders[reminder_id]
            self._save_store()
            logger.info("Deleted reminder %s", reminder_id)
            return True
        return False

    def execute_test_run(self, reminder_id: str) -> Optional[ReminderTestRunResponse]:
        record = self._reminders.get(reminder_id)
        if not record:
            return None

        now_str = datetime.now().isoformat()
        record["last_run_at"] = now_str
        self._save_store()

        agent_id = record["agent_id"]
        title = record["title"]
        target_time = record.get("target_time", "07:00")
        occasion = record.get("occasion") or title

        if agent_id == "thay_cung":
            sim_msg = (
                f"🏮 **[Nhắc nhở tự động 24/24 từ Thầy Cúng]**\n\n"
                f"Dạ kính chào Giám đốc! Đúng lịch hẹn lúc **{target_time}**, Thầy Cúng xin gửi lời chúc an lành tới sếp.\n\n"
                f"Hôm nay là **{occasion}**. Sếp nhớ thành tâm thắp nén nhang thơm, dâng chén nước thanh tịnh cầu chúc cho công ty vnverse vạn sự hanh thông, nội bộ thuận hòa, công việc đại cát đại lợi nhé Giám đốc!"
            )
            notif_title = f"🏮 Thầy Cúng: Nhắc nhở {occasion}"
            notif_body = f"Giám đốc ơi, đúng lịch {target_time} hôm nay là {occasion}. Nhớ thắp hương cầu an lành nhé!"
        else:
            sim_msg = (
                f"⚡ **[Nhắc nhở tự động từ Nhân sự {agent_id}]**\n\n"
                f"Thưa Giám đốc! Đến lịch hẹn **{target_time}** cho: **{title}** ({occasion}). Sếp lưu ý công việc nhé ạ!"
            )
            notif_title = f"⚡ Nhắc nhở: {title}"
            notif_body = f"Giám đốc ơi, đến lịch {target_time}: {occasion}."

        return ReminderTestRunResponse(
            reminder_id=reminder_id,
            agent_id=agent_id,
            triggered_at=now_str,
            simulated_message=sim_msg,
            notification_title=notif_title,
            notification_body=notif_body,
        )


_service_instance: Optional[RemindersService] = None


def get_reminders_service() -> RemindersService:
    global _service_instance
    if _service_instance is None:
        _service_instance = RemindersService()
    return _service_instance
