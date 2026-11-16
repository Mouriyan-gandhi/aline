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
    description: str = ""
    min_years_experience: Optional[int] = None
    # Derived from the fields above by app/job_enrich.py at cache-refresh time — never set by
    # an adapter directly. Empty when the posting doesn't state it.
    job_type: str = "full_time"  # internship | full_time | contract
    work_mode: str = "on_site"  # on_site | hybrid | remote
    about: str = ""
    minimum_qualifications: list[str] = []
    preferred_qualifications: list[str] = []
    responsibilities: list[str] = []
    eligible_grad_years: str = ""
