"""
SmartRecruiters public Posting API — officially documented, genuinely public, free.
NOTE: this endpoint returns HTTP 200 with an empty body for ANY company identifier, even
nonexistent ones (confirmed live) — it never 404s. The registry only includes slugs the
slug_prober confirmed had `totalFound > 0` at probe time, but a company's postings can still
legitimately drop to zero between probes; that's expected, not a bug.

Found live (2026-10-09): the list endpoint paginates at 100 results per page (`totalFound`
vs. `content` length), and this adapter only ever fetched page one. For Swiggy specifically
— 175 total postings — every one of its real India tech roles (Software Development
Engineer, Data Scientist, Product Manager) sat in the second page; the Sales/Warehouse/
Copywriter postings that happened to occupy the first 100 slots were all this adapter ever
saw. Now paginates until `totalFound` is exhausted.
"""
import httpx

from app.adapters.common import HTTP_TIMEOUT, USER_AGENT, html_to_text, normalize_location
from app.schemas import Job
from app.filters import is_relevant_job, is_india_location, is_senior_excluded, extract_skills, extract_min_years_experience


async def _fetch_description(client: httpx.AsyncClient, slug: str, post_id: str) -> str:
    """The postings-LIST endpoint (used above) carries no description text at all — only
    the per-posting detail endpoint does, under jobAd.sections.*.text (companyDescription,
    jobDescription, qualifications, additionalInformation — confirmed live). One extra
    request per posting that's already passed title/location filtering, not per posting
    overall, so this stays cheap at this platform's current job volume."""
    try:
        resp = await client.get(
            f"https://api.smartrecruiters.com/v1/companies/{slug}/postings/{post_id}",
            timeout=HTTP_TIMEOUT, headers={"User-Agent": USER_AGENT},
        )
        resp.raise_for_status()
        sections = (resp.json().get("jobAd") or {}).get("sections") or {}
        parts = [
            sections[key]["text"]
            for key in ("jobDescription", "qualifications", "additionalInformation")
            if sections.get(key, {}).get("text")
        ]
        return html_to_text(" ".join(parts))
    except (httpx.HTTPError, ValueError, KeyError):
        return ""


PAGE_SIZE = 100
MAX_POSTINGS = 1000  # safety cap, not a real limit — generous headroom above any real company's count


async def _fetch_all_postings(client: httpx.AsyncClient, slug: str) -> list[dict]:
    url = f"https://api.smartrecruiters.com/v1/companies/{slug}/postings"
    all_postings: list[dict] = []
    for offset in range(0, MAX_POSTINGS, PAGE_SIZE):
        resp = await client.get(
            url, params={"offset": offset, "limit": PAGE_SIZE},
            timeout=HTTP_TIMEOUT, headers={"User-Agent": USER_AGENT},
        )
        resp.raise_for_status()
        data = resp.json()
        page = data.get("content", [])
        all_postings.extend(page)
        if len(page) < PAGE_SIZE or offset + PAGE_SIZE >= data.get("totalFound", 0):
            break
    return all_postings


async def scrape(company: dict, client: httpx.AsyncClient) -> list[Job]:
    postings = await _fetch_all_postings(client, company["slug"])

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
        description = await _fetch_description(client, company["slug"], post_id)
        # Re-check with the real description now in hand — the title-only check above is a
        # cheap pre-filter, but a years-of-experience requirement almost always lives in the
        # body text, not the title, so this catches senior postings the pre-filter couldn't.
        if is_senior_excluded(title, description):
            continue

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
            extracted_skills=extract_skills(f"{title} {description}"),
            description=description,
            min_years_experience=extract_min_years_experience(description),
        ))
    return results
