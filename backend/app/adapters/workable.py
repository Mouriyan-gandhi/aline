"""
Workable's public widget API — keyless, documented, genuinely public. Field names below are
best-effort from Workable's public widget schema; verified/adjusted against a real company
with live postings once the slug_prober found one (see companies_resolved.json).
"""
import httpx

from app.adapters.common import HTTP_TIMEOUT, USER_AGENT, normalize_location
from app.schemas import Job
from app.filters import is_relevant_job, is_india_location, is_senior_excluded, extract_skills


async def scrape(company: dict, client: httpx.AsyncClient) -> list[Job]:
    url = f"https://apply.workable.com/api/v1/widget/accounts/{company['slug']}"
    resp = await client.get(url, timeout=HTTP_TIMEOUT, headers={"User-Agent": USER_AGENT})
    resp.raise_for_status()
    postings = resp.json().get("jobs", [])

    results: list[Job] = []
    for post in postings:
        title = (post.get("title") or "").strip()
        department = post.get("department") or ""
        if not is_relevant_job(title, department):
            continue

        location_parts = [post.get("city"), post.get("state"), post.get("country")]
        location = normalize_location(", ".join(filter(None, location_parts)))
        if not is_india_location(location):
            continue

        if is_senior_excluded(title, ""):
            continue

        shortcode = post.get("shortcode") or post.get("code") or ""
        apply_url = post.get("url") or post.get("application_url") or f"https://apply.workable.com/{company['slug']}/j/{shortcode}"

        results.append(Job(
            id=f"workable_{company['slug']}_{shortcode or title}",
            company=company["name"],
            platform="workable",
            title=title,
            department=department,
            location=location,
            apply_url=apply_url,
            posted_at=post.get("published_on"),
            extracted_skills=extract_skills(title),
        ))
    return results
