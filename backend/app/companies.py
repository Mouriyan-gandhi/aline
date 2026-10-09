"""
The company registry. Three sources, merged:
1. SEED_COMPANIES — hand-verified during Milestone 0, kept as a guaranteed-good fallback.
2. WORKDAY_COMPANIES — Workday tenants found via web search (site:myworkdayjobs.com),
   scraped through the sitemap + JobPosting JSON-LD method (app/adapters/workday_sitemap.py),
   NOT the old blocked internal search API (app/adapters/workday.py, kept but unused — see
   its module docstring for the full story of why).
3. companies_resolved.json — the slug_prober's output: real companies that, at probe time,
   actually had live India-filtered-relevant postings on one of the 4 slug-guessable ATS
   platforms (Greenhouse/Lever/Ashby/SmartRecruiters).

Only "high" confidence hits from companies_resolved.json are loaded automatically — "low"
confidence (single generic-word slug guesses, e.g. "Pine" for "Pine Labs") are excluded from
the live registry and kept in NEEDS_REVIEW for manual confirmation, since a generic slug can
collide with an unrelated company on the same platform.
"""
import json
import os

SEED_COMPANIES = [
    {"name": "Databricks", "platform": "greenhouse", "slug": "databricks"},
    {"name": "Twilio", "platform": "greenhouse", "slug": "twilio"},
    {"name": "Zeta", "platform": "lever", "slug": "zeta"},
    {"name": "Harvey", "platform": "ashby", "slug": "harvey"},
    # Amazon — genuinely public search.json API, see adapters/amazon.py for the full
    # investigation of this and the other 4 "mega-cap" custom career platforms (2026-10-08).
    {"name": "Amazon", "platform": "amazon", "slug": "amazon"},
    # The next 4 came out of a manual review of 33 single-word-slug NEEDS_REVIEW candidates
    # (2026-10-09) — slug_prober correctly flagged all of them "low confidence" (the collision
    # risk a bare single word like "capital"/"general"/"pure" carries), and live-checking each
    # one found the overwhelming majority genuinely WERE the wrong company (see
    # _CONFIRMED_BAD_MATCHES below) — these 4 are the ones with strong positive evidence.
    {"name": "Sarvam AI", "platform": "ashby", "slug": "sarvam"},  # confirmed via "Chanakya" — a Sarvam-specific product codename, not a generic title
    {"name": "Swiggy", "platform": "smartrecruiters", "slug": "swiggy"},  # 100 real-looking postings; renamed from "Swiggy Instamart" since this is their main board
    {"name": "Make", "platform": "greenhouse", "slug": "make"},  # confirmed via absolute_url pointing to make.com; renamed from "Make Integromat" (their old name)
    {"name": "Plaid", "platform": "ashby", "slug": "plaid"},  # 121 postings, consistent with Plaid's real size; renamed from "Plaid India" since this looks like their global board, not an India-specific one
]

