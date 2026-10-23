import json
import logging
import uuid
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, status

from app.schemas.reports import CreateReportRequest, ReportResponse

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Reports"])

# Reports storage file on server (inspected manually by admin)
BASE_DIR = Path(__file__).resolve().parent.parent.parent
REPORTS_DIR = BASE_DIR / "data"
REPORTS_FILE = REPORTS_DIR / "admin_reports.jsonl"


@router.post(
    "/reports",
    response_model=ReportResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit user feedback or unsupported intent report to admin",
)
async def submit_admin_report(request: CreateReportRequest) -> ReportResponse:
    """
    Persist user report to server-side JSONL file for manual review by admin.
    """
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)

    report_id = f"report_{uuid.uuid4().hex[:8]}"
    created_at = datetime.now(timezone.utc).isoformat()

    record = {
        "id": report_id,
        "created_at": created_at,
        "user_email": request.user_email or "anonymous",
        "user_input": request.user_input,
        "reason": request.reason or "unsupported_content",
        "user_notes": request.user_notes,
        "status": "pending_manual_review",
    }

    try:
        with open(REPORTS_FILE, "a", encoding="utf-8") as f:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")
        logger.info("Admin report persisted: id=%s file=%s", report_id, REPORTS_FILE)
    except Exception as exc:
        logger.error("Failed to append report to file: %s", exc)

    return ReportResponse(
        id=report_id,
        status="received",
        message="Khiếu nại đã được gửi tới admin thành công. Chúng tôi sẽ kiểm tra thủ công.",
        created_at=created_at,
    )
