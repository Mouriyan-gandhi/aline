"""
Help & feedback — the Figma "Feedback and problem form" screen needs somewhere real to send
what someone types, not a form that looks functional and silently discards input. Captured
into the same SQLite DB as everything else (see community_db.py), attributed to the same
device identity. No notification/triage pipeline exists yet (no email, no Slack webhook) —
this is intentionally just durable storage for now, read directly from the DB file until
there's an actual reason to build more.
"""
from fastapi import APIRouter

from app.community_db import create_feedback
from app.community_schemas import FeedbackRequest

router = APIRouter(prefix="/feedback", tags=["feedback"])


@router.post("")
async def post_feedback(request: FeedbackRequest) -> dict:
    feedback_id = create_feedback(request.device_id, request.category, request.message)
    return {"id": feedback_id}
