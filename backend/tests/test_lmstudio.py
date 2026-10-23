from unittest.mock import AsyncMock, patch

import httpx
import pytest

from app.llm.base import (
    LLMTimeoutError,
    LLMValidationError,
)
from app.llm.lmstudio import LMStudioProvider


@pytest.mark.asyncio
async def test_lmstudio_health_check_success():
    provider = LMStudioProvider(base_url="http://localhost:1234/v1")
    with patch("httpx.AsyncClient.get", new_callable=AsyncMock) as mock_get:
        mock_get.return_value = httpx.Response(200, json={"data": []})
        is_healthy = await provider.health_check()
        assert is_healthy is True


@pytest.mark.asyncio
async def test_lmstudio_health_check_failure():
    provider = LMStudioProvider(base_url="http://localhost:1234/v1")
    with patch("httpx.AsyncClient.get", new_callable=AsyncMock) as mock_get:
        mock_get.side_effect = Exception("Connection refused")
        is_healthy = await provider.health_check()
        assert is_healthy is False


@pytest.mark.asyncio
async def test_lmstudio_parse_rule_intent_success_with_markdown_strip():
    provider = LMStudioProvider(
        base_url="http://localhost:1234/v1",
        model="qwen/qwen3-4b-2507",
    )
    mock_payload = {
        "choices": [
            {
                "message": {
                    "content": '```json\n{"conditions": {"from_contains": "test@domain.com"}, "actions": [{"action_type": "add_label", "target": "Test"}], "confidence": 0.95}\n```'
                }
            }
        ]
    }
    with patch("httpx.AsyncClient.post", new_callable=AsyncMock) as mock_post:
        mock_post.return_value = httpx.Response(200, json=mock_payload)
        res = await provider.parse_rule_intent("Tag emails from test@domain.com as Test")
        assert res["conditions"]["from_contains"] == "test@domain.com"
        assert res["actions"][0]["target"] == "Test"
        assert res["confidence"] == 0.95


@pytest.mark.asyncio
async def test_lmstudio_timeout_error():
    provider = LMStudioProvider(timeout=1.0)
    with patch("httpx.AsyncClient.post", new_callable=AsyncMock) as mock_post:
        mock_post.side_effect = httpx.TimeoutException("Timeout")
        with pytest.raises(LLMTimeoutError):
            await provider.parse_rule_intent("Some natural language rule")


@pytest.mark.asyncio
async def test_lmstudio_invalid_json():
    provider = LMStudioProvider()
    mock_payload = {
        "choices": [
            {
                "message": {
                    "content": "Not valid JSON at all"
                }
            }
        ]
    }
    with patch("httpx.AsyncClient.post", new_callable=AsyncMock) as mock_post:
        mock_post.return_value = httpx.Response(200, json=mock_payload)
        with pytest.raises(LLMValidationError):
            await provider.parse_rule_intent("Some natural language rule")
