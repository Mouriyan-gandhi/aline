"""
The plan's "ATS slug-prober script" (Target company list section): takes candidate company
names, generates likely slug variants, and batch-tests them against the live Greenhouse,
Lever, Ashby, SmartRecruiters, and Workable endpoints to auto-confirm which actually resolve.
Workday/SuccessFactors/iCIMS are NOT included here — unlike the other five, their endpoints
need a real tenant/site path that isn't guessable from a company name alone (confirmed during
Milestone 0: Workday needs the actual careers-page URL, not just a slug guess), so those stay
a manual/semi-automated discovery task, not something this prober can brute-force.

Run directly: `python -m app.slug_prober` — writes app/companies_resolved.json.
"""
import asyncio
import json
import re
import sys

import httpx

from app.company_candidates import ALL_CATEGORIES

TIMEOUT = 10.0
USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"

CORPORATE_SUFFIXES = [
    " technologies", " technology", " systems", " software", " financial", " holdings",
    " global tech", " group", " global", " corporation", " corp", " inc", " llc", " ltd",
    " limited", " bank", " labs", " .com",
]


# A candidate name written as a short, all-caps acronym (TCS, GE, IBM, SAP, ABB) is
# collision-prone in a way a length check alone doesn't capture — found live: "TCS" (3 chars)
# auto-resolved on Greenhouse to an unrelated UK nursing company. A flat length cutoff would
# also wrongly demote real coined brand names of similar length (Uber, Loom, Okta, Miro,
# Wise, Zeta) that aren't acronyms and aren't meaningfully collision-prone the same way —
# acronym-style capitalization in the ORIGINAL candidate name is the actual signal: an
# initialism could plausibly stand for many unrelated things, a coined brand word can't.
_ACRONYM_LOW_CONFIDENCE_MAX_LENGTH = 4


def _looks_like_acronym(name: str) -> bool:
    letters = re.sub(r"[^A-Za-z]", "", name)
    return bool(letters) and letters.isupper() and len(letters) <= _ACRONYM_LOW_CONFIDENCE_MAX_LENGTH


def slug_variants(name: str) -> list[tuple[str, str]]:
    """Returns (slug, confidence) pairs — 'high' for full-name variants, 'low' for
    first-word-only (more prone to colliding with an unrelated company on the platform) OR
    any variant derived from a short all-caps acronym name (see _looks_like_acronym)."""
    is_acronym = _looks_like_acronym(name)

    base = name.lower().strip()
    for suffix in CORPORATE_SUFFIXES:
        if base.endswith(suffix):
            base = base[: -len(suffix)].strip()

    cleaned = re.sub(r"[^a-z0-9\s-]", "", base)
    words = cleaned.split()
    if not words:
        return []

    compressed = "".join(words)
    hyphenated = "-".join(words)

    full_name_confidence = "low" if is_acronym else "high"
    variants = [(compressed, full_name_confidence)]
    if hyphenated != compressed:
        variants.append((hyphenated, full_name_confidence))
    if len(words) > 1:
        variants.append((words[0], "low"))
    return variants


async def try_greenhouse(client: httpx.AsyncClient, slug: str) -> bool:
    r = await client.get(
        f"https://boards-api.greenhouse.io/v1/boards/{slug}/jobs",
        timeout=TIMEOUT, headers={"User-Agent": USER_AGENT},
    )
    return r.status_code == 200


async def try_lever(client: httpx.AsyncClient, slug: str) -> bool:
    r = await client.get(
        f"https://api.lever.co/v0/postings/{slug}?mode=json",
        timeout=TIMEOUT, headers={"User-Agent": USER_AGENT},
    )
    return r.status_code == 200 and isinstance(r.json(), list)


async def try_ashby(client: httpx.AsyncClient, slug: str) -> bool:
    r = await client.get(
        f"https://api.ashbyhq.com/posting-api/job-board/{slug}",
        timeout=TIMEOUT, headers={"User-Agent": USER_AGENT},
    )
    return r.status_code == 200 and "jobs" in r.json()


