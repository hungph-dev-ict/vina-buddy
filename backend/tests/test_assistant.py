import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from app.schemas.assistant import AssistantIntent


@pytest.mark.asyncio
async def test_assistant_chat_stats_intent():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={"message": "Cho tôi xem thống kê email của tôi", "locale": "vi"},
        )
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] == AssistantIntent.STATS
        assert data["action_type"] == "stats"
        assert data["stats"] is not None
        assert data["stats"]["total_emails"] > 0
        assert len(data["stats"]["categories"]) > 0
        assert data["suggested_actions"] == ["stats", "classify", "label"]


@pytest.mark.asyncio
async def test_assistant_chat_classify_intent():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={"message": "Phân loại email trong hộp thư đến", "locale": "vi"},
        )
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] == AssistantIntent.CLASSIFY
        assert data["action_type"] == "classify"
        assert data["classification"] is not None
        assert data["classification"]["total_analyzed"] > 0
        assert len(data["classification"]["categories"]) > 0


@pytest.mark.asyncio
async def test_assistant_chat_label_intent():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={"message": "Gắn nhãn email từ Amazon là Shopping", "locale": "vi"},
        )
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] == AssistantIntent.LABEL
        assert data["action_type"] == "label_proposal"
        assert data["proposal"] is not None
        assert data["proposal"]["rule_id"] != ""
        assert data["proposal"]["target_label"] != ""


@pytest.mark.asyncio
async def test_assistant_chat_unsupported_other_intent():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # User asks out of scope question
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={"message": "Thời tiết hôm nay ở Hà Nội thế nào?", "locale": "vi"},
        )
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] in (AssistantIntent.CHITCHAT, AssistantIntent.OTHER)
        assert data["action_type"] in ("chitchat", "unsupported")
        assert len(data["reply"]) > 20
        assert data["stats"] is None
        assert data["classification"] is None
        assert data["proposal"] is None


@pytest.mark.asyncio
async def test_assistant_chat_delete_request_rejected():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Delete request must be rejected to 'other' / unsupported
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={"message": "Xoá tất cả email rác", "locale": "vi"},
        )
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] in (AssistantIntent.OUT_OF_SCOPE, AssistantIntent.OTHER)
        assert data["action_type"] == "unsupported"


@pytest.mark.asyncio
async def test_assistant_chat_label_prompt_mode():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # User taps "gán nhãn email" button without rule
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={"message": "Gán nhãn email", "locale": "vi"},
        )
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] == AssistantIntent.LABEL
        assert data["action_type"] == "label_prompt"
        assert "Bạn muốn gán nhãn email như thế nào?" in data["reply"]
        assert "AI Dev Monitor" in data["reply"]
        assert data["confidence"] > 0.80


@pytest.mark.asyncio
async def test_assistant_chat_invalid_rule_rejected():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # User enters an invalid rule
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={"message": "Tôi muốn quản lý nhãn mà không có điều kiện gì hết", "locale": "vi"},
        )
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] == AssistantIntent.OTHER
        assert data["action_type"] == "unsupported"
        assert "không phải là một quy tắc hợp lệ" in data["reply"]
        assert "AI Dev Monitor" in data["reply"]


@pytest.mark.asyncio
async def test_assistant_chat_rule_creates_and_saves_to_my_rules():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # User describes a natural language rule
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={"message": "Gán nhãn email từ Shopee thành Mua sắm", "locale": "vi"},
        )
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] == AssistantIntent.LABEL
        assert data["action_type"] == "label_proposal"
        assert "My Rules" in data["reply"]
        assert data["proposal"] is not None
        assert data["proposal"]["target_label"] == "Mua sắm"

        # Verify the rule is now retrievable in GET /api/v1/rules
        rules_res = await ac.get("/api/v1/rules")
        assert rules_res.status_code == 200
        rules = rules_res.json()["rules"]
        assert any(r["id"] == data["proposal"]["rule_id"] for r in rules)


