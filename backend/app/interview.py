"""
Interview Questions — the Community tab's Interview Prep section. Questions are contributed by
users (the Contribute sheet), filtered by company / role / topic, upvoted and saved. Same
device-scoped identity as Community (see community_db.py's module docstring).

There is deliberately no server-side answer generation: a question carries only the hint,
approach and answer its contributor wrote. The app's "AI solution" is generated on-device and
labeled as such, never stored here as if a person wrote it.
"""
from typing import Optional

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from app.community_db import (
    create_question,
    get_or_create_user,
    list_questions,
    toggle_question_save,
    toggle_question_upvote,
)

router = APIRouter(prefix="/interview", tags=["interview"])

# Must match the app's QuestionTopic raw values.
TOPICS = [
    "Array & DSA", "System Design", "Core CS", "Databases", "Networking",
    "Behavioral", "Operating Systems", "AI & ML",
]


class InterviewQuestion(BaseModel):
    id: str
    question: str
    topic: str
    company: Optional[str] = None
    role: Optional[str] = None
    difficulty: str = "General"
    hint: Optional[str] = None
    approach: Optional[str] = None
    answer: Optional[str] = None
    time_complexity: Optional[str] = None
    space_complexity: Optional[str] = None
    upvotes_count: int = 0
    upvoted_by_me: bool = False
    saved_by_me: bool = False
    is_mine: bool = False
    created_at: str


class CreateQuestionRequest(BaseModel):
    device_id: str = Field(min_length=1)
    question: str = Field(min_length=1, max_length=3000)
    topic: str
    company: Optional[str] = None
    role: Optional[str] = None
    difficulty: str = "General"
    hint: Optional[str] = Field(default=None, max_length=3000)
    approach: Optional[str] = Field(default=None, max_length=3000)
    answer: Optional[str] = Field(default=None, max_length=10000)
    time_complexity: Optional[str] = None
    space_complexity: Optional[str] = None


class UpvoteResponse(BaseModel):
    upvoted: bool


class SaveResponse(BaseModel):
    saved: bool


def _to_model(row: dict) -> InterviewQuestion:
    return InterviewQuestion(**{
        **row,
        "upvoted_by_me": bool(row["upvoted_by_me"]),
        "saved_by_me": bool(row["saved_by_me"]),
        "is_mine": bool(row["is_mine"]),
    })


def _blank_to_none(value: Optional[str]) -> Optional[str]:
    return value.strip() if value and value.strip() else None


@router.get("/topics")
async def topics() -> list[str]:
    return TOPICS


@router.get("/questions", response_model=list[InterviewQuestion])
async def get_questions(
    device_id: Optional[str] = None,
    companies: Optional[list[str]] = Query(None),
    roles: Optional[list[str]] = Query(None),
    topics: Optional[list[str]] = Query(None),
    only_saved: bool = False,
) -> list[InterviewQuestion]:
    viewer = get_or_create_user(device_id) if device_id else None
    rows = list_questions(viewer["id"] if viewer else None, companies, roles, topics, only_saved)
    return [_to_model(r) for r in rows]


@router.post("/questions", response_model=InterviewQuestion)
async def post_question(request: CreateQuestionRequest) -> InterviewQuestion:
    if request.topic not in TOPICS:
        raise HTTPException(400, f"Unknown topic. Must be one of: {TOPICS}")
    user = get_or_create_user(request.device_id)
    fields = request.model_dump(exclude={"device_id"})
    for key in ("company", "role", "hint", "approach", "answer", "time_complexity", "space_complexity"):
        fields[key] = _blank_to_none(fields.get(key))
    return _to_model(create_question(user["id"], fields))


@router.post("/questions/{question_id}/upvote", response_model=UpvoteResponse)
async def upvote_question(question_id: str, device_id: str) -> UpvoteResponse:
    user = get_or_create_user(device_id)
    upvoted = toggle_question_upvote(question_id, user["id"])
    if upvoted is None:
        raise HTTPException(404, "Question not found")
    return UpvoteResponse(upvoted=upvoted)


@router.post("/questions/{question_id}/save", response_model=SaveResponse)
async def save_question(question_id: str, device_id: str) -> SaveResponse:
    user = get_or_create_user(device_id)
    saved = toggle_question_save(question_id, user["id"])
    if saved is None:
        raise HTTPException(404, "Question not found")
    return SaveResponse(saved=saved)
