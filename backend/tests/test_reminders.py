import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from app.schemas.assistant import AssistantIntent


@pytest.mark.asyncio
async def test_reminders_crud_and_test_run():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 1. List reminders for thay_cung (should have at least the pre-seeded default)
        res = await ac.get("/api/v1/agents/thay_cung/reminders")
        assert res.status_code == 200
        reminders = res.json()
        assert len(reminders) >= 1
        default_rem = reminders[0]
        assert default_rem["agent_id"] == "thay_cung"

        # 2. Create a custom reminder
        create_payload = {
            "agent_id": "thay_cung",
            "title": "Nhắc Giỗ Cụ",
            "description": "Nhắc Giám đốc thắp hương ngày giỗ cụ 15/3 âm lịch",
            "schedule": {
                "type": "lunar_yearly",
                "days": [15],
                "month": 3,
            },
            "target_time": "07:00",
            "occasion": "Giỗ Cụ",
            "custom_payload": {"spiritual_notes": "hoa quả thanh tịnh"},
            "is_enabled": True,
        }
        create_res = await ac.post("/api/v1/agents/thay_cung/reminders", json=create_payload)
        assert create_res.status_code == 201
        new_rem = create_res.json()
        new_id = new_rem["id"]
        assert new_rem["title"] == "Nhắc Giỗ Cụ"
        assert new_rem["is_enabled"] is True

        # 3. Toggle reminder OFF
        patch_res = await ac.patch(f"/api/v1/reminders/{new_id}", json={"is_enabled": False})
        assert patch_res.status_code == 200
        assert patch_res.json()["is_enabled"] is False

        # 4. Execute test run
        test_run_res = await ac.post(f"/api/v1/reminders/{new_id}/test-run")
        assert test_run_res.status_code == 200
        run_data = test_run_res.json()
        assert run_data["reminder_id"] == new_id
        assert "Thầy Cúng" in run_data["simulated_message"]
        assert "Giỗ Cụ" in run_data["simulated_message"]

        # 5. Delete reminder
        del_res = await ac.delete(f"/api/v1/reminders/{new_id}")
        assert del_res.status_code == 204

        # Verify deletion
        get_res = await ac.get(f"/api/v1/reminders/{new_id}")
        assert get_res.status_code == 404


@pytest.mark.asyncio
async def test_thay_cung_chat_prompts_interactive_reminder_checkbox():
    """Verify asking Thầy Cúng to remind incense prompts interactive multi-checkbox."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={
                "message": "Thầy ơi nhắc tôi thắp hương",
                "agent_id": "thay_cung",
                "locale": "vi",
            },
        )
        assert res.status_code == 200
        data = res.json()
        assert data["agent_id"] == "thay_cung"
        assert data["action_type"] == "reminder"
        assert "interactive_config" in data and data["interactive_config"] is not None
        config = data["interactive_config"]
        assert config["config_type"] == "reminder_days"
        assert config["is_multi_select"] is True
        assert len(config["options"]) >= 2
        assert "Mùng 1" in config["options"][0]["label"]
        assert "Ngày rằm" in config["options"][1]["label"]


@pytest.mark.asyncio
async def test_thay_cung_chat_custom_anniversary_reminder_created():
    """Verify specifying a custom anniversary directly creates the reminder."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={
                "message": "Nhắc tôi ngày 15/3 âm lịch là ngày giỗ cụ nhé",
                "agent_id": "thay_cung",
                "locale": "vi",
            },
        )
        assert res.status_code == 200
        data = res.json()
        assert data["agent_id"] == "thay_cung"
        assert "Giỗ cụ" in data["reply"]
        assert "15/3 Âm lịch" in data["reply"]
        assert "Nhân viên" in data["reply"]


@pytest.mark.asyncio
async def test_thay_cung_asks_details_when_selecting_custom_date_without_specifics():
    """Verify selecting 'Ngày khác tuỳ chọn' without date asks ONLY for the required date instead of hardcoding."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # User clicks confirmation from checkbox selecting only custom date
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={
                "message": "Tôi chọn lịch nhắc: Ngày khác tuỳ chọn (giỗ cụ, ngày lễ...). Hãy lưu lịch nhắc nhở này cho tôi nhé!",
                "agent_id": "thay_cung",
                "locale": "vi",
            },
        )
        assert res.status_code == 200
        data = res.json()
        assert data["agent_id"] == "thay_cung"
        reply = data["reply"]
        # Must ask for the required date!
        assert "Sếp muốn Thầy lên lịch nhắc vào ngày âm lịch nào ạ?" in reply
        # MUST NOT claim to have scheduled a default 15/3 Giỗ cụ!
        assert "Thầy đã cài đặt lịch nhắc nhở ngày" not in reply


@pytest.mark.asyncio
async def test_thay_cung_dynamic_slot_filling_with_short_user_answer():
    """Verify user can answer slot filling with 'giỗ cụ 10/24 lúc 2:04' dynamically."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={
                "message": "giỗ cụ 10/24 lúc 2:04",
                "agent_id": "thay_cung",
                "locale": "vi",
            },
        )
        assert res.status_code == 200
        data = res.json()
        assert data["agent_id"] == "thay_cung"
        reply = data["reply"]
        # Must dynamically detect 10/24, occasion Giỗ cụ, and time 02:04
        assert "10/24" in reply
        assert "Giỗ cụ" in reply
        assert "02:04" in reply
        assert "Nhân viên" in reply


@pytest.mark.asyncio
async def test_thay_cung_creates_dynamic_custom_reminder_with_custom_date_and_time():
    """Verify Thầy Cúng dynamically parses occasion, custom lunar day/month, and target time."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={
                "message": "Nhắc ngày giỗ mẹ 20/8 âm lịch lúc 8h sáng nhé",
                "agent_id": "thay_cung",
                "locale": "vi",
            },
        )
        assert res.status_code == 200
        data = res.json()
        assert data["agent_id"] == "thay_cung"
        reply = data["reply"]
        assert "Giỗ mẹ" in reply or "Giỗ Mẹ" in reply
        assert "20/8 Âm lịch" in reply
        assert "08:00" in reply


@pytest.mark.asyncio
async def test_thay_cung_rejects_google_calendar_as_system_limitation():
    """Verify asking to read/sync Google Calendar is rejected as a platform boundary limitation."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={
                "message": "Đọc Google Calendar của tôi rồi nhắc lịch cúng",
                "agent_id": "thay_cung",
                "locale": "vi",
            },
        )
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] == AssistantIntent.OTHER
        # Must be rejected because vnverse does not support syncing external calendars
        assert data["action_type"] == "unsupported" or "Google Calendar" in data["reply"] or "Bộ trưởng" in data["reply"]


@pytest.mark.asyncio
async def test_thay_cung_rejects_non_spiritual_meeting_reminder():
    """Verify asking Thầy Cúng for a non-spiritual meeting reminder is treated as out of scope."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={
                "message": "Nhắc tôi họp ban giám đốc lúc 14h chiều",
                "agent_id": "thay_cung",
                "locale": "vi",
            },
        )
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] == AssistantIntent.OTHER
