from typing import Optional

from pydantic import BaseModel, Field


class UserIdentity(BaseModel):
    id: str
    username: str
    role_title: Optional[str] = None
    avatar: Optional[str] = None


class IdentityRequest(BaseModel):
    device_id: str = Field(min_length=1)
    role_title: Optional[str] = None


class Comment(BaseModel):
    id: str
    discussion_id: str
    user_id: str
    username: str
    role_title: Optional[str] = None
    avatar: Optional[str] = None
    body: str
    created_at: str
    parent_id: Optional[str] = None  # set on replies — always a top-level comment's id
    likes_count: int = 0
    liked_by_me: bool = False
    is_mine: bool = False


class CreateCommentRequest(BaseModel):
    device_id: str = Field(min_length=1)
    body: str = Field(min_length=1, max_length=2000)
    parent_id: Optional[str] = None


class Discussion(BaseModel):
    id: str
    user_id: str
    username: str
    role_title: Optional[str] = None
    avatar: Optional[str] = None
    category: str
    company: Optional[str] = None
    title: str
    body: str
    created_at: str
    likes_count: int
    comments_count: int
    liked_by_me: bool = False
    saved_by_me: bool = False
    topics: list[str] = []
    shares_count: int = 0
    is_mine: bool = False


class DiscussionDetail(Discussion):
    comments: list[Comment] = []


class CreateDiscussionRequest(BaseModel):
    device_id: str = Field(min_length=1)
    category: str
    company: Optional[str] = None
    title: str = Field(min_length=1, max_length=200)
    body: str = Field(min_length=1, max_length=5000)
    topics: list[str] = []


class LikeResponse(BaseModel):
    liked: bool


class SavedResponse(BaseModel):
    saved: bool


class FollowedResponse(BaseModel):
    following: bool


class FeedbackRequest(BaseModel):
    device_id: str = Field(min_length=1)
    category: str
    message: str = Field(min_length=1, max_length=2000)


class ShareResponse(BaseModel):
    shares_count: int


class CompanyCommunity(BaseModel):
    name: str
    followers_count: int
    posts_count: int
    following: bool


class NotificationItem(BaseModel):
    id: str
    kind: str  # commented_on_post | replied_to_comment | liked_post | liked_comment | new_post
    actor: str
    actor_avatar: Optional[str] = None
    post_id: str
    snippet: str = ""
    created_at: str
