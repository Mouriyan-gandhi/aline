"""
Ashby public job-board API. Ported from old_version/scraper/scraper.js's intent, but the
old code's field names (jobPostings/locationName/descriptionPlain/publishedDate) turned out
to be stale against the real current API, caught by testing against live companies during
Milestone 0 build: the real top-level key is `jobs`, and fields are `location` (plain string),
`jobUrl`, `descriptionHtml`, `publishedAt`.
"""
import httpx

from app.adapters.common import HTTP_TIMEOUT, USER_AGENT, html_to_text, normalize_location
from app.schemas import Job
from app.filters import is_relevant_job, is_india_location, is_senior_excluded, extract_skills, extract_min_years_experience


def _salary(compensation) -> str:
    """Only what the company chose to publish on the posting."""
    if not isinstance(compensation, dict) or compensation.get("shouldDisplayCompensationOnJobPostings") is False:
        return ""
    return compensation.get("scrapeableCompensationSalarySummary") or compensation.get("compensationTierSummary") or ""


async def scrape(company: dict, client: httpx.AsyncClient) -> list[Job]:
    url = f"https://api.ashbyhq.com/posting-api/job-board/{company['slug']}?includeCompensation=true"
    resp = await client.get(url, timeout=HTTP_TIMEOUT, headers={"User-Agent": USER_AGENT})
    resp.raise_for_status()
    postings = resp.json().get("jobs", [])

    results: list[Job] = []
    for post in postings:
        title = post.get("title", "")
        department = post.get("department") or post.get("team") or ""
        if not is_relevant_job(title, department):
            continue

        location = normalize_location(post.get("location"))
        if not is_india_location(location):
            continue

        description = html_to_text(post.get("descriptionHtml") or "")
        if is_senior_excluded(title, description):
            continue

        results.append(Job(
            id=f"ashby_{company['slug']}_{post['id']}",
            company=company["name"],
            platform="ashby",
            title=title.strip(),
            department=department,
            location=location,
            apply_url=post.get("jobUrl") or f"https://jobs.ashbyhq.com/{company['slug']}",
            posted_at=post.get("publishedAt"),
            extracted_skills=extract_skills(f"{title} {description}"),
            description=description,
            min_years_experience=extract_min_years_experience(description),
            employment_type=post.get("employmentType") or "",
            workplace_type=post.get("workplaceType") or ("Remote" if post.get("isRemote") else ""),
            salary=_salary(post.get("compensation")),
        ))
    return results