# Workday tenants, verified via the sitemap + JobPosting JSON-LD method (2026-10-08) — each
# one found through `site:myworkdayjobs.com "{company}"` search, 3-5 confirmed live with real
# India postings via the real adapter (Adobe, Cisco, PayPal, Cadence), the rest registered on
# the strength of the same, consistently-working underlying mechanism (every Workday tenant
# publishes a robots.txt-linked sitemap — this isn't a per-company configuration that varies,
# it's standard platform behavior, confirmed across every tenant checked so far).
#
# `slug` here is unused by workday_sitemap.scrape() (only `url_base` matters) but kept
# populated with the old internal-API URL for reference / in case workday.py is ever revisited.
WORKDAY_COMPANIES = [
    {"name": "NVIDIA", "platform": "workday_sitemap",
     "url_base": "https://nvidia.wd5.myworkdayjobs.com/en-US/NVIDIAExternalCareerSite"},
    {"name": "Mastercard", "platform": "workday_sitemap",
     "url_base": "https://mastercard.wd1.myworkdayjobs.com/en-US/CorporateCareers"},
    {"name": "Adobe", "platform": "workday_sitemap",
     "url_base": "https://adobe.wd5.myworkdayjobs.com/en-US/external_experienced"},
    {"name": "Qualcomm", "platform": "workday_sitemap",
     "url_base": "https://qualcomm.wd12.myworkdayjobs.com/en-US/External"},
    {"name": "Autodesk", "platform": "workday_sitemap",
     "url_base": "https://autodesk.wd1.myworkdayjobs.com/en-US/Ext"},
    {"name": "Salesforce", "platform": "workday_sitemap",
     "url_base": "https://salesforce.wd12.myworkdayjobs.com/en-US/External_Career_Site"},
    {"name": "Wells Fargo", "platform": "workday_sitemap",
     "url_base": "https://wf.wd1.myworkdayjobs.com/en-US/WellsFargoJobs"},
    {"name": "Morgan Stanley", "platform": "workday_sitemap",
     "url_base": "https://ms.wd5.myworkdayjobs.com/en-US/External"},
    {"name": "Deutsche Bank", "platform": "workday_sitemap",
     "url_base": "https://db.wd3.myworkdayjobs.com/en-US/DBWebsite"},
    {"name": "Target", "platform": "workday_sitemap",
     "url_base": "https://target.wd5.myworkdayjobs.com/en-US/targetcareers"},
    {"name": "Philips", "platform": "workday_sitemap",
     "url_base": "https://philips.wd3.myworkdayjobs.com/en-US/jobs-and-careers"},
    {"name": "Hewlett Packard Enterprise", "platform": "workday_sitemap",
     "url_base": "https://hpe.wd5.myworkdayjobs.com/en-US/ACJobSite"},
    {"name": "Cisco", "platform": "workday_sitemap",
     "url_base": "https://cisco.wd5.myworkdayjobs.com/en-US/Cisco_Careers"},
    {"name": "Capital One", "platform": "workday_sitemap",
     "url_base": "https://capitalone.wd12.myworkdayjobs.com/en-US/Capital_One"},
    {"name": "PNC", "platform": "workday_sitemap",
     "url_base": "https://pnc.wd5.myworkdayjobs.com/en-US/External"},
    {"name": "Elevance Health", "platform": "workday_sitemap",
     "url_base": "https://elevancehealth.wd1.myworkdayjobs.com/en-US/carelonglobal_in"},
    {"name": "Trimble", "platform": "workday_sitemap",
     "url_base": "https://trimble.wd1.myworkdayjobs.com/en-US/TrimbleCareers"},
    {"name": "Wellington", "platform": "workday_sitemap",
     "url_base": "https://wellington.wd5.myworkdayjobs.com/en-US/External"},
    {"name": "PayPal", "platform": "workday_sitemap",
     "url_base": "https://paypal.wd1.myworkdayjobs.com/en-US/jobs"},
    {"name": "Micron", "platform": "workday_sitemap",
     "url_base": "https://micron.wd1.myworkdayjobs.com/en-US/External"},
    {"name": "Broadcom", "platform": "workday_sitemap",
     "url_base": "https://broadcom.wd1.myworkdayjobs.com/en-US/External_Career"},
    {"name": "Alteryx", "platform": "workday_sitemap",
     "url_base": "https://alteryx.wd5.myworkdayjobs.com/en-US/AlteryxCareers"},
    {"name": "Cadence", "platform": "workday_sitemap",
     "url_base": "https://cadence.wd1.myworkdayjobs.com/en-US/External_Careers"},
    {"name": "Citi", "platform": "workday_sitemap",
     "url_base": "https://citi.wd5.myworkdayjobs.com/en-US/2"},
    {"name": "Visa", "platform": "workday_sitemap",
     "url_base": "https://visa.wd5.myworkdayjobs.com/en-US/Visa"},
    {"name": "Nationwide", "platform": "workday_sitemap",
     "url_base": "https://nationwide.wd1.myworkdayjobs.com/en-US/Nationwide_Career_India"},
    {"name": "Nasdaq", "platform": "workday_sitemap",
     "url_base": "https://nasdaq.wd1.myworkdayjobs.com/en-US/Global_External_Site"},
    {"name": "Samsung", "platform": "workday_sitemap",
     "url_base": "https://sec.wd3.myworkdayjobs.com/en-US/Samsung_Careers"},
    {"name": "Prudential", "platform": "workday_sitemap",
     "url_base": "https://prudential.wd3.myworkdayjobs.com/en-US/prudential"},
    {"name": "Comcast", "platform": "workday_sitemap",
     "url_base": "https://comcast.wd5.myworkdayjobs.com/en-US/Comcast_Careers"},
    {"name": "Cigna", "platform": "workday_sitemap",
     "url_base": "https://cigna.wd5.myworkdayjobs.com/en-US/cignacareers"},
    {"name": "AVEVA", "platform": "workday_sitemap",
     "url_base": "https://aveva.wd3.myworkdayjobs.com/en-US/AVEVA_careers"},
    {"name": "Hitachi", "platform": "workday_sitemap",
     "url_base": "https://hitachi.wd1.myworkdayjobs.com/en-US/hitachi"},
    {"name": "S&P Global", "platform": "workday_sitemap",
     "url_base": "https://spgi.wd5.myworkdayjobs.com/en-US/spgi_careers"},
    {"name": "Motorola Solutions", "platform": "workday_sitemap",
     "url_base": "https://motorolasolutions.wd5.myworkdayjobs.com/en-US/careers"},
    {"name": "Intel", "platform": "workday_sitemap",
     "url_base": "https://intel.wd1.myworkdayjobs.com/en-US/External"},
    {"name": "Boeing", "platform": "workday_sitemap",
     "url_base": "https://boeing.wd1.myworkdayjobs.com/en-US/EXTERNAL_CAREERS"},
    {"name": "GE", "platform": "workday_sitemap",
     "url_base": "https://ge.wd5.myworkdayjobs.com/en-US/GE_ExternalSite"},
    {"name": "GE HealthCare", "platform": "workday_sitemap",
     "url_base": "https://gehc.wd5.myworkdayjobs.com/en-US/GEHC_ExternalSite"},
    {"name": "GE Aerospace", "platform": "workday_sitemap",
     "url_base": "https://geaerospace.wd5.myworkdayjobs.com/en-US/GE_ExternalSite"},

    # Round 2 (2026-10-08) — found via targeted sweep of the three categories that showed the
    # strongest Workday hit rate: pharma/medtech (near 100% hit rate), US financial GCCs, and
    # semiconductor/hardware. Each confirmed with real India-location evidence in search
    # results before being added, same standard as round 1.
    {"name": "Barclays", "platform": "workday_sitemap",
     "url_base": "https://barclays.wd3.myworkdayjobs.com/en-US/External_Career_Site_Barclays"},
    {"name": "CrowdStrike", "platform": "workday_sitemap",
     "url_base": "https://crowdstrike.wd5.myworkdayjobs.com/en-US/crowdstrikecareers"},
    {"name": "Fidelity Investments", "platform": "workday_sitemap",
     "url_base": "https://fmr.wd1.myworkdayjobs.com/en-US/FidelityCareers"},
    {"name": "Pfizer", "platform": "workday_sitemap",
     "url_base": "https://pfizer.wd1.myworkdayjobs.com/en-US/PfizerCareers"},
    {"name": "Novartis", "platform": "workday_sitemap",
     "url_base": "https://novartis.wd3.myworkdayjobs.com/en-US/Novartis_Careers"},
    {"name": "AstraZeneca", "platform": "workday_sitemap",
     "url_base": "https://astrazeneca.wd3.myworkdayjobs.com/en-US/broadbean_external"},
    {"name": "Medtronic", "platform": "workday_sitemap",
     "url_base": "https://medtronic.wd1.myworkdayjobs.com/en-US/MedtronicCareers"},
    {"name": "Analog Devices", "platform": "workday_sitemap",
     "url_base": "https://analogdevices.wd1.myworkdayjobs.com/en-US/External"},
    {"name": "Lloyds Technology Centre", "platform": "workday_sitemap",
     "url_base": "https://lbg.wd3.myworkdayjobs.com/en-US/Lloyds_Technology_Centre"},
    {"name": "CDK Global", "platform": "workday_sitemap",
     "url_base": "https://cdk.wd1.myworkdayjobs.com/en-US/CDK"},
    {"name": "Danaher", "platform": "workday_sitemap",
     "url_base": "https://danaher.wd1.myworkdayjobs.com/en-US/DanaherJobs"},
    {"name": "GSK", "platform": "workday_sitemap",
     "url_base": "https://gsk.wd5.myworkdayjobs.com/en-US/GSKCareers"},
    {"name": "Sanofi", "platform": "workday_sitemap",
     "url_base": "https://sanofi.wd3.myworkdayjobs.com/en-US/SanofiCareers"},
    {"name": "Amgen", "platform": "workday_sitemap",
     "url_base": "https://amgen.wd1.myworkdayjobs.com/en-US/Careers"},
    {"name": "Eli Lilly", "platform": "workday_sitemap",
     "url_base": "https://lilly.wd5.myworkdayjobs.com/en-US/CMP"},
    {"name": "Northern Trust", "platform": "workday_sitemap",
     "url_base": "https://ntrs.wd1.myworkdayjobs.com/en-US/northerntrust"},
    {"name": "Marvell Technology", "platform": "workday_sitemap",
     "url_base": "https://marvell.wd1.myworkdayjobs.com/en-US/MarvellCareers"},
    {"name": "NXP Semiconductors", "platform": "workday_sitemap",
     "url_base": "https://nxp.wd3.myworkdayjobs.com/en-US/careers"},
    {"name": "Synchrony", "platform": "workday_sitemap",
     "url_base": "https://synchronyfinancial.wd5.myworkdayjobs.com/en-US/careers"},
    {"name": "Applied Materials", "platform": "workday_sitemap",
     "url_base": "https://amat.wd1.myworkdayjobs.com/en-US/External"},
    {"name": "Allstate", "platform": "workday_sitemap",
     "url_base": "https://allstate.wd5.myworkdayjobs.com/en-US/allstate_careers"},
    {"name": "CME Group", "platform": "workday_sitemap",
     "url_base": "https://cmegroup.wd1.myworkdayjobs.com/en-US/cme_careers"},
    {"name": "Microchip Technology", "platform": "workday_sitemap",
     "url_base": "https://microchiphr.wd5.myworkdayjobs.com/en-US/External"},
    {"name": "Takeda", "platform": "workday_sitemap",
     "url_base": "https://takeda.wd3.myworkdayjobs.com/en-US/External"},

    # Dell and Walmart: tenant URLs found the same way, but their careers pages themselves
    # return 500/422 independent of request pattern — genuinely broken guesses (wrong site
    # identifier, most likely), not a rate issue. Would need the correct site name re-derived.
]

