"""
Profile API — the real identity fields (name, education, links, skills, experience,
projects), distinct from Community's anonymous username even though both live on the same
device-scoped users row (see community_db.py's module docstring). Same device_id-based
pseudo-identity, same limitations.
"""
import json

from fastapi import APIRouter

from app.community_db import PROFILE_FIELDS, delete_account, get_or_create_user, update_profile
from app.profile_schemas import ExperienceEntry, ProfileData, ProfileUpdateRequest, ProjectEntry

router = APIRouter(prefix="/profile", tags=["profile"])

# These three columns hold JSON-encoded TEXT in the DB (see community_db.py's migration
# comment) — everything else on the users row is a plain scalar column.
JSON_FIELDS = {"skills", "experience", "projects"}


def _row_to_profile(row) -> ProfileData:
    scalar_fields = {f: row[f] for f in PROFILE_FIELDS if f not in JSON_FIELDS}
    skills = json.loads(row["skills"]) if row["skills"] else []
    experience = [ExperienceEntry(**e) for e in json.loads(row["experience"])] if row["experience"] else []
    projects = [ProjectEntry(**p) for p in json.loads(row["projects"])] if row["projects"] else []
    return ProfileData(username=row["username"], skills=skills, experience=experience, projects=projects, **scalar_fields)


@router.get("", response_model=ProfileData)
async def get_profile(device_id: str) -> ProfileData:
    user = get_or_create_user(device_id)
    return _row_to_profile(user)


@router.put("", response_model=ProfileData)
async def put_profile(request: ProfileUpdateRequest) -> ProfileData:
    fields = request.model_dump(exclude={"device_id"}, exclude_unset=True)
    for key in JSON_FIELDS:
        if key in fields:
            fields[key] = json.dumps(fields[key])
    row = update_profile(request.device_id, fields)
    return _row_to_profile(row)


@router.delete("")
async def delete_profile(device_id: str) -> dict:
    """Full account deletion — forgets the identity row and everything tied to it (community
    posts/comments/likes/saves/follows, see community_db.delete_account's cascade). No
    confirmation step here; the client (Account & Privacy's delete flow) owns that UX."""
    delete_account(device_id)
    return {"deleted": True}
