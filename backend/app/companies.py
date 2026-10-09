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
    # Second review batch (2026-10-09), same live-verification discipline against the Round 4
    # NEEDS_REVIEW candidates.
    {"name": "Intuitive Surgical", "platform": "smartrecruiters", "slug": "intuitive"},  # 100 postings, "Field Service Engineer" fits their real business
    {"name": "Observe.AI", "platform": "greenhouse", "slug": "observeai"},  # confirmed via absolute_url pointing to observe.ai; renamed from "Observe.AI India"
    {"name": "Paytm", "platform": "lever", "slug": "paytm"},  # 182 postings — clearly their main corporate board, not just the First Games subsidiary; renamed from "Paytm First Games"
    {"name": "Glance", "platform": "greenhouse", "slug": "glance"},  # 36 postings, thematically fitting (AI Governance Specialist etc.); renamed from "Glance InMobi"
    # Third review batch (2026-10-09), Round 5 NEEDS_REVIEW — this round skewed toward
    # distinctive coined brand names (Braze, Mixpanel, Webflow, Voodoo...) rather than generic
    # English words, which is a real, lower collision risk, not just a hunch — confirmed live
    # per-entry below same as every prior batch.
    {"name": "Amplitude", "platform": "ashby", "slug": "amplitude"},  # 39 postings, real analytics-company roles
    {"name": "Anchorage Digital", "platform": "lever", "slug": "anchorage"},  # "Stablecoin Solutions" role fits their actual business exactly
    {"name": "Apollo.io", "platform": "greenhouse", "slug": "apolloio"},  # posting title literally says "(India)"
    {"name": "Braze", "platform": "greenhouse", "slug": "braze"},  # 337 real postings
    {"name": "Circle", "platform": "ashby", "slug": "circle"},  # 32 postings, consistent with the real stablecoin/crypto company's size
    {"name": "Customer.io", "platform": "greenhouse", "slug": "customerio"},  # "Customer Success Manager" fits their business exactly
    {"name": "Discord", "platform": "greenhouse", "slug": "discord"},  # 49 real postings
    {"name": "Gemini Trust", "platform": "greenhouse", "slug": "gemini"},  # 35 postings, consistent with the real crypto exchange's size
    {"name": "Iterable", "platform": "ashby", "slug": "iterable"},  # real email-marketing-platform roles
    {"name": "Knock", "platform": "ashby", "slug": "knock"},  # "Engineering Manager, Platform" fits the notifications-infra company; the greenhouse/knock board looked like a different, unrelated "Knock" — not registered
    {"name": "LaunchDarkly", "platform": "greenhouse", "slug": "launchdarkly"},  # 56 postings, consistent with the real feature-flag company's size
    {"name": "Mixpanel", "platform": "greenhouse", "slug": "mixpanel"},  # 51 real postings
    {"name": "Twitch", "platform": "greenhouse", "slug": "twitch"},  # 50 real postings
    {"name": "Webflow", "platform": "ashby", "slug": "webflow"},  # real postings on both ashby and greenhouse — kept both rather than guessing which is current
    {"name": "Webflow", "platform": "greenhouse", "slug": "webflow"},
    {"name": "Voodoo", "platform": "ashby", "slug": "voodoo"},  # 124 postings, "Game Developer - Puzzle Games" fits the real mobile-games publisher exactly
    {"name": "Oyster HR", "platform": "ashby", "slug": "oyster"},  # a posting literally titled "Oyster Talent Community Sign Up"
    {"name": "Railway", "platform": "ashby", "slug": "railway"},  # consistent real-tech-role pattern (Full-Stack/Infrastructure/Growth Content Engineer) fitting the dev platform
    {"name": "Slice", "platform": "greenhouse", "slug": "slice"},  # absolute_url points to slice.careers
    {"name": "Tiger Analytics", "platform": "ashby", "slug": "tiger"},  # consistent real-tech-role pattern (Infrastructure/Frontend Engineer, Director of Platform Engineering)
    {"name": "Vogo", "platform": "lever", "slug": "vogo"},  # "Senior Backend Engineer" among real postings, fits the mobility startup
    # Fourth review batch (2026-10-09), Round 6 NEEDS_REVIEW.
    {"name": "Attentive", "platform": "greenhouse", "slug": "attentive"},  # 28 real postings incl. "Director of Engineering, Cloud Platform"
    {"name": "Finix", "platform": "lever", "slug": "finix"},  # "GTM Engineer" fits the real payments-infra company
    {"name": "Rebuy Engine", "platform": "ashby", "slug": "rebuy"},  # "Staff Software Engineer" fits the real e-commerce personalization startup
    {"name": "Recharge", "platform": "ashby", "slug": "recharge"},  # "Senior Data Engineer" fits the real subscription-billing company
    {"name": "Socket Security", "platform": "ashby", "slug": "socket"},  # 28 real postings
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

    # Batch found via a dedicated research pass (2026-10-09) targeting large-GCC candidates
    # not yet covered. Every entry here was independently re-verified against the REAL
    # adapter (not just trusted from the research pass) before being added — robots.txt +
    # sitemap existence confirmed live, and workday_sitemap.scrape() run against each to
    # confirm it actually returns real current job data, not just a resolvable URL. Two
    # (Unilever, Kimberly-Clark) needed a site-id correction: the first guess wasn't wrong
    # exactly, just one of several sitemaps a single Workday tenant can declare in robots.txt
    # (a large company often runs multiple distinct "sites" — early careers, experienced
    # professionals, regional, LinkedIn-feed-only, etc. — under one tenant domain); this
    # doesn't actually matter for OUR adapter, since it reads every Sitemap: line robots.txt
    # declares, not just the one named in url_base — url_base's site-id suffix only needs to
    # share the tenant's domain, which both did. Stryker, Unilever, and Coca-Cola currently
    # show 0 matching jobs (real sitemap, real company, just no current posting that passes
    # the relevance/seniority filters) — kept registered per the standing principle that a
    # correctly-identified company having zero current openings isn't a reason to exclude it.
    {"name": "Johnson & Johnson", "platform": "workday_sitemap",
     "url_base": "https://jj.wd5.myworkdayjobs.com/JJ"},
    {"name": "Merck (MSD)", "platform": "workday_sitemap",
     "url_base": "https://msd.wd5.myworkdayjobs.com/SearchJobs"},
    {"name": "Bristol Myers Squibb", "platform": "workday_sitemap",
     "url_base": "https://bristolmyerssquibb.wd5.myworkdayjobs.com/BMS"},
    {"name": "Abbott Laboratories", "platform": "workday_sitemap",
     "url_base": "https://abbott.wd5.myworkdayjobs.com/abbottcareers"},
    {"name": "Stryker", "platform": "workday_sitemap",
     "url_base": "https://stryker.wd1.myworkdayjobs.com/StrykerCareers"},
    {"name": "Rockwell Automation", "platform": "workday_sitemap",
     "url_base": "https://rockwellautomation.wd1.myworkdayjobs.com/External_Rockwell_Automation"},
    {"name": "Unilever", "platform": "workday_sitemap",
     "url_base": "https://unilever.wd3.myworkdayjobs.com/Unilever_Experienced_Professionals"},
    {"name": "Kimberly-Clark", "platform": "workday_sitemap",
     "url_base": "https://kimberlyclark.wd1.myworkdayjobs.com/GLOBAL"},
    {"name": "Coca-Cola Company", "platform": "workday_sitemap",
     "url_base": "https://coke.wd1.myworkdayjobs.com/coca-cola-careers"},

    # Fourth Workday batch (2026-10-09) — same independent re-verification discipline: each
    # one run through the real adapter before being trusted, not just taken from research.
    # Verifying this batch also surfaced a real bug: `jobLocation` text was never unescaped at
    # all (unlike `title`, fixed in an earlier commit), and at least one tenant (Baxter)
    # double-encodes entities — "BANGALORE_R&D" arrived as "BANGALORE_R&amp;amp;D." Fixed by
    # making unescape_text() always unescape twice (a no-op on already-clean text) and wiring
    # it into the location field too, not just title.
    {"name": "Becton Dickinson (BD)", "platform": "workday_sitemap",
     "url_base": "https://bdx.wd1.myworkdayjobs.com/EXTERNAL_CAREER_SITE_INDIA"},
    {"name": "Baxter International", "platform": "workday_sitemap",
     "url_base": "https://baxter.wd1.myworkdayjobs.com/baxter"},
    {"name": "Johnson Controls", "platform": "workday_sitemap",
     "url_base": "https://jci.wd5.myworkdayjobs.com/JCI"},
    {"name": "Otis Worldwide", "platform": "workday_sitemap",
     "url_base": "https://otis.wd504.myworkdayjobs.com/REC_Ext_Gateway"},  # 0 current matching jobs, real confirmed tenant — kept per standing principle
    {"name": "Carrier Global", "platform": "workday_sitemap",
     "url_base": "https://carrier.wd5.myworkdayjobs.com/jobs"},
    {"name": "Illumina", "platform": "workday_sitemap",
     "url_base": "https://illumina.wd1.myworkdayjobs.com/illumina-careers"},
    {"name": "Agilent Technologies", "platform": "workday_sitemap",
     "url_base": "https://agilent.wd5.myworkdayjobs.com/Agilent_Careers"},
    {"name": "Dexcom", "platform": "workday_sitemap",
     "url_base": "https://dexcom.wd1.myworkdayjobs.com/Dexcom"},
    {"name": "PTC Inc", "platform": "workday_sitemap",
     "url_base": "https://ptc.wd1.myworkdayjobs.com/PTC"},
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
    # Second review batch (2026-10-09).
    ("Charles River Associates", "greenhouse", "charles"),  # identical board/job as the already-denylisted Charles Schwab — "charles" resolves to a third, unrelated company
    ("Blue Tokai Coffee", "lever", "blue"),  # identical board/job as the already-denylisted Blue Yonder — "blue" resolves to a third, unrelated company
    ("Novo Nordisk", "ashby", "novo"),  # an 11-job Ashby board is implausible for a 60,000+ employee pharma company; a different, smaller "Novo"
    ("Fireworks AI", "ashby", "fireworks"),  # "Financial Reporting Manager" among 85 jobs doesn't fit a small AI inference startup; a different, larger "Fireworks"
    ("Allegro MicroSystems", "greenhouse", "allegro"),  # 0 jobs
    ("Allegro MicroSystems", "smartrecruiters", "allegro"),  # board's own listing says "we have switched to SAP Harmony - SmartRecruiters will be decommissioned" — confirmed real but abandoned
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

    # Dedupe by (platform, slug), not (name, platform) — slug+platform is the actual
    # uniqueness constraint (it determines the real underlying data source and therefore every
    # job's id), not the display name. Found live: "Observe.AI" and "Observe AI" are two
    # different candidate-list entries for the same company that both resolved to
    # greenhouse/observeai — different NAME strings, so a name-keyed dedupe let both through,
    # registering the same board twice and producing a literal duplicate job id in the live
    # feed (caught by the client-side/Workday dedup safety nets, but shouldn't have happened
    # in the first place). With 1500+ curated candidate names, near-duplicate entries for the
    # same company are inevitable — this makes the dedup structurally immune to that instead
    # of relying on catching each one by hand.
    seen = set()
    resolved = []
    for hit in high_confidence:
        key = (hit["platform"], hit["slug"])
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

# Merge, de-duping by (platform, data-source-key) — same reasoning as _load_resolved()'s own
# dedupe above — with SEED_COMPANIES/WORKDAY_COMPANIES taking priority (their curated
# name/rename wins over whatever the raw auto-resolved hit was called). Workday entries key on
# `url_base` instead of `slug` (see WORKDAY_COMPANIES' own comment on why `slug` there is
# vestigial), so the key has to fall back across both fields.
def _source_key(c: dict) -> tuple:
    return (c["platform"], c.get("slug") or c.get("url_base"))


_priority = SEED_COMPANIES + WORKDAY_COMPANIES
_priority_keys = {_source_key(c) for c in _priority}
COMPANIES = _priority + [c for c in RESOLVED_COMPANIES if _source_key(c) not in _priority_keys]
