from typing import Any, Optional

from pydantic import BaseModel, Field


class ExperienceEntry(BaseModel):
    id: Optional[str] = None  # the app's stable id for editing an entry in place
    title: str = ""
    organization: str = ""
    location: str = ""
    date_range: str = ""
    bullets: list[str] = []


class ProjectEntry(BaseModel):
    id: Optional[str] = None
    name: str = ""
    tech_stack: str = ""
    date_range: str = ""
    bullets: list[str] = []


class Achievement(BaseModel):
    id: str
    title: str = ""
    issuer: str = ""
    category: str = "Other"
    date_earned: str = ""
    description: str = ""
    credential_url: Optional[str] = None
    attachment_name: Optional[str] = None


class ProfileData(BaseModel):
    username: str  # the Community anonymous handle — echoed for convenience, never editable here
    avatar: Optional[str] = None
    name: Optional[str] = None
    education: Optional[str] = None
    institution: Optional[str] = None
    specialization: Optional[str] = None
    graduation_year: Optional[int] = None
    career_stage: Optional[str] = None
    linkedin: Optional[str] = None
    github: Optional[str] = None
    portfolio: Optional[str] = None
    skills: list[str] = []
    experience: list[ExperienceEntry] = []
    projects: list[ProjectEntry] = []
    headline: Optional[str] = None
    location: Optional[str] = None
    bio: Optional[str] = None
    achievements: list[Achievement] = []
    # Career preferences as the app models them (roles, companies, locations, job types, work
    # arrangements, experience level, alerts) — stored as-is, the app owns the shape.
    preferences: Optional[dict[str, Any]] = None


class ProfileUpdateRequest(BaseModel):
    device_id: str = Field(min_length=1)
    name: Optional[str] = None
    education: Optional[str] = None
    institution: Optional[str] = None
    specialization: Optional[str] = None
    graduation_year: Optional[int] = None
    career_stage: Optional[str] = None
    linkedin: Optional[str] = None
    github: Optional[str] = None
    portfolio: Optional[str] = None
    skills: Optional[list[str]] = None
    experience: Optional[list[ExperienceEntry]] = None
    projects: Optional[list[ProjectEntry]] = None
    headline: Optional[str] = None
    location: Optional[str] = None
    bio: Optional[str] = None
    achievements: Optional[list[Achievement]] = None
    preferences: Optional[dict[str, Any]] = None
