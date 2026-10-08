"""Ported from old_version/scraper/scraper.js (scrapeGreenhouse)."""
import httpx

from app.adapters.common import HTTP_TIMEOUT, USER_AGENT, normalize_location
from app.schemas import Job
from app.filters import is_relevant_job, is_india_location, is_senior_excluded, extract_skills


async def scrape(company: dict, client: httpx.AsyncClient) -> list[Job]:
    url = f"https://boards-api.greenhouse.io/v1/boards/{company['slug']}/jobs?content=true"
    resp = await client.get(url, timeout=HTTP_TIMEOUT, headers={"User-Agent": USER_AGENT})
    resp.raise_for_status()
    jobs_raw = resp.json().get("jobs", [])

    results: list[Job] = []
    for job in jobs_raw:
        title = job.get("title", "")
        department = ", ".join(d["name"] for d in job.get("departments", []) if d.get("name"))
        if not is_relevant_job(title, department):
            continue

        location = normalize_location([o["name"] for o in job.get("offices", []) if o.get("name")])
        if not is_india_location(location):
            continue

        description = job.get("content", "") or ""
        if is_senior_excluded(title, description):
            continue

        results.append(Job(
            id=f"greenhouse_{company['slug']}_{job['id']}",
            company=company["name"],
            platform="greenhouse",
            title=title.strip(),
            department=department,
            location=location,
            apply_url=job.get("absolute_url") or f"https://boards.greenhouse.io/{company['slug']}",
            posted_at=job.get("updated_at"),
            extracted_skills=extract_skills(f"{title} {description}"),
        ))
    return results
