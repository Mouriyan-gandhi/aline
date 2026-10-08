"""
Ashby public job-board API. Ported from old_version/scraper/scraper.js's intent, but the
old code's field names (jobPostings/locationName/descriptionPlain/publishedDate) turned out
to be stale against the real current API, caught by testing against live companies during
Milestone 0 build: the real top-level key is `jobs`, and fields are `location` (plain string),
`jobUrl`, `descriptionHtml`, `publishedAt`.
"""
import httpx

from app.adapters.common import HTTP_TIMEOUT, USER_AGENT, normalize_location
from app.schemas import Job
from app.filters import is_relevant_job, is_india_location, is_senior_excluded, extract_skills


async def scrape(company: dict, client: httpx.AsyncClient) -> list[Job]:
    url = f"https://api.ashbyhq.com/posting-api/job-board/{company['slug']}"
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

        description = post.get("descriptionHtml") or ""
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
        ))
    return results
