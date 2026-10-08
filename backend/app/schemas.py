from typing import Optional

from pydantic import BaseModel


class Job(BaseModel):
    id: str
    company: str
    platform: str
    title: str
    department: str = ""
    location: str
    apply_url: str
    posted_at: Optional[str] = None
    extracted_skills: list[str] = []
