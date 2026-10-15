import asyncio
import logging
import time
from typing import Optional

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.adapters import amazon, ashby, greenhouse, lever, smartrecruiters, workable, workday, workday_sitemap
from app.community import router as community_router
from app.community_db import init_db as init_community_db
from app.companies import COMPANIES, NEEDS_REVIEW
from app.feedback import router as feedback_router
from app.profile import router as profile_router
from app.schemas import Job

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("aline")

app = FastAPI(title="Aline Backend", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(community_router)
app.include_router(profile_router)
app.include_router(feedback_router)

ADAPTERS = {
    "greenhouse": greenhouse.scrape,
    "lever": lever.scrape,
    "ashby": ashby.scrape,
    "workday": workday.scrape,  # legacy, blocked-endpoint based — unused, no companies route here
    "workday_sitemap": workday_sitemap.scrape,  # active Workday path — see its module docstring
    "smartrecruiters": smartrecruiters.scrape,
    "workable": workable.scrape,
    "amazon": amazon.scrape,  # genuinely public search.json API — see amazon.py docstring
}

# Workable rate-limits aggressively (429 after a couple of back-to-back requests from one
# IP — confirmed live during Milestone 0). Everything else can run with more headroom.
#
# workday_sitemap gets real but deliberately moderate concurrency: each company already paces
# itself internally (1.5s between its own job-page fetches — see workday_sitemap.py), so this
# number controls how many DIFFERENT companies' sitemap+job-page loops run at once, not
# per-request speed. Verified live (2026-10-08): zero blocking across dozens of requests to
# this endpoint at light-to-moderate concurrency, a completely different code path from the
# old `wday/cxs/.../jobs` search API that got blocked (see workday.py's module docstring) —
# but 40 companies is still new territory for this method, so staying moderate (8) rather than
# matching the other fast platforms' 15, until a full production cycle is observed.
#
# "workday" (legacy) is NOT in this map — no companies route to it (see companies.py), kept
# only for reference/history.
PLATFORM_CONCURRENCY = {
    "greenhouse": 15, "lever": 15, "ashby": 15,
    "smartrecruiters": 15, "workable": 3, "workday_sitemap": 8,
}

CACHE_TTL_SECONDS = 10 * 60  # periodic refresh, not re-scraped on every request

# A company's last-known-good jobs survive this many consecutive failed refresh cycles before
# being dropped from the feed. Without this, a single transient failure (DNS blip, a one-off
# 500 from the source, a rate limit) wiped that company's jobs out of /jobs immediately —
# indistinguishable from those jobs actually closing, and a real risk of a user missing a
# still-open opportunity for a reason that has nothing to do with the job itself. 3 cycles
# (~30 min at the current 10-minute TTL) tolerates a transient blip while still eventually
# reflecting a source that's genuinely down or discontinued, rather than caching it forever.
MAX_CONSECUTIVE_FAILURES = 3


def _company_key(company: dict) -> tuple:
    # (name, platform, slug-or-url_base) — verified unique across the full registry; name
    # alone collides (several companies share a display name across platforms) and slug alone
    # collides even more (workday_sitemap entries key off url_base, not slug).
    return (company["name"], company["platform"], company.get("slug") or company.get("url_base"))


class JobsCache:
    def __init__(self):
        self.jobs: list[Job] = []
        self.last_refreshed: float = 0
        self.last_error: Optional[str] = None
        self.refreshing = False
        # Lets a request that arrives while the very first scrape is still in flight
        # (e.g. right after startup) actually wait for it, instead of racing it and
        # returning an empty list — the bug that shipped first: 0 jobs within 10ms of the
        # startup scrape still running.
        self.ready_event = asyncio.Event()
        # Per-company last-known-good jobs + consecutive failure count — see
        # MAX_CONSECUTIVE_FAILURES and refresh_cache's merge logic below.
        self.company_jobs: dict[tuple, list[Job]] = {}
        self.company_fail_streak: dict[tuple, int] = {}
        # Companies currently mid-failure-streak (but not yet dropped) as of the last refresh —
        # surfaced on /companies so a scraper problem is visible, not silently indistinguishable
        # from "those companies just have zero open jobs right now."
        self.companies_degraded: list[str] = []

    def is_stale(self) -> bool:
        return (time.time() - self.last_refreshed) > CACHE_TTL_SECONDS


cache = JobsCache()


async def scrape_all() -> dict[tuple, tuple[list[Job], bool]]:
    """
    Every active platform (including workday_sitemap) tolerates real concurrency — see
    PLATFORM_CONCURRENCY above for per-platform limits and why. The old fully-serial,
    heavily-spaced Workday path is gone: no companies route to the legacy "workday" adapter
    that needed it (see companies.py) — workday_sitemap hits a fundamentally different,
    unblocked endpoint.

    Returns {company_key: (jobs, succeeded)} rather than a flat job list — refresh_cache needs
    to tell a company that scraped to a genuine empty result apart from one whose scrape
    outright failed, so a failure never gets merged in as if it were real "zero jobs" data.
    """
    sems = {platform: asyncio.Semaphore(n) for platform, n in PLATFORM_CONCURRENCY.items()}

    async def scrape_one(company: dict, client: httpx.AsyncClient) -> tuple[tuple, list[Job], bool]:
        key = _company_key(company)
        adapter = ADAPTERS.get(company["platform"])
        if adapter is None:
            return key, [], True  # unroutable platform, not a failure — genuinely nothing to show
        sem = sems.get(company["platform"], asyncio.Semaphore(10))
        async with sem:
            try:
                return key, await adapter(company, client), True
            except Exception as exc:  # noqa: BLE001 — one bad source shouldn't break the rest
                logger.warning("Scrape failed for %s (%s): %s", company["name"], company["platform"], exc)
                return key, [], False

    async with httpx.AsyncClient(follow_redirects=True) as client:
        results = await asyncio.gather(*(scrape_one(c, client) for c in COMPANIES))

    return {key: (jobs, ok) for key, jobs, ok in results}


async def refresh_cache():
    if cache.refreshing:
        return
    cache.refreshing = True
    started = time.time()
    try:
        results = await scrape_all()
        degraded: list[str] = []
        current_keys = {_company_key(c) for c in COMPANIES}
        name_by_key = {_company_key(c): c["name"] for c in COMPANIES}

        for key, (jobs, ok) in results.items():
            if ok:
                cache.company_jobs[key] = jobs
                cache.company_fail_streak[key] = 0
            else:
                streak = cache.company_fail_streak.get(key, 0) + 1
                cache.company_fail_streak[key] = streak
                if streak > MAX_CONSECUTIVE_FAILURES:
                    # Genuinely treat as gone only after repeated failures — a real signal the
                    # source is down/discontinued, not a one-off blip.
                    cache.company_jobs[key] = []
                else:
                    # Keep the prior cycle's jobs as-is; this company's contribution to /jobs
                    # doesn't change just because this one cycle's fetch failed.
                    degraded.append(name_by_key.get(key, str(key)))

        # Drop any company no longer in the registry (e.g. removed from companies.py) so its
        # stale jobs don't linger in the cache forever.
        for stale_key in list(cache.company_jobs.keys()):
            if stale_key not in current_keys:
                del cache.company_jobs[stale_key]
                cache.company_fail_streak.pop(stale_key, None)

        cache.jobs = [job for jobs in cache.company_jobs.values() for job in jobs]
        cache.companies_degraded = degraded
        cache.last_refreshed = time.time()
        cache.last_error = None
        cache.ready_event.set()
        logger.info(
            "Refreshed cache: %d jobs from %d companies in %.1fs (%d degraded, kept from last cycle)",
            len(cache.jobs), len(COMPANIES), time.time() - started, len(degraded),
        )
    except Exception as exc:  # noqa: BLE001
        cache.last_error = str(exc)
        logger.error("Cache refresh failed: %s", exc)
    finally:
        cache.refreshing = False


@app.on_event("startup")
async def on_startup():
    init_community_db()
    asyncio.create_task(refresh_cache())


@app.get("/")
async def root():
    return {"service": "aline-backend", "try": ["/health", "/jobs", "/companies", "/community/discussions", "/profile"]}


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/companies")
async def companies_status():
    return {
        "registered": len(COMPANIES),
        "needs_review": len(NEEDS_REVIEW),
        "by_platform": _count_by_platform(COMPANIES),
        "cache_last_refreshed": cache.last_refreshed,
        "cache_job_count": len(cache.jobs),
        "cache_last_error": cache.last_error,
        # Companies whose last scrape failed but whose jobs are still being shown from a
        # prior successful cycle (see MAX_CONSECUTIVE_FAILURES) — a scraper problem should be
        # visible here, never silently indistinguishable from "that company has 0 jobs."
        "companies_degraded": cache.companies_degraded,
    }


@app.get("/jobs", response_model=list[Job])
async def get_jobs():
    """
    Serves from an in-memory cache, refreshed in the background every CACHE_TTL_SECONDS —
    NOT a live scrape on every request, which would be both slow (100+ companies) and
    discourteous to the source sites. If nothing's cached yet (cold start, or a request that
    arrives while the very first scrape is still in flight), this actually waits for it
    rather than racing it and returning an empty list.
    """
    if not cache.jobs:
        if not cache.refreshing:
            asyncio.create_task(refresh_cache())
        await cache.ready_event.wait()
    elif cache.is_stale():
        asyncio.create_task(refresh_cache())  # serve stale cache, refresh in background
    return cache.jobs


def _count_by_platform(companies: list[dict]) -> dict:
    counts: dict = {}
    for c in companies:
        counts[c["platform"]] = counts.get(c["platform"], 0) + 1
    return counts
