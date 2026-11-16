"""
Achievement attachments (certificate PDFs, images) — stored in the same SQLite DB as everything
else, per device identity, keyed by the achievement's id. JSON with base64 content rather than
multipart, so no extra dependency (python-multipart) is needed for one small upload path.
"""
import base64
import binascii

from fastapi import APIRouter, HTTPException, Response
from pydantic import BaseModel, Field

from app.community_db import delete_file, get_file, get_or_create_user, put_file

router = APIRouter(prefix="/files", tags=["files"])

MAX_FILE_BYTES = 8 * 1024 * 1024
ALLOWED_TYPES = {"application/pdf", "image/jpeg", "image/png", "image/heic", "image/heif", "image/gif", "image/webp"}


class UploadFileRequest(BaseModel):
    device_id: str = Field(min_length=1)
    filename: str = Field(min_length=1, max_length=255)
    content_type: str
    data_base64: str


@router.put("/{file_id}")
async def upload(file_id: str, request: UploadFileRequest) -> dict:
    if request.content_type not in ALLOWED_TYPES:
        raise HTTPException(415, f"Unsupported file type. Allowed: {sorted(ALLOWED_TYPES)}")
    try:
        data = base64.b64decode(request.data_base64, validate=True)
    except (binascii.Error, ValueError):
        raise HTTPException(400, "data_base64 is not valid base64")
    if len(data) > MAX_FILE_BYTES:
        raise HTTPException(413, "File is larger than 8 MB")
    user = get_or_create_user(request.device_id)
    put_file(user["id"], file_id, request.filename, request.content_type, data)
    return {"id": file_id, "filename": request.filename, "size": len(data)}


@router.get("/{file_id}")
async def download(file_id: str, device_id: str) -> Response:
    user = get_or_create_user(device_id)
    row = get_file(user["id"], file_id)
    if row is None:
        raise HTTPException(404, "File not found")
    return Response(
        content=row["data"], media_type=row["content_type"],
        headers={"Content-Disposition": f'inline; filename="{row["filename"]}"'},
    )


@router.delete("/{file_id}")
async def remove(file_id: str, device_id: str) -> dict:
    user = get_or_create_user(device_id)
    delete_file(user["id"], file_id)
    return {"deleted": True}
