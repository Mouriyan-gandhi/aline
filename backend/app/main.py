import asyncio
import logging
import time
from typing import Optional

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.adapters import amazon, ashby, greenhouse, lever, smartrecruiters, workable, workday, workday_sitemap
from app.companies import COMPANIES, NEEDS_REVIEW
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

    def is_stale(self) -> bool:
        return (time.time() - self.last_refreshed) > CACHE_TTL_SECONDS


cache = JobsCache()


async def scrape_all() -> list[Job]:
    """
    Every active platform (including workday_sitemap) tolerates real concurrency — see
    PLATFORM_CONCURRENCY above for per-platform limits and why. The old fully-serial,
    heavily-spaced Workday path is gone: no companies route to the legacy "workday" adapter
    that needed it (see companies.py) — workday_sitemap hits a fundamentally different,
    unblocked endpoint.
    """
    sems = {platform: asyncio.Semaphore(n) for platform, n in PLATFORM_CONCURRENCY.items()}

    async def scrape_one(company: dict, client: httpx.AsyncClient) -> list[Job]:
        adapter = ADAPTERS.get(company["platform"])
        if adapter is None:
            return []
        sem = sems.get(company["platform"], asyncio.Semaphore(10))
        async with sem:
            try:
                return await adapter(company, client)
            except Exception as exc:  # noqa: BLE001 — one bad source shouldn't break the rest
                logger.warning("Scrape failed for %s (%s): %s", company["name"], company["platform"], exc)
                return []

    async with httpx.AsyncClient(follow_redirects=True) as client:
        results = await asyncio.gather(*(scrape_one(c, client) for c in COMPANIES))

    return [job for company_jobs in results for job in company_jobs]


async def refresh_cache():
    if cache.refreshing:
        return
    cache.refreshing = True
    started = time.time()
    try:
        jobs = await scrape_all()
        cache.jobs = jobs
        cache.last_refreshed = time.time()
        cache.last_error = None
        cache.ready_event.set()
        logger.info(
            "Refreshed cache: %d jobs from %d companies in %.1fs",
            len(jobs), len(COMPANIES), time.time() - started,
        )
    except Exception as exc:  # noqa: BLE001
        cache.last_error = str(exc)
        logger.error("Cache refresh failed: %s", exc)
    finally:
        cache.refreshing = False


@app.on_event("startup")
async def on_startup():
    asyncio.create_task(refresh_cache())


@app.get("/")
async def root():
    return {"service": "aline-backend", "try": ["/health", "/jobs", "/companies"]}


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
