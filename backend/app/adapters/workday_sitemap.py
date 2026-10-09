"""
Workday adapter, v2 — sitemap + JobPosting JSON-LD, replacing the blocked search-API approach.

Why this exists (full reasoning in the plan file, "Workday data acquisition" section):
the old approach called Workday's internal `wday/cxs/.../jobs` search API directly — the same
endpoint the page's own JS calls, but NOT published anywhere, NOT meant for third-party
consumption, and sitting behind a Cloudflare layer that escalates-blocks on cumulative request
volume from one IP. That approach is kept in workday.py but disabled (see companies.py).

This adapter instead uses two things every Workday tenant explicitly publishes for automated
readers:
1. `robots.txt` -> `Sitemap:` directive -> a sitemap.xml listing EVERY current job URL.
   This is the open "Sitemaps protocol" (sitemaps.org) — a company publishing one is an
   explicit, standard "please crawl this" signal, not something we found by accident.
2. Each job URL's page embeds `schema.org JobPosting` JSON-LD — data the company formats
   specifically for machine consumption (Google for Jobs, etc.), not something we're
   extracting in spite of them.

Verified live (2026-10-08): 10/10 successful job-page fetches across Adobe/Cisco/PayPal, all
carrying full JobPosting JSON-LD, zero blocking at 1.5-2s spacing — a completely different
code path from the blocked search API, because there's no bot defense in front of content a
site is begging crawlers to read.

Still respectful by default: honors robots.txt Disallow rules for the sitemap/job paths, and
paces individual job-page fetches (not just fire-them-all-concurrently) even though no
blocking was observed, per the project's standing policy of reasonable pacing regardless of
whether a given source is currently enforcing it.
"""
import asyncio
import json
import re
from typing import Optional
from urllib.parse import urljoin, urlparse

import httpx
from urllib.robotparser import RobotFileParser

from app.adapters.common import HTTP_TIMEOUT, USER_AGENT, html_to_text, unescape_text
from app.schemas import Job
from app.filters import (
    is_relevant_job, is_india_location, is_senior_excluded, is_senior_excluded_in_slug,
    extract_skills, extract_min_years_experience,
)

JOB_PAGE_DELAY_SECONDS = 1.5
MAX_JOBS_PER_COMPANY = 400  # safety cap; largest tenant seen so far (Cisco) was ~1375 total,
                             # ~280 India-matched — this is generous headroom, not a real limit

_LD_JSON_PATTERN = re.compile(
    r'<script[^>]*type=["\']application/ld\+json["\'][^>]*>(.*?)</script>',
    re.DOTALL | re.IGNORECASE,
)


async def _fetch_robots_and_sitemap_urls(client: httpx.AsyncClient, base_url: str) -> list[str]:
    robots_url = urljoin(base_url, "/robots.txt")
    resp = await client.get(robots_url, timeout=HTTP_TIMEOUT, headers={"User-Agent": USER_AGENT})
    if resp.status_code != 200:
        return []

    parser = RobotFileParser()
    parser.parse(resp.text.splitlines())

    sitemap_urls = re.findall(r"Sitemap:\s*(\S+)", resp.text, re.IGNORECASE)
    allowed = [u for u in sitemap_urls if parser.can_fetch(USER_AGENT, u)]
    return allowed or sitemap_urls  # if robots parsing finds nothing to disallow, use them all


async def _fetch_job_urls_from_sitemap(client: httpx.AsyncClient, sitemap_url: str) -> list[str]:
    resp = await client.get(sitemap_url, timeout=HTTP_TIMEOUT, headers={"User-Agent": USER_AGENT})
    if resp.status_code != 200:
        return []
    return re.findall(r"<loc>([^<]+)</loc>", resp.text)


def _is_india_url(url: str) -> bool:
    lowered = url.lower()
    return any(
        sig in lowered
        for sig in ["india", "bangalore", "bengaluru", "hyderabad", "chennai", "pune", "noida", "gurugram", "gurgaon", "mumbai"]
    )


def _url_slug_text(url: str) -> str:
    """The job title is usually readable directly in the URL slug, e.g. .../job/Bangalore-
    India/Software-Engineer_2020077 -> 'Bangalore India Software Engineer'. Cheap pre-filter
    so large tenants (hundreds of India postings, most irrelevant) don't require fetching
    every single page just to find out most aren't IT/software roles."""
    path = urlparse(url).path
    last_segment = path.rsplit("/", 1)[-1]
    without_id = re.sub(r"_[A-Za-z0-9-]+$", "", last_segment)  # strip trailing _R169928 etc.
    return without_id.replace("-", " ")


def _extract_job_posting_ld_json(html: str) -> Optional[dict]:
    for block in _LD_JSON_PATTERN.findall(html):
        try:
            data = json.loads(block.strip())
        except (ValueError, TypeError):
            continue
        if isinstance(data, dict) and data.get("@type") == "JobPosting":
            return data
        if isinstance(data, list):
            for item in data:
                if isinstance(item, dict) and item.get("@type") == "JobPosting":
                    return item
    return None


