from typing import Optional

from pydantic import BaseModel, Field


class ExperienceEntry(BaseModel):
    title: str = ""
    organization: str = ""
    location: str = ""
    date_range: str = ""
    bullets: list[str] = []


class ProjectEntry(BaseModel):
    name: str = ""
    tech_stack: str = ""
    date_range: str = ""
    bullets: list[str] = []


class ProfileData(BaseModel):
    username: str  # the Community anonymous handle — echoed for convenience, never editable here
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
