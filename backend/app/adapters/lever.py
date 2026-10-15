"""Ported from old_version/scraper/scraper.js (scrapeLever)."""
from datetime import datetime, timezone

import httpx

from app.adapters.common import HTTP_TIMEOUT, USER_AGENT, html_to_text, normalize_location
from app.schemas import Job
from app.filters import is_relevant_job, is_india_location, is_senior_excluded, extract_skills, extract_min_years_experience


async def scrape(company: dict, client: httpx.AsyncClient) -> list[Job]:
    url = f"https://api.lever.co/v0/postings/{company['slug']}?mode=json"
    resp = await client.get(url, timeout=HTTP_TIMEOUT, headers={"User-Agent": USER_AGENT})
    resp.raise_for_status()
    postings = resp.json()
    if not isinstance(postings, list):
        postings = []

    results: list[Job] = []
    for post in postings:
        title = post.get("text", "")
        categories = post.get("categories", {}) or {}
        department = categories.get("team") or categories.get("department") or ""
        if not is_relevant_job(title, department):
            continue

        location = normalize_location(categories.get("location") or post.get("workplaceType"))
        if not is_india_location(location):
            continue

        # descriptionPlain is already plain text when present; description (the fallback)
        # is real HTML — same risk as Greenhouse/Ashby, see html_to_text's docstring.
        description = post.get("descriptionPlain") or html_to_text(post.get("description") or "")
        if is_senior_excluded(title, description):
            continue

        results.append(Job(
            id=f"lever_{company['slug']}_{post['id']}",
            company=company["name"],
            platform="lever",
            title=title.strip(),
            department=department,
            location=location,
            apply_url=post.get("hostedUrl") or f"https://jobs.lever.co/{company['slug']}",
            # Lever's createdAt is epoch milliseconds, not a date string — every other
            # adapter (Greenhouse/Ashby/SmartRecruiters/Workday) already hands the iOS client
            # an ISO8601 string, so convert here rather than leaning on the client to guess
            # which platform sent a raw timestamp. Was previously `str(createdAt)`, which
            # shipped a literal "1788425813778" to the freshness badge.
            posted_at=(
                datetime.fromtimestamp(post["createdAt"] / 1000, tz=timezone.utc).isoformat()
                if post.get("createdAt") else None
            ),
            extracted_skills=extract_skills(f"{title} {description}"),
            description=description,
            min_years_experience=extract_min_years_experience(description),
        ))
    return results