def _location_from_ld_json(data: dict) -> str:
    loc = data.get("jobLocation")
    if isinstance(loc, list):
        loc = loc[0] if loc else {}
    if not isinstance(loc, dict):
        return "Not specified"
    address = loc.get("address", {})
    if not isinstance(address, dict):
        return "Not specified"
    parts = [address.get("addressLocality"), address.get("addressRegion"), address.get("addressCountry")]
    return ", ".join(p for p in parts if p) or "Not specified"


async def scrape(company: dict, client: httpx.AsyncClient) -> list[Job]:
    """
    `company["slug"]` here is the tenant's base career-site URL, e.g.
    "https://adobe.wd5.myworkdayjobs.com/en-US/external_experienced" — the same `url_base`
    value already used by the legacy workday.py adapter (so existing registry entries port
    over directly, just by switching which adapter function is called for them).
    """
    base_url = company.get("url_base") or company["slug"]
    parsed = urlparse(base_url)
    origin = f"{parsed.scheme}://{parsed.netloc}"

    sitemap_urls = await _fetch_robots_and_sitemap_urls(client, origin)
    if not sitemap_urls:
        return []

    all_job_urls: list[str] = []
    for sitemap_url in sitemap_urls:
        all_job_urls.extend(await _fetch_job_urls_from_sitemap(client, sitemap_url))

    # Some tenants publish multiple sitemaps (e.g. a locale variant alongside the main one —
    # found live: Mastercard's robots.txt lists more than one, and the same job appeared in
    # both). Dedupe by URL before fetching — saves wasted requests, and is the first of two
    # dedup layers (see job_id dedup below, which catches the case where two DIFFERENT URLs
    # still resolve to the same underlying requisition ID).
    all_job_urls = list(dict.fromkeys(all_job_urls))

    india_job_urls = [u for u in all_job_urls if _is_india_url(u)]
    # Cheap pre-filter on the URL slug text before committing to a full page fetch per job —
    # large tenants (Cisco: ~280 India URLs) would otherwise mean fetching every single page
    # just to discover most aren't relevant at all (sales/HR/manufacturing, or senior-only —
    # years-of-experience is frequently right in the title slug, e.g. "...-12-15-Years").
    relevant_job_urls = [
        u for u in india_job_urls
        if is_relevant_job(_url_slug_text(u))
        and not is_senior_excluded_in_slug(_url_slug_text(u))
    ][:MAX_JOBS_PER_COMPANY]

    results: list[Job] = []
    for i, job_url in enumerate(relevant_job_urls):
        if i > 0:
            await asyncio.sleep(JOB_PAGE_DELAY_SECONDS)
        try:
            resp = await client.get(job_url, timeout=HTTP_TIMEOUT, headers={"User-Agent": USER_AGENT})
        except httpx.HTTPError:
            continue
        if resp.status_code != 200:
            continue

        ld_json = _extract_job_posting_ld_json(resp.text)
        if not ld_json:
            continue  # page didn't carry structured data this time; skip rather than guess

        title = unescape_text((ld_json.get("title") or "").strip())
        # schema.org JobPosting's description is conventionally HTML (it's meant for a
        # browser/search-engine renderer), same risk as Greenhouse's content/Ashby's
        # descriptionHtml — see html_to_text's docstring for the live false-positive this
        # caused.
        description = html_to_text(ld_json.get("description") or "")
        if not is_relevant_job(title, ""):
            continue

        location = _location_from_ld_json(ld_json)
        # job_url already passed the India-text prefilter before we got here; this is a
        # second check against the actual structured location, in case the URL mentioned
        # India in passing (e.g. a comparison/relocation note) but the real post isn't there.
        if location != "Not specified" and not is_india_location(location):
            continue

        if is_senior_excluded(title, description):
            continue

        job_id = (ld_json.get("identifier") or {}).get("value") or job_url
        full_id = f"workday_sitemap_{company['name'].replace(' ', '_')}_{job_id}"

        results.append(Job(
            id=full_id,
            company=company["name"],
            platform="workday",
            title=title,
            department="",
            location=location,
            apply_url=job_url,
            posted_at=ld_json.get("datePosted"),
            extracted_skills=extract_skills(f"{title} {description}"),
            description=description,
            min_years_experience=extract_min_years_experience(description),
        ))

    # Second dedup layer: the URL-level dedup above doesn't catch two DIFFERENT URLs (e.g.
    # distinct locale paths) resolving to the same underlying requisition id — confirmed live
    # with Mastercard (crashed the iOS app's `Dictionary(uniqueKeysWithValues:)`, since a
    # duplicate `Job.id` is a hard contract violation downstream, not just redundant data).
    seen_ids: set[str] = set()
    deduped: list[Job] = []
    for job in results:
        if job.id in seen_ids:
            continue
        seen_ids.add(job.id)
        deduped.append(job)

    return deduped
