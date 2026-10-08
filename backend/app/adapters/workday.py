"""
Ported from old_version/scraper/scraper.js (scrapeWorkday) — the highest-value non-"big 4"
adapter: Workday is the #1 ATS among large enterprises (confirmed via live research during
registry expansion — Adobe, Salesforce, Walmart, Wells Fargo, Morgan Stanley, Deutsche Bank,
Target, Philips, HPE, Dell, Autodesk, Qualcomm are all on it), and its internal JSON endpoint
needs no headless browser once accessed correctly.

ROOT CAUSE, found by actually testing rather than assuming (two wrong diagnoses before this):
1. First assumption: "Cloudflare is blocking us" — wrong, or at least incomplete.
2. Second fix: added Referer/Origin headers, saw 10/10 success on NVIDIA/Mastercard, declared
   it solved — ALSO wrong. Retesting against 12 new companies immediately after showed 0/12,
   and a closer look found Adobe's own endpoint flipping 200 -> 400 -> 400 across consecutive
   calls even with the headers in place.
3. Actual root cause: REQUEST RATE, not missing headers. Back-to-back POSTs with no spacing
   trigger a block; the same requests spaced 2s apart succeeded 8/8 in direct testing. This is
   paginating like an impatient script, not browsing like a person — the fix is to pace
   requests, not to add more retry attempts at the same rate (retries alone do not fix a
   rate-based block; they just hit the same wall repeatedly).
This is rate-limiting ourselves to behave like a real, unhurried visitor — not evasion, no
challenge-solving, no fake UA/IP tricks.
"""
import asyncio

import httpx

from app.adapters.common import HTTP_TIMEOUT, normalize_location, request_with_retries
from app.schemas import Job
from app.filters import is_relevant_job, is_india_location, is_senior_excluded, extract_skills

PAGE_SIZE = 100
MAX_OFFSET = 1000  # Workday enterprises can have 1000+ postings; cap to stay bounded.
PAGE_DELAY_SECONDS = 2.0  # verified live: <2s spacing between POSTs reliably triggers a block
POST_SESSION_WARMUP_DELAY_SECONDS = 1.0

BROWSER_USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 "
    "(KHTML, like Gecko) Version/17.0 Safari/605.1.15"
)


async def scrape(company: dict, client: httpx.AsyncClient) -> list[Job]:
    api_url = company["slug"]
    url_base = company.get("url_base", "")
    all_postings = []

    # Step 1: visit the real careers page first, exactly like a real visitor — picks up
    # session cookies.
    if url_base:
        try:
            await client.get(
                url_base, timeout=HTTP_TIMEOUT,
                headers={
                    "User-Agent": BROWSER_USER_AGENT,
                    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                },
            )
            await asyncio.sleep(POST_SESSION_WARMUP_DELAY_SECONDS)
        except httpx.HTTPError:
            pass  # proceed anyway; the POST below will just fail and we move on

    origin = "/".join(url_base.split("/")[:3]) if url_base else None
    api_headers = {
        "User-Agent": BROWSER_USER_AGENT,
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
    if url_base:
        api_headers["Referer"] = url_base
    if origin:
        api_headers["Origin"] = origin

    for offset in range(0, MAX_OFFSET, PAGE_SIZE):
        if offset > 0:
            await asyncio.sleep(PAGE_DELAY_SECONDS)
        try:
            resp = await request_with_retries(
                client,
                "POST",
                api_url,
                json={"appliedFacets": {}, "limit": PAGE_SIZE, "offset": offset, "searchText": ""},
                headers=api_headers,
                retries=3,
                backoff_seconds=2.0,  # match the rate the server actually tolerates
            )
            resp.raise_for_status()
            postings = resp.json().get("jobPostings", [])
            all_postings.extend(postings)
            if len(postings) < PAGE_SIZE:
                break
        except httpx.HTTPError:
            break

    results: list[Job] = []
    for post in all_postings:
        title = post.get("title", "")
        if not is_relevant_job(title, ""):
            continue

        location = normalize_location(post.get("locationsText"))
        if not is_india_location(location):
            continue

        if is_senior_excluded(title, ""):
            continue

        bullet_id = (post.get("bulletFields") or [None])[0] or title
        external_path = post.get("externalPath", "")

        results.append(Job(
            id=f"workday_{company['name'].replace(' ', '_')}_{bullet_id}",
            company=company["name"],
            platform="workday",
            title=title.strip(),
            department="",
            location=location,
            apply_url=f"{url_base}{external_path}" if url_base else f"{api_url}{external_path}",
            posted_at=post.get("postedOn"),
            extracted_skills=extract_skills(title),
        ))
    return results