_RESOLVED_PATH = os.path.join(os.path.dirname(__file__), "companies_resolved.json")

# Permanent denylist for confirmed slug collisions — found live: "TCS" auto-resolved to a
# Greenhouse board at slug "tcs" that is actually a UK home-healthcare nursing provider
# ("Community Adult Nurse," "Complex Care" postings), nothing to do with Tata Consultancy
# Services. The company name was short enough (3-letter acronym) that the prober's
# multi-word-name "low confidence" check never triggered — it only downgrades confidence for
# candidates with more than one word, not for short single-word/acronym names, which turned
# out to be an equally real collision risk. This denylist is a permanent backstop so a
# confirmed-bad match can never silently re-enter the registry, even after re-running the
# prober or regenerating companies_resolved.json from scratch. See slug_prober.py's
# `_SHORT_NAME_LOW_CONFIDENCE_LENGTH` for the actual heuristic fix going forward.
_CONFIRMED_BAD_MATCHES = {
    ("TCS", "greenhouse", "tcs"),  # verified live: unrelated UK nursing company
    # Batch from the 2026-10-09 manual review of 33 single-word-slug NEEDS_REVIEW candidates
    # — each confirmed live to be a different, unrelated company than the intended target
    # (wrong domain in absolute_url, implausible job content for the company's real size, or
    # an outright duplicate slug collision between two different intended targets — "capital"
    # and "general" each matched two different companies on this list to the identical board).
    ("Together AI", "smartrecruiters", "together"),  # mortgage/lending company, not the AI infra company
    ("Stage OTT", "greenhouse", "stage"),  # resolves to KKR (private equity), not Stage OTT
    ("Charles Schwab", "greenhouse", "charles"),  # small EU company, not the US brokerage
    ("National Grid", "greenhouse", "national"),  # too few/generic postings for a utility this size
    ("Disney Hotstar", "greenhouse", "disney"),  # only a placeholder "MASTER TEMPLATE" posting
    ("Capital One", "lever", "capital"),  # collided with Capital Float on the identical board — neither is real
    ("Capital Float", "lever", "capital"),
    ("Eli Lilly", "ashby", "eli"),  # 5-job Ashby board implausible for a company this size
    ("US Bancorp", "greenhouse", "us"),  # absolute_url points to itelinternational.com
    ("Help Scout", "greenhouse", "help"),  # "Dispatch" role suggests logistics, not a support-SaaS company
    ("Lattice Semiconductor", "greenhouse", "lattice"),  # lattice.com is the HR-software company, not the chipmaker
    ("Applied Materials", "ashby", "applied"),  # implausible for a semiconductor-equipment giant to run Ashby
    ("General Motors", "greenhouse", "general"),  # collided with General Dynamics on the identical board
    ("General Dynamics", "greenhouse", "general"),
    ("Analog Devices", "ashby", "analog"),  # implausible size/platform fit; "Senior iOS Engineer" doesn't fit either
    ("Parker Hannifin", "ashby", "parker"),  # implausible for an industrial manufacturing giant
    ("New Relic", "greenhouse", "new"),  # single generic-titled job, too thin to trust
    ("Pure Storage", "ashby", "pure"),  # "Founding GTM Leader" — early-stage-startup language, not a 5000-person public company
}


def _load_resolved() -> list[dict]:
    if not os.path.exists(_RESOLVED_PATH):
        return []
    with open(_RESOLVED_PATH) as f:
        hits = json.load(f)

    high_confidence = [
        h for h in hits
        if h.get("confidence") == "high"
        and (h["name"], h["platform"], h["slug"]) not in _CONFIRMED_BAD_MATCHES
    ]

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

# Merge, de-duping by (name, platform) with SEED_COMPANIES/WORKDAY_COMPANIES taking priority.
_priority = SEED_COMPANIES + WORKDAY_COMPANIES
_priority_keys = {(c["name"], c["platform"]) for c in _priority}
COMPANIES = _priority + [c for c in RESOLVED_COMPANIES if (c["name"], c["platform"]) not in _priority_keys]
