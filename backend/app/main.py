import asyncio
import logging
import time
from typing import Optional

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.adapters import ashby, greenhouse, lever, smartrecruiters, workable, workday
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
    "workday": workday.scrape,
    "smartrecruiters": smartrecruiters.scrape,
    "workable": workable.scrape,
}

# Workable rate-limits aggressively (429 after a couple of back-to-back requests from one
# IP — confirmed live during Milestone 0). Everything else can run with more headroom.
# Workday is handled completely separately (see WORKDAY_INTER_COMPANY_DELAY_SECONDS below) —
# it is NOT in this concurrency map because concurrent/rapid requests to it, even spaced
# per-company-pagination, were found live to trigger an escalating block tied to cumulative
# request volume across the whole myworkdayjobs.com surface from one IP (not per-tenant,
# not fixable by Referer/Origin headers alone — confirmed by testing: a single isolated
# request to any tenant succeeds reliably; a burst across multiple tenants within a short
# window does not, even with 2-3s spacing between them).
PLATFORM_CONCURRENCY = {
    "greenhouse": 15, "lever": 15, "ashby": 15,
    "smartrecruiters": 15, "workable": 3,
}

# Real, conservative spacing between *every* Workday request across *all* companies in a
# scrape cycle — this is what actually keeps us under the block, not per-company concurrency
# limiting (which still allows bursts). Workday also runs with concurrency=1 (see scrape_all).
WORKDAY_INTER_COMPANY_DELAY_SECONDS = 8.0

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


async def scrape_fast_platforms(companies: list[dict]) -> list[Job]:
    """Greenhouse/Lever/Ashby/SmartRecruiters/Workable — all tolerate real concurrency."""
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
        results = await asyncio.gather(*(scrape_one(c, client) for c in companies))

    return [job for company_jobs in results for job in company_jobs]


async def scrape_workday_serially(companies: list[dict]) -> list[Job]:
    """
    Fully serial, heavily spaced — see WORKDAY_INTER_COMPANY_DELAY_SECONDS docstring above
    for why. Each company gets its own fresh client (not strictly required, but keeps
    cookie state cleanly scoped per-tenant rather than accumulating across many tenants in
    one session, which may itself be a contributing factor to the cumulative block).
    """
    all_jobs: list[Job] = []
    for i, company in enumerate(companies):
        if i > 0:
            await asyncio.sleep(WORKDAY_INTER_COMPANY_DELAY_SECONDS)
        async with httpx.AsyncClient(follow_redirects=True) as client:
            try:
                jobs = await workday.scrape(company, client)
                all_jobs.extend(jobs)
            except Exception as exc:  # noqa: BLE001
                logger.warning("Workday scrape failed for %s: %s", company["name"], exc)
    return all_jobs


async def scrape_all() -> list[Job]:
    fast_companies = [c for c in COMPANIES if c["platform"] != "workday"]
    workday_companies = [c for c in COMPANIES if c["platform"] == "workday"]

    fast_jobs = await scrape_fast_platforms(fast_companies)
    workday_jobs = await scrape_workday_serially(workday_companies)

    return fast_jobs + workday_jobs


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
