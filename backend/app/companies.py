"""
The company registry. Two sources, merged:
1. SEED_COMPANIES — hand-verified during Milestone 0, kept as a guaranteed-good fallback.
2. companies_resolved.json — the slug_prober's output: real companies that, at probe time,
   actually had live India-filtered-relevant postings on one of the 5 slug-guessable ATS
   platforms (Greenhouse/Lever/Ashby/SmartRecruiters/Workable). Workday/SuccessFactors/iCIMS
   need per-company URL discovery and aren't in this auto-resolved set (see slug_prober.py).

Only "high" confidence hits are loaded automatically — "low" confidence (single generic-word
slug guesses, e.g. "Pine" for "Pine Labs") are excluded from the live registry and kept in
NEEDS_REVIEW for manual confirmation, since a generic slug can collide with an unrelated
company on the same platform.
"""
import json
import os

# Workday is DISABLED (kept out of SEED_COMPANIES, see WORKDAY_TENANTS_PENDING below), not
# deleted. Full timeline, so this doesn't get re-litigated from scratch later:
# 1. Adapter built correctly (session-primed GET, Referer/Origin headers, retries).
# 2. Full 12-company batch: 0/12, 298s — Cloudflare block from heavy debugging volume.
# 3. Re-tested Adobe alone ~15min later: succeeded first try. Looked like a clearing
#    cooldown -> re-enabled all 12.
# 4. A genuine, non-hammering production-shaped pass (12 companies, sequential, ~9s apart,
#    zero manual pre-testing) STILL hit the block again, starting on the very first company
#    (NVIDIA). So step 3's good result does not generalize — a single isolated request
#    succeeding does not mean a normal multi-tenant sequential pass will. The safe margin is
#    narrower than "wait a few minutes and retry."
# Conclusion: Workday is real and the code works, but isn't currently usable at the volume we
# need without either a much longer per-company interval than is practical for a 10min cache
# cycle (minutes, not seconds, between companies) or infrastructure (rotating IPs/proxies)
# that the plan and the user have both already ruled out as evasion. Disabled until a
# genuinely different approach is found — not "try again later with the same method."

SEED_COMPANIES = [
    {"name": "Databricks", "platform": "greenhouse", "slug": "databricks"},
    {"name": "Twilio", "platform": "greenhouse", "slug": "twilio"},
    {"name": "Zeta", "platform": "lever", "slug": "zeta"},
    {"name": "Harvey", "platform": "ashby", "slug": "harvey"},
]

