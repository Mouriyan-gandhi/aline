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
    company_stats,
    delete_comment,
    increment_share,
    list_notifications,
    toggle_comment_like,
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
    CompanyCommunity,
    CreateCommentRequest,
    CreateDiscussionRequest,
    Discussion,
    DiscussionDetail,
    FollowedResponse,
    IdentityRequest,
    LikeResponse,
    NotificationItem,
    SavedResponse,
    ShareResponse,
    UserIdentity,
)

router = APIRouter(prefix="/community", tags=["community"])


def _row_to_discussion(row: dict, viewer_id: Optional[str] = None) -> Discussion:
    return Discussion(
        id=row["id"], user_id=row["user_id"], username=row["username"], role_title=row["role_title"],
        avatar=row.get("avatar"),
        category=row["category"], company=row["company"], title=row["title"], body=row["body"],
        created_at=row["created_at"], likes_count=row["likes_count"], comments_count=row["comments_count"],
        liked_by_me=bool(row["liked_by_me"]), saved_by_me=bool(row["saved_by_me"]),
        topics=json.loads(row["topics"]) if row["topics"] else [],
        shares_count=row.get("shares_count") or 0,
        is_mine=viewer_id is not None and row["user_id"] == viewer_id,
    )


def _row_to_comment(c, viewer_id: Optional[str] = None) -> Comment:
    c = dict(c)
    return Comment(
        id=c["id"], discussion_id=c["discussion_id"], user_id=c["user_id"],
        username=c["username"], role_title=c["role_title"], avatar=c.get("avatar"),
        body=c["body"], created_at=c["created_at"], parent_id=c.get("parent_id"),
        likes_count=c.get("likes_count") or 0, liked_by_me=bool(c.get("liked_by_me")),
        is_mine=viewer_id is not None and c["user_id"] == viewer_id,
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
    return UserIdentity(id=user["id"], username=user["username"], role_title=user["role_title"], avatar=user["avatar"])


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
    return [_row_to_discussion(r, viewer["id"] if viewer else None) for r in rows]


@router.post("/discussions", response_model=Discussion)
async def post_discussion(request: CreateDiscussionRequest) -> Discussion:
    if request.category not in CATEGORIES:
        raise HTTPException(400, f"Unknown category. Must be one of: {CATEGORIES}")
    user = get_or_create_user(request.device_id)
    discussion_id = create_discussion(
        user["id"], request.category, request.company, request.title, request.body, topics=request.topics
    )
    row = get_discussion(discussion_id, user["id"])
    return _row_to_discussion(row, user["id"])


@router.get("/discussions/{discussion_id}", response_model=DiscussionDetail)
async def get_discussion_detail(discussion_id: str, device_id: Optional[str] = None) -> DiscussionDetail:
    viewer = get_or_create_user(device_id) if device_id else None
    data = get_discussion(discussion_id, viewer["id"] if viewer else None)
    if data is None:
        raise HTTPException(404, "Discussion not found")
    viewer_id = viewer["id"] if viewer else None
    comments = [_row_to_comment(c, viewer_id) for c in data["comments"]]
    return DiscussionDetail(**_row_to_discussion(data, viewer_id).model_dump(), comments=comments)


@router.post("/discussions/{discussion_id}/comments", response_model=Comment)
async def post_comment(discussion_id: str, request: CreateCommentRequest) -> Comment:
    user = get_or_create_user(request.device_id)
    row = add_comment(discussion_id, user["id"], request.body, request.parent_id)
    if row is None:
        raise HTTPException(404, "Discussion or parent comment not found")
    return _row_to_comment(row, user["id"])


@router.delete("/comments/{comment_id}")
async def remove_comment(comment_id: str, device_id: str) -> dict:
    user = get_or_create_user(device_id)
    result = delete_comment(comment_id, user["id"])
    if result is None:
        raise HTTPException(404, "Comment not found")
    if result is False:
        raise HTTPException(403, "Only the author can delete a comment")
    return {"deleted": True}


@router.post("/comments/{comment_id}/like", response_model=LikeResponse)
async def like_comment(comment_id: str, device_id: str) -> LikeResponse:
    user = get_or_create_user(device_id)
    liked = toggle_comment_like(comment_id, user["id"])
    if liked is None:
        raise HTTPException(404, "Comment not found")
    return LikeResponse(liked=liked)


@router.post("/discussions/{discussion_id}/share", response_model=ShareResponse)
async def share_discussion(discussion_id: str) -> ShareResponse:
    count = increment_share(discussion_id)
    if count is None:
        raise HTTPException(404, "Discussion not found")
    return ShareResponse(shares_count=count)


@router.get("/companies", response_model=list[CompanyCommunity])
async def get_companies(device_id: Optional[str] = None) -> list[CompanyCommunity]:
    """Every company in the job-source registry plus any company someone posted about or
    follows — so a company community exists for each employer the feed shows, with real
    follower/post counts (zero is a real number, not a placeholder)."""
    from app.companies import COMPANIES  # local import: companies.py is large and jobs-side

    stats = company_stats()
    followed = set(list_followed_companies(device_id)) if device_id else set()
    names = {c["name"] for c in COMPANIES} | set(stats) | followed
    result = [
        CompanyCommunity(
            name=name,
            followers_count=stats.get(name, {}).get("followers", 0),
            posts_count=stats.get(name, {}).get("posts", 0),
            following=name in followed,
        )
        for name in names
    ]
    result.sort(key=lambda c: (-c.posts_count, -c.followers_count, c.name.lower()))
    return result


@router.get("/notifications", response_model=list[NotificationItem])
async def get_notifications(device_id: str) -> list[NotificationItem]:
    user = get_or_create_user(device_id)
    return [NotificationItem(**row) for row in list_notifications(user["id"])]


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
