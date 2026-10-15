"""
Community API — discussions (posts), comments, likes, bookmarks, followed companies, and
device-scoped anonymous identity. See community_db.py's module docstring for the identity
model and why it's device_id-based rather than real auth. Sync endpoints (sqlite3 is sync);
FastAPI runs sync def endpoints in a threadpool automatically, so this doesn't block the event
loop that the jobs-scraping side depends on.
"""
import json
from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from app.community_db import (
    CATEGORIES,
    TOPICS,
    add_comment,
    create_discussion,
    get_discussion,
    get_or_create_user,
    list_discussions,
    list_followed_companies,
    list_saved_post_ids,
    toggle_followed_company,
    toggle_like,
    toggle_saved_post,
)
from app.community_schemas import (
    Comment,
    CreateCommentRequest,
    CreateDiscussionRequest,
    Discussion,
    DiscussionDetail,
    FollowedResponse,
    IdentityRequest,
    LikeResponse,
    SavedResponse,
    UserIdentity,
)

router = APIRouter(prefix="/community", tags=["community"])


def _row_to_discussion(row: dict) -> Discussion:
    return Discussion(
        id=row["id"], user_id=row["user_id"], username=row["username"], role_title=row["role_title"],
        category=row["category"], company=row["company"], title=row["title"], body=row["body"],
        created_at=row["created_at"], likes_count=row["likes_count"], comments_count=row["comments_count"],
        liked_by_me=bool(row["liked_by_me"]), saved_by_me=bool(row["saved_by_me"]),
        topics=json.loads(row["topics"]) if row["topics"] else [],
    )


@router.get("/categories")
async def categories() -> list[str]:
    return CATEGORIES


@router.get("/topics")
async def topics() -> list[str]:
    return TOPICS


@router.post("/identity", response_model=UserIdentity)
async def identity(request: IdentityRequest) -> UserIdentity:
    """
    The only way a username is ever created or retrieved — the client never chooses or sends
    one. Idempotent: calling this again with the same device_id returns the same username,
    never a new one (see get_or_create_user's lookup-before-insert).
    """
    user = get_or_create_user(request.device_id, request.role_title)
    return UserIdentity(id=user["id"], username=user["username"], role_title=user["role_title"])


@router.get("/discussions", response_model=list[Discussion])
async def get_discussions(
    category: Optional[str] = None,
    sort: str = "newest",
    device_id: Optional[str] = None,
    companies: Optional[list[str]] = Query(None),
    topics: Optional[list[str]] = Query(None),
    only_saved: bool = False,
) -> list[Discussion]:
    if category and category not in CATEGORIES:
        raise HTTPException(400, f"Unknown category. Must be one of: {CATEGORIES}")
    viewer = get_or_create_user(device_id) if device_id else None
    rows = list_discussions(
        category, sort, viewer["id"] if viewer else None,
        companies=companies, only_saved=only_saved, topics=topics,
    )
    return [_row_to_discussion(r) for r in rows]


@router.post("/discussions", response_model=Discussion)
async def post_discussion(request: CreateDiscussionRequest) -> Discussion:
    if request.category not in CATEGORIES:
        raise HTTPException(400, f"Unknown category. Must be one of: {CATEGORIES}")
    user = get_or_create_user(request.device_id)
    discussion_id = create_discussion(
        user["id"], request.category, request.company, request.title, request.body, topics=request.topics
    )
    row = get_discussion(discussion_id, user["id"])
    return _row_to_discussion(row)


@router.get("/discussions/{discussion_id}", response_model=DiscussionDetail)
async def get_discussion_detail(discussion_id: str, device_id: Optional[str] = None) -> DiscussionDetail:
    viewer = get_or_create_user(device_id) if device_id else None
    data = get_discussion(discussion_id, viewer["id"] if viewer else None)
    if data is None:
        raise HTTPException(404, "Discussion not found")
    comments = [
        Comment(
            id=c["id"], discussion_id=c["discussion_id"], user_id=c["user_id"],
            username=c["username"], role_title=c["role_title"], body=c["body"], created_at=c["created_at"],
        )
        for c in data["comments"]
    ]
    return DiscussionDetail(**_row_to_discussion(data).model_dump(), comments=comments)


@router.post("/discussions/{discussion_id}/comments", response_model=Comment)
async def post_comment(discussion_id: str, request: CreateCommentRequest) -> Comment:
    user = get_or_create_user(request.device_id)
    row = add_comment(discussion_id, user["id"], request.body)
    if row is None:
        raise HTTPException(404, "Discussion not found")
    return Comment(
        id=row["id"], discussion_id=row["discussion_id"], user_id=row["user_id"],
        username=row["username"], role_title=row["role_title"], body=row["body"], created_at=row["created_at"],
    )


@router.post("/discussions/{discussion_id}/like", response_model=LikeResponse)
async def like_discussion(discussion_id: str, device_id: str) -> LikeResponse:
    user = get_or_create_user(device_id)
    liked = toggle_like(discussion_id, user["id"])
    if liked is None:
        raise HTTPException(404, "Discussion not found")
    return LikeResponse(liked=liked)


@router.post("/discussions/{discussion_id}/save", response_model=SavedResponse)
async def save_discussion(discussion_id: str, device_id: str) -> SavedResponse:
    saved = toggle_saved_post(device_id, discussion_id)
    if saved is None:
        raise HTTPException(404, "Discussion not found")
    return SavedResponse(saved=saved)


@router.get("/saved", response_model=list[str])
async def get_saved_discussion_ids(device_id: str) -> list[str]:
    return list_saved_post_ids(device_id)


@router.get("/following", response_model=list[str])
async def get_followed_companies(device_id: str) -> list[str]:
    return list_followed_companies(device_id)


@router.post("/following/{company}", response_model=FollowedResponse)
async def follow_company(company: str, device_id: str) -> FollowedResponse:
    following = toggle_followed_company(device_id, company)
    return FollowedResponse(following=following)