# Workday tenant URLs — found via WebSearch (site:myworkdayjobs.com), each one verified live
# with a real isolated request before being recorded. NOT currently loaded into the active
# registry — see the timeline comment above SEED_COMPANIES for why.
WORKDAY_TENANTS_PENDING = [
    {"name": "NVIDIA", "platform": "workday",
     "slug": "https://nvidia.wd5.myworkdayjobs.com/wday/cxs/nvidia/NVIDIAExternalCareerSite/jobs",
     "url_base": "https://nvidia.wd5.myworkdayjobs.com/en-US/NVIDIAExternalCareerSite"},
    {"name": "Mastercard", "platform": "workday",
     "slug": "https://mastercard.wd1.myworkdayjobs.com/wday/cxs/mastercard/CorporateCareers/jobs",
     "url_base": "https://mastercard.wd1.myworkdayjobs.com/en-US/CorporateCareers"},
    {"name": "Adobe", "platform": "workday",
     "slug": "https://adobe.wd5.myworkdayjobs.com/wday/cxs/adobe/external_experienced/jobs",
     "url_base": "https://adobe.wd5.myworkdayjobs.com/en-US/external_experienced"},
    {"name": "Qualcomm", "platform": "workday",
     "slug": "https://qualcomm.wd12.myworkdayjobs.com/wday/cxs/qualcomm/External/jobs",
     "url_base": "https://qualcomm.wd12.myworkdayjobs.com/en-US/External"},
    {"name": "Autodesk", "platform": "workday",
     "slug": "https://autodesk.wd1.myworkdayjobs.com/wday/cxs/autodesk/Ext/jobs",
     "url_base": "https://autodesk.wd1.myworkdayjobs.com/en-US/Ext"},
    {"name": "Salesforce", "platform": "workday",
     "slug": "https://salesforce.wd12.myworkdayjobs.com/wday/cxs/salesforce/External_Career_Site/jobs",
     "url_base": "https://salesforce.wd12.myworkdayjobs.com/en-US/External_Career_Site"},
    {"name": "Wells Fargo", "platform": "workday",
     "slug": "https://wf.wd1.myworkdayjobs.com/wday/cxs/wf/WellsFargoJobs/jobs",
     "url_base": "https://wf.wd1.myworkdayjobs.com/en-US/WellsFargoJobs"},
    {"name": "Morgan Stanley", "platform": "workday",
     "slug": "https://ms.wd5.myworkdayjobs.com/wday/cxs/ms/External/jobs",
     "url_base": "https://ms.wd5.myworkdayjobs.com/en-US/External"},
    {"name": "Deutsche Bank", "platform": "workday",
     "slug": "https://db.wd3.myworkdayjobs.com/wday/cxs/db/DBWebsite/jobs",
     "url_base": "https://db.wd3.myworkdayjobs.com/en-US/DBWebsite"},
    {"name": "Target", "platform": "workday",
     "slug": "https://target.wd5.myworkdayjobs.com/wday/cxs/target/targetcareers/jobs",
     "url_base": "https://target.wd5.myworkdayjobs.com/en-US/targetcareers"},
    {"name": "Philips", "platform": "workday",
     "slug": "https://philips.wd3.myworkdayjobs.com/wday/cxs/philips/jobs-and-careers/jobs",
     "url_base": "https://philips.wd3.myworkdayjobs.com/en-US/jobs-and-careers"},
    {"name": "Hewlett Packard Enterprise", "platform": "workday",
     "slug": "https://hpe.wd5.myworkdayjobs.com/wday/cxs/hpe/ACJobSite/jobs",
     "url_base": "https://hpe.wd5.myworkdayjobs.com/en-US/ACJobSite"},

    # Dell and Walmart: tenant URLs found the same way, but their careers pages themselves
    # return 500/422 independent of our request pattern — genuinely broken guesses (wrong
    # site identifier, most likely), not a rate issue. Would need the correct site name
    # re-derived, not just retried, regardless of the cooldown question above.
]

_RESOLVED_PATH = os.path.join(os.path.dirname(__file__), "companies_resolved.json")


def _load_resolved() -> list[dict]:
    if not os.path.exists(_RESOLVED_PATH):
        return []
    with open(_RESOLVED_PATH) as f:
        hits = json.load(f)

    high_confidence = [h for h in hits if h.get("confidence") == "high"]

    # A company can resolve on more than one platform / slug variant — keep the first
    # (name, platform) pair only, to avoid double-registering the same company twice under
    # the same adapter with two slug spellings.
    seen = set()
    resolved = []
    for hit in high_confidence:
        key = (hit["name"], hit["platform"])
        if key in seen:
            continue
        seen.add(key)
        resolved.append({"name": hit["name"], "platform": hit["platform"], "slug": hit["slug"]})
    return resolved


def _load_needs_review() -> list[dict]:
    if not os.path.exists(_RESOLVED_PATH):
        return []
    with open(_RESOLVED_PATH) as f:
        hits = json.load(f)
    return [h for h in hits if h.get("confidence") == "low"]


RESOLVED_COMPANIES = _load_resolved()
NEEDS_REVIEW = _load_needs_review()

# Merge, de-duping by (name, platform) with SEED_COMPANIES taking priority.
_seed_keys = {(c["name"], c["platform"]) for c in SEED_COMPANIES}
COMPANIES = SEED_COMPANIES + [c for c in RESOLVED_COMPANIES if (c["name"], c["platform"]) not in _seed_keys]