@pytest.mark.asyncio
async def test_llm_boundary_json_scores_and_rule_validation():
    """Verify strict LLM boundary: Call 1 scores JSON and Call 2 rule validation JSON appear at top of reply."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Call 1 test: Stats query
        res_stats = await ac.post(
            "/api/v1/assistant/chat",
            json={"message": "thống kê email", "locale": "vi"},
        )
        assert res_stats.status_code == 200
        data_stats = res_stats.json()
        assert data_stats["intent_scores"] is not None
        assert "stats" in data_stats["intent_scores"]
        assert "classify" in data_stats["intent_scores"]
        assert "label" in data_stats["intent_scores"]
        assert "other" in data_stats["intent_scores"]
        # Verify JSON appears at the top of reply
        assert "```json" in data_stats["reply"]
        assert '"intent": "stats"' in data_stats["reply"]
        assert '"scores"' in data_stats["reply"]

        # Call 2 test: Valid rule query
        res_rule = await ac.post(
            "/api/v1/assistant/chat",
            json={"message": "Gán nhãn email từ Shopee thành Mua sắm", "locale": "vi"},
        )
        assert res_rule.status_code == 200
        data_rule = res_rule.json()
        assert data_rule["rule_validation"] is not None
        assert data_rule["rule_validation"]["is_valid_rule"] is True
        assert data_rule["rule_validation"]["condition"]["field"] == "from"
        assert data_rule["rule_validation"]["condition"]["value"].lower() == "shopee"
        assert data_rule["rule_validation"]["label"] == "Mua sắm"
        # Verify both JSON blocks appear at the top of reply
        assert '"is_valid_rule": true' in data_rule["reply"]
        assert '"condition"' in data_rule["reply"]
        assert '"label": "Mua sắm"' in data_rule["reply"]


@pytest.mark.asyncio
async def test_assistant_chat_with_authenticated_session():
    """Verify assistant chat accepts Authorization header and delegates to session."""
    from app.routers.auth import auth_service

    # Create simulated session
    session_token, user_email, _ = await auth_service.exchange_google_code(
        auth_code="email:real.tester@gmail.com",
        redirect_uri="http://test/callback",
    )

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={"message": "thống kê email", "locale": "vi"},
            headers={"Authorization": f"Bearer {session_token}"},
        )
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] == AssistantIntent.STATS
        assert data["stats"] is not None
        assert data["stats"]["total_emails"] > 0


@pytest.mark.asyncio
async def test_assistant_chat_coordinator_recommends_thay_cung():
    """Verify Coordinator recommends Thầy Cúng when asking about lunar dates or offerings."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={"message": "Hôm nay có phải ngày rằm hay mùng 1 không?", "locale": "vi"},
        )
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] in (AssistantIntent.RECOMMEND_AGENT, AssistantIntent.OTHER)
        assert data["recommend_agent_id"] == "thay_cung"
        assert "Thầy Cúng" in data["reply"]


@pytest.mark.asyncio
async def test_assistant_chat_thay_cung_expert_response():
    """Verify Thầy Cúng handles lunar rituals, văn khấn, and lễ vật in 100% Vietnamese."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={
                "message": "Xin văn khấn rằm tháng Giêng cho công ty",
                "agent_id": "thay_cung",
                "locale": "vi",
            },
        )
        assert res.status_code == 200
        data = res.json()
        assert data["agent_id"] == "thay_cung"
        assert "Giám đốc" in data["reply"]
        assert "khấn" in data["reply"].lower() or "lễ" in data["reply"].lower()
        assert data.get("handoff") is None


@pytest.mark.asyncio
async def test_assistant_chat_thay_cung_project_on_fire_in_scope_with_capability_scores():
    """Verify Thầy Cúng handles 'bài cúng cho dự án đang cháy' in scope with dynamic capability scores."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={
                "message": "Cho thầy bài cúng cho dự án đang cháy",
                "agent_id": "thay_cung",
                "locale": "vi",
            },
        )
        assert res.status_code == 200
        data = res.json()
        assert data["agent_id"] == "thay_cung"
        assert data.get("handoff") is None
        # Must score across Thay Cung's capabilities
        assert "traditional_offerings_and_prayers" in data["reply"]
        assert "lunar_day_reminder" in data["reply"]
        assert "other" in data["reply"]
        assert "thần code" in data["reply"].lower() or "dự án đang cháy" in data["reply"].lower()


