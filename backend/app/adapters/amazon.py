"""
Amazon — one of the 5 "mega-cap" custom career platforms investigated 2026-10-08. Unlike
Google/Apple/Meta, Amazon's own search page calls a genuinely public, clean JSON API
(`amazon.jobs/en/search.json`) with no login wall and no robots.txt prohibition — confirmed
live before building this. This is the real endpoint the site's own UI uses, filterable
directly by `country=IND`, not an undocumented internal API we had to reverse-engineer.

Note on the other 4 "mega-caps," for the record (none get an adapter, each for a different
reason):
- Meta: `metacareers.com`'s robots.txt explicitly states automated collection is prohibited
  without written permission. Hard no — this is a stated policy, not a technical obstacle.
- Apple: a plain request to jobs.apple.com's robots.txt path redirected through an Apple ID
  sign-in flow — an ambiguous but concerning signal, not pursued without clearer verification
  that public job browsing genuinely doesn't require authentication.
- Google: careers.google.com is a heavily dynamic SPA with no discoverable sitemap or public
  JSON endpoint found via direct HTTP probing — would need real browser-based network
  inspection (not available in this environment) to find the actual internal API, which is a
  different risk profile than reusing a site's own confirmed-public endpoint like Amazon's.
- Microsoft: careers run on Eightfold AI (a third-party ATS, confirmed via branding in
  redirect responses) — worth investigating as its own platform-level adapter (like Workday)
  since it may cover other companies too, not built yet as of this commit.
"""
import httpx

from app.adapters.common import HTTP_TIMEOUT, USER_AGENT, html_to_text
from app.schemas import Job
from app.filters import is_relevant_job, is_senior_excluded, extract_skills, extract_min_years_experience

PAGE_SIZE = 100
MAX_RESULTS = 1000  # safety cap — India total is ~2300 before filtering; this is generous
                     # headroom for the relevant/non-senior subset, not a real limit


async def scrape(company: dict, client: httpx.AsyncClient) -> list[Job]:
    all_jobs_raw: list[dict] = []
    for offset in range(0, MAX_RESULTS, PAGE_SIZE):
        url = (
            "https://www.amazon.jobs/en/search.json"
            f"?country=IND&offset={offset}&result_limit={PAGE_SIZE}"
        )
        resp = await client.get(url, timeout=HTTP_TIMEOUT, headers={"User-Agent": USER_AGENT})
        resp.raise_for_status()
        data = resp.json()
        page = data.get("jobs", [])
        all_jobs_raw.extend(page)
        if len(page) < PAGE_SIZE or offset + PAGE_SIZE >= data.get("hits", 0):
            break

    results: list[Job] = []
    for job in all_jobs_raw:
        title = (job.get("title") or "").strip()
        department = job.get("job_category") or job.get("business_category") or ""
        if not is_relevant_job(title, department):
            continue

        # country_code already confirms India at the API level (we requested country=IND),
        # so no separate is_india_location re-check needed here unlike the other adapters —
        # this endpoint doesn't mix in non-India results the way a global sitemap does.
        location = job.get("normalized_location") or job.get("location") or "India"

        # Confirmed live (2026-10-08): amazon.jobs's description/qualifications fields embed
        # inline HTML (e.g. "<br/>"), same risk as Greenhouse/Ashby — see html_to_text.
        description = html_to_text(job.get("description") or "")
        qualifications = html_to_text(job.get("basic_qualifications") or "")
        full_text = f"{description} {qualifications}"
        if is_senior_excluded(title, full_text):
            continue

        job_path = job.get("job_path", "")
        apply_url = f"https://www.amazon.jobs{job_path}" if job_path else "https://www.amazon.jobs"

        results.append(Job(
            id=f"amazon_{job.get('id', job_path)}",
            company="Amazon",
            platform="amazon",
            title=title,
            department=department,
            location=location,
            apply_url=apply_url,
            posted_at=job.get("posted_date"),
            extracted_skills=extract_skills(f"{title} {full_text}"),
            description=full_text,
            min_years_experience=extract_min_years_experience(full_text),
        ))
    return results