async def try_smartrecruiters(client: httpx.AsyncClient, slug: str) -> bool:
    # IMPORTANT: this endpoint returns HTTP 200 with an empty-but-valid-shaped body for
    # ANY slug, including nonexistent ones — it never 404s (confirmed live during Milestone
    # 0: a garbage slug like "totallyfakecompanyxyz123" still returns 200). The only honest
    # signal is whether it actually has current postings.
    r = await client.get(
        f"https://api.smartrecruiters.com/v1/companies/{slug}/postings",
        timeout=TIMEOUT, headers={"User-Agent": USER_AGENT},
    )
    if r.status_code != 200:
        return False
    data = r.json()
    return "content" in data and data.get("totalFound", 0) > 0


async def try_workable(client: httpx.AsyncClient, slug: str) -> bool:
    # Workable DOES properly 404 a nonexistent account (verified live, isolated from
    # concurrent load) — but it also rate-limits aggressively (429 after just a couple of
    # back-to-back requests from one IP), which a naive check would misread as "not found".
    # Retry through 429s before concluding anything.
    for attempt in range(4):
        r = await client.get(
            f"https://apply.workable.com/api/v1/widget/accounts/{slug}",
            timeout=TIMEOUT, headers={"User-Agent": USER_AGENT},
        )
        if r.status_code == 429:
            await asyncio.sleep(1.5 * (attempt + 1))
            continue
        if r.status_code != 200:
            return False
        data = r.json()
        return "jobs" in data and len(data.get("jobs", [])) > 0
    return False


ALL_PLATFORM_CHECKS = {
    "greenhouse": try_greenhouse,
    "lever": try_lever,
    "ashby": try_ashby,
    "smartrecruiters": try_smartrecruiters,
    "workable": try_workable,
}

# Workable rate-limits hard enough (see try_workable) that running it in the same fast pass
# as the other four roughly triples total run time for comparatively low yield against this
# candidate list (which skews toward large enterprises — Workable is mostly smaller/startup
# companies). Run it separately via `--include-workable` when there's time, not by default.
PLATFORM_CHECKS = (
    ALL_PLATFORM_CHECKS
    if "--include-workable" in sys.argv
    else {k: v for k, v in ALL_PLATFORM_CHECKS.items() if k != "workable"}
)


PLATFORM_CONCURRENCY = {
    "greenhouse": 20, "lever": 20, "ashby": 20, "smartrecruiters": 20,
    "workable": 3,  # aggressive rate limiter — see try_workable
}


async def probe_one(
    client: httpx.AsyncClient, sems: dict, category: str, name: str
) -> list[dict]:
    hits = []
    for slug, confidence in slug_variants(name):
        for platform, check in PLATFORM_CHECKS.items():
            async with sems[platform]:
                try:
                    if await check(client, slug):
                        hits.append({
                            "name": name, "category": category, "platform": platform,
                            "slug": slug, "confidence": confidence,
                        })
                except (httpx.HTTPError, ValueError):
                    pass
    return hits


async def main():
    sems = {platform: asyncio.Semaphore(n) for platform, n in PLATFORM_CONCURRENCY.items()}
    results = []
    total = sum(len(v) for v in ALL_CATEGORIES.values())
    done = 0

    async with httpx.AsyncClient(follow_redirects=True) as client:
        tasks = []
        for category, names in ALL_CATEGORIES.items():
            for name in names:
                tasks.append(probe_one(client, sems, category, name))

        for coro in asyncio.as_completed(tasks):
            hits = await coro
            results.extend(hits)
            done += 1
            if done % 25 == 0 or done == total:
                print(f"  probed {done}/{total} companies, {len(results)} hits so far", file=sys.stderr)

    with open("app/companies_resolved.json", "w") as f:
        json.dump(results, f, indent=2)

    by_platform = {}
    for hit in results:
        by_platform.setdefault(hit["platform"], 0)
        by_platform[hit["platform"]] += 1
    print(f"\nDone. {len(results)} total hits across {len(set(h['name'] for h in results))} companies.", file=sys.stderr)
    print(f"By platform: {by_platform}", file=sys.stderr)


if __name__ == "__main__":
    asyncio.run(main())
