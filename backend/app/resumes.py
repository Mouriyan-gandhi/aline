"""
Resumes — the Resume tab's documents (master + tailored copies). The app owns the document
shape (sections, template, tailoring target), so each resume is stored as an opaque JSON
object per device identity; the server never interprets it.
"""
import json
from typing import Any

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.community_db import delete_resume, get_or_create_user, list_resumes, upsert_resume

router = APIRouter(prefix="/resumes", tags=["resumes"])

MAX_RESUME_BYTES = 512 * 1024


class StoredResume(BaseModel):
    id: str
    data: dict[str, Any]
    created_at: str
    updated_at: str


class SaveResumeRequest(BaseModel):
    device_id: str = Field(min_length=1)
    data: dict[str, Any]


def _to_model(row: dict) -> StoredResume:
    return StoredResume(id=row["id"], data=json.loads(row["data"]), created_at=row["created_at"], updated_at=row["updated_at"])


@router.get("", response_model=list[StoredResume])
async def get_resumes(device_id: str) -> list[StoredResume]:
    user = get_or_create_user(device_id)
    return [_to_model(r) for r in list_resumes(user["id"])]


@router.put("/{resume_id}", response_model=StoredResume)
async def put_resume(resume_id: str, request: SaveResumeRequest) -> StoredResume:
    encoded = json.dumps(request.data)
    if len(encoded.encode()) > MAX_RESUME_BYTES:
        raise HTTPException(413, "Resume document too large")
    user = get_or_create_user(request.device_id)
    return _to_model(upsert_resume(user["id"], resume_id, encoded))


@router.delete("/{resume_id}")
async def remove_resume(resume_id: str, device_id: str) -> dict:
    user = get_or_create_user(device_id)
    if not delete_resume(user["id"], resume_id):
        raise HTTPException(404, "Resume not found")
    return {"deleted": True}
