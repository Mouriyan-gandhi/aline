"""
SmartRecruiters public Posting API — officially documented, genuinely public, free.
NOTE: this endpoint returns HTTP 200 with an empty body for ANY company identifier, even
nonexistent ones (confirmed live) — it never 404s. The registry only includes slugs the
slug_prober confirmed had `totalFound > 0` at probe time, but a company's postings can still
legitimately drop to zero between probes; that's expected, not a bug.
"""
import httpx

from app.adapters.common import HTTP_TIMEOUT, USER_AGENT, normalize_location
from app.schemas import Job
from app.filters import is_relevant_job, is_india_location, is_senior_excluded, extract_skills


async def scrape(company: dict, client: httpx.AsyncClient) -> list[Job]:
    url = f"https://api.smartrecruiters.com/v1/companies/{company['slug']}/postings"
    resp = await client.get(url, timeout=HTTP_TIMEOUT, headers={"User-Agent": USER_AGENT})
    resp.raise_for_status()
    postings = resp.json().get("content", [])

    results: list[Job] = []
    for post in postings:
        # Defense-in-depth against slug collisions: the posting's own company identifier
        # should match what we asked for.
        identifier = (post.get("company") or {}).get("identifier", "")
        if identifier and identifier.lower() != company["slug"].lower():
            continue

        title = (post.get("name") or "").strip()
        department = (post.get("department") or {}).get("label", "")
        if not is_relevant_job(title, department):
            continue

        loc = post.get("location") or {}
        location = normalize_location(
            ", ".join(filter(None, [loc.get("city"), loc.get("region"), loc.get("country")]))
        )
        if not is_india_location(location):
            continue

        if is_senior_excluded(title, ""):
            continue

        post_id = post.get("id", "")
        # NOTE: the postings-list response has no human-facing URL field — only "ref",
        # which is a raw API self-link (https://api.smartrecruiters.com/...), confirmed by
        # inspecting a real response. The actual public careers page follows this pattern,
        # confirmed live (200, no redirect needed) against a real posting.
        apply_url = f"https://jobs.smartrecruiters.com/{company['slug']}/{post_id}"

        results.append(Job(
            id=f"smartrecruiters_{company['slug']}_{post_id}",
            company=company["name"],
            platform="smartrecruiters",
            title=title,
            department=department,
            location=location,
            apply_url=apply_url,
            posted_at=post.get("releasedDate"),
            extracted_skills=extract_skills(title),
        ))
    return results