@pytest.mark.asyncio
async def test_assistant_chat_thay_cung_out_of_scope_handoff_to_email():
    """Verify Thầy Cúng gracefully hands off email tasks to Thư ký Email."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={
                "message": "Lọc cho thầy tất cả email từ ngân hàng",
                "agent_id": "thay_cung",
                "locale": "vi",
            },
        )
        assert res.status_code == 200
        data = res.json()
        assert data["agent_id"] == "thay_cung"
        assert data["handoff"] is not None
        assert data["handoff"]["recommendedAgentId"] == "thu_ky_email"
        assert data["recommend_agent_id"] == "thu_ky_email"
        assert "Thư ký Email" in data["reply"]


@pytest.mark.asyncio
async def test_assistant_chat_unsupported_travel_escalates_to_minister():
    """Verify out-of-scope requests (travel/gym) escalate to Bộ trưởng vnverse."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={"message": "Đặt cho tôi vé máy bay đi Đà Nẵng", "locale": "vi"},
        )
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] in (AssistantIntent.RECOMMEND_AGENT, AssistantIntent.OTHER)
        assert "Bộ trưởng vnverse" in data["reply"]
        assert "nhân tài nước ngoài" in data["reply"]


@pytest.mark.asyncio
async def test_assistant_chat_thay_cung_unsupported_travel_escalates_to_foreign_talent():
    """Verify Thầy Cúng informs user of missing skill and reports to minister for foreign talent."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={
                "message": "Đặt cho tôi vé máy bay đi Đà Nẵng",
                "agent_id": "thay_cung",
                "locale": "vi",
            },
        )
        assert res.status_code == 200
        data = res.json()
        assert data["agent_id"] == "thay_cung"
        assert data["recommend_agent_id"] is None
        assert "Bộ trưởng" in data["reply"]
        assert "nhân tài nước ngoài" in data["reply"]


@pytest.mark.asyncio
async def test_assistant_chat_thay_cung_tet_doan_ngo_answers_cultural_holiday():
    """Verify Thầy Cúng accurately answers Tet Doan Ngo query with details instead of opening greeting."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={
                "message": "Tết Đoan Ngọ là ngày nào?",
                "agent_id": "thay_cung",
                "locale": "vi",
            },
        )
        assert res.status_code == 200
        data = res.json()
        assert data["agent_id"] == "thay_cung"
        assert "Mùng 5 tháng 5 Âm lịch" in data["reply"]
        assert "diệt sâu bọ" in data["reply"]
        assert "cơm rượu nếp" in data["reply"]
        assert "vietnamese_traditional_holidays" in data["reply"]
        assert "Kính chào Giám đốc! Em là Thầy Cúng của công ty vnverse. Em chuyên lo chuyện lễ nghi" not in data["reply"]


@pytest.mark.asyncio
async def test_coordinator_intent_recommend_agent_market_overview():
    """Verify Coordinator returns market overview when asked about available staff or recruitment market."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={"message": "Giới thiệu các nhân sự hiện có trên Chợ tuyển dụng", "locale": "vi"},
        )
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] == AssistantIntent.RECOMMEND_AGENT
        assert data["action_type"] == "recommend_agent"
        assert "Chợ tuyển dụng" in data["reply"]
        assert "Thầy Cúng" in data["reply"]
        assert "Kế toán" in data["reply"]


@pytest.mark.asyncio
async def test_coordinator_intent_chitchat():
    """Verify Coordinator handles chitchat and greeting with assistant persona."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={"message": "Xin chào em trợ lý, hôm nay em thế nào?", "locale": "vi"},
        )
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] in (AssistantIntent.CHITCHAT, AssistantIntent.OTHER)
        assert data["action_type"] in ("chitchat", "unsupported")
        assert len(data["reply"]) > 10


@pytest.mark.asyncio
async def test_coordinator_intent_out_of_scope_politics_and_ethics():
    """Verify Coordinator politely rejects political and ethical topics."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Political query
        res = await ac.post(
            "/api/v1/assistant/chat",
            json={"message": "Quan điểm của bạn về chính trị và bầu cử nhà nước thế nào?", "locale": "vi"},
        )
        assert res.status_code == 200
        data = res.json()
        assert data["intent"] in (AssistantIntent.OUT_OF_SCOPE, AssistantIntent.OTHER)
        assert data["action_type"] == "unsupported"
        assert "chính trị, đạo đức" in data["reply"] or "từ chối" in data["reply"]
