"""
Deterministic ingestion filters — no AI involved, per the plan's AI usage map.

Ported and extended from old_version/data/companies.js (TARGET_KEYWORDS/TARGET_ROLES),
plus the two filters added at the plan stage: India location, and one-sided seniority
exclusion (only drop postings that read as ~10+ years / senior-staff-and-up).
"""
import re
from typing import Optional

# Keywords indicating an internship / early-career / student-facing posting.
TARGET_KEYWORDS = [
    "intern", "internship", "new grad", "new-grad", "university grad",
    "entry level", "entry-level", "junior", "associate", "campus", "graduate",
    "university", "student", "co-op", "coop", "apprentice", "apprenticeship",
    "early career", "2026", "2027", "2028",
]

# Role categories under the single "IT/software/AI and adjacent" umbrella (spec section 3).
# Broadened 2026-10-08 per explicit direction: "all engineering roles in computer science and
# software industry — everything that comes in software" — the original list was too narrow
# on real title phrasing (e.g. Adobe/Cisco postings titled "Computer Scientist", "Enterprise
# Architect", "Data Science Engineer" weren't matching any of it).
TARGET_ROLES = [
    "software engineer", "software developer", "software development",
    "swe", "backend", "frontend", "full stack", "fullstack", "full-stack",
    "machine learning", "ml engineer", "ai engineer", "artificial intelligence",
    "data scientist", "data engineer", "data analyst", "data science",
    "research engineer", "research scientist", "applied scientist", "computer scientist",
    "computer science", "computer vision", "nlp", "natural language processing",
    "deep learning", "generative ai", "llm", "large language model",
    "product manager", "program manager", "technical program manager",
    "infrastructure", "platform engineer", "devops", "site reliability", "sre",
    "security engineer", "application security", "cybersecurity", "cyber security",
    "mobile engineer", "mobile developer", "ios engineer", "ios developer",
    "android engineer", "android developer", "robotics", "systems engineer",
    "qa engineer", "test engineer", "sdet", "cloud engineer", "cloud architect",
    "solutions architect", "solution architect", "enterprise architect",
    "technical architect", "database engineer", "database administrator", "dba",
    "network engineer", "embedded engineer", "embedded software", "firmware engineer",
    "web developer", "ui engineer", "ux engineer", "frontend developer",
    "computer engineer", "electrical engineer", "hardware engineer",
    "verification engineer", "design engineer", "asic", "fpga",
    "blockchain engineer", "game developer", "game engineer",
    "automation engineer", "release engineer", "build engineer",
    "it engineer", "systems administrator", "technical lead", "engineering manager",
    "developer", "engineer", "programmer", "developer advocate",
]

# India office / location signals. Deliberately broad — city names plus "india" itself.
INDIA_LOCATION_SIGNALS = [
    "india", "bengaluru", "bangalore", "hyderabad", "pune", "gurugram", "gurgaon",
    "mumbai", "chennai", "noida", "delhi", "ncr", "kolkata", "ahmedabad", "kochi",
    "coimbatore", "thiruvananthapuram", "trivandrum", "indore", "jaipur", "navi mumbai",
]

# One-sided exclusion: only drop postings that read as senior-staff-and-up (~10+ years).
# Deliberately NOT excluding plain "senior" — a Senior SWE role is often 4-6 years, which
# still belongs in the pool per the plan (ingestion filter is one-sided, matching engine
# judges real fit later).
SENIOR_EXCLUDE_TITLE_SIGNALS = [
    "principal", "distinguished engineer", "staff",
    "director", "vp", "vice president", "head of", "chief", "svp", "executive",
    "senior director", "group manager", "engineering manager",
]


# ---------------------------------------------------------------------------------------
# Shared word-boundary-safe phrase matching — used by every filter function below.
#
# Found live, twice, in two different functions, before this was unified: plain
# `phrase in text` substring checks matched "C" inside "Commerce"/"Center"/"coordinate"
# (extract_skills, via the Amazon adapter) and separately matched "llm" inside
# "Fu[llm]ent" — i.e. a plain Amazon *warehouse fulfillment* job got flagged as an LLM/AI
# role (is_relevant_job, via the same adapter). Same root cause, two call sites — so this is
# now ONE shared, properly-tested utility instead of scattered one-off regexes, to make sure
# a third instance of this bug class can't quietly reappear in a new function later.
# ---------------------------------------------------------------------------------------

_PHRASE_PATTERN_CACHE: dict[str, re.Pattern] = {}


def _phrase_pattern(phrase: str) -> re.Pattern:
    """Word-boundary-safe pattern for one phrase. \\b alone doesn't work cleanly for
    phrases ending in a non-word character (e.g. "C++", "C#") — \\b only fires at a
    word/non-word transition, and a symbol followed by whitespace/end-of-string is
    non-word-to-non-word, no transition, so "C++" would only ever match its "C" prefix and
    never match as itself. A negative lookahead for "not immediately followed by another
    alphanumeric character" fixes this for every case \\b handles plus this one.

    That lookahead alone still isn't enough for short phrases that are themselves a PREFIX
    of a longer tech term differing only by a trailing symbol — found live: a JD's "Java,
    Scala, C++, or similar" credited both "C++" (correct) AND "C" (wrong), since "C" followed
    by "+" passes a lookahead that only blocks letters/digits. "+" and "#" are the only two
    symbols that extend a bare letter into a different, unrelated skill name in our own
    vocabulary (C++, C#) — excluding them here is specific to this real collision, not a
    general symbol allowlist."""
    if phrase not in _PHRASE_PATTERN_CACHE:
        _PHRASE_PATTERN_CACHE[phrase] = re.compile(
            r"\b" + re.escape(phrase) + r"(?![a-zA-Z0-9+#])"
        )
    return _PHRASE_PATTERN_CACHE[phrase]


def _contains_any_phrase(text: str, phrases, case_sensitive: bool = False) -> bool:
    haystack = text if case_sensitive else text.lower()
    needles = phrases if case_sensitive else [p.lower() for p in phrases]
    return any(_phrase_pattern(p).search(haystack) for p in needles)


def _matching_phrases(text: str, phrases, case_sensitive: bool = False) -> list:
    haystack = text if case_sensitive else text.lower()
    out = []
    for original in phrases:
        needle = original if case_sensitive else original.lower()
        if _phrase_pattern(needle).search(haystack):
            out.append(original)
    return out


# A handful of SKILL_VOCABULARY entries are ALSO ordinary English words ("Go" the language
# vs. "go" the verb; "Swift" the language vs. "swift" the adjective) — word-boundary matching
# alone can't distinguish these, since both uses are grammatically standalone words. Found
# live: a Business Intelligence job description's ordinary use of "swift" got credited as
# the Swift programming language. Real tech mentions in a JD are almost always properly
# capitalized ("Go", "Swift"); ordinary prose usage is typically lowercase mid-sentence. This
# is a heuristic, not a certainty, but it's directionally correct and costs nothing to apply.
_CASE_SENSITIVE_SKILLS = {"Go", "Swift"}


def is_relevant_job(title: str, department: str = "") -> bool:
    text = f"{title} {department}"
    return (
        _contains_any_phrase(text, TARGET_KEYWORDS)
        or _contains_any_phrase(text, TARGET_ROLES)
    )


def is_india_location(location: str) -> bool:
    if not location:
        return False
    return _contains_any_phrase(location, INDIA_LOCATION_SIGNALS)


# Must be followed by "experience"/"exp" (optionally through a few connector words, e.g.
# "8+ years of professional experience") — a bare "N years" anywhere in a JD is unreliable:
# real postings routinely contain unrelated mentions like "innovating for 40 years" (company
# history) or benefits copy, which a naive years-match incorrectly reads as a seniority
# requirement. Found live: this was silently excluding every single Cisco posting, including
# plain "Software Engineer" with no experience requirement at all, because its JD boilerplate
# mentions Cisco's 40-year history.
_YEARS_PATTERN = re.compile(
    r"(\d{1,2})\s*\+?\s*(?:-\s*\d{1,2}\s*)?\s*years?\s*(?:of\s+)?(?:[a-z]+\s+){0,3}?(?:experience|exp\b)",
    re.IGNORECASE,
)

# For short, terse text ONLY (URL slugs, job-title-length strings) — a bare "N years/yrs" is
# a reliable signal there because there's no prose padding to produce false positives the way
# a full JD description has (company-history blurbs, benefits copy, etc. — see _YEARS_PATTERN
# above). Do NOT use this against real description text.
_SLUG_YEARS_PATTERN = re.compile(r"(\d{1,2})\s*\+?\s*(?:-\s*\d{1,2}\s*)?\s*(?:years?|yrs?)", re.IGNORECASE)


def is_senior_excluded_in_slug(slug_text: str) -> bool:
    """Lightweight seniority check for short slug/title-length text — see _SLUG_YEARS_PATTERN."""
    text = slug_text or ""
    if _contains_any_phrase(text, SENIOR_EXCLUDE_TITLE_SIGNALS):
        return True
    for match in _SLUG_YEARS_PATTERN.finditer(text):
        if int(match.group(1)) >= 8:
            return True
    return False


def is_senior_excluded(title: str, description: str = "") -> bool:
    """One-sided: True only for postings that read as ~10+ years / senior-staff-and-up."""
    if _contains_any_phrase(title or "", SENIOR_EXCLUDE_TITLE_SIGNALS):
        return True
    for match in _YEARS_PATTERN.finditer(description or ""):
        years = int(match.group(1))
        if years >= 8:
            return True
    return False


def extract_min_years_experience(description: str) -> Optional[int]:
    """Surfaces the same number is_senior_excluded already finds and throws away, for the
    client's experience-fit match component (see iOS MatchEngine) — reuses _YEARS_PATTERN
    rather than a second regex, so this stays immune to the exact false-positive class that
    pattern was already hardened against (company-history blurbs, benefits copy). Takes the
    MINIMUM years mentioned across all matches: a posting that opens with "0-2 years" and
    later mentions "5+ years preferred" for a senior variant of the role should read as
    asking for the lower, actually-applicable floor, not the higher aspirational one."""
    years = [int(m.group(1)) for m in _YEARS_PATTERN.finditer(description or "")]
    return min(years) if years else None


# Shared skill vocabulary used for deterministic JD skill extraction (backend) and,
# conceptually, resume skill extraction (on-device, iOS side) — same vocabulary means the
# overlap/match computation on the client is comparing like-for-like strings.
SKILL_VOCABULARY = [
    "Python", "Java", "JavaScript", "TypeScript", "Swift", "Kotlin", "C++", "C", "Go", "Rust",
    "React", "Angular", "Vue", "Node.js", "FastAPI", "Django", "Flask", "Spring", "Spring Boot",
    "AWS", "GCP", "Azure", "Docker", "Kubernetes", "SQL", "PostgreSQL", "MySQL", "MongoDB",
    "Redis", "Machine Learning", "Deep Learning", "TensorFlow", "PyTorch", "NLP",
    "Computer Vision", "Data Structures", "Algorithms", "REST API", "GraphQL", "CI/CD", "Git",
    "Linux", "Android", "iOS", "HTML", "CSS", "SwiftUI", "UIKit", "Spark", "Hadoop", "Kafka",
    "Terraform", "Jenkins", "GitHub Actions", "Microservices", "System Design", "DSA",
    "Pandas", "NumPy", "Scikit-learn", "LLM", "Generative AI", "GraphDB", "Elasticsearch",
]


def extract_skills(text: str) -> list[str]:
    """Deterministic keyword match against SKILL_VOCABULARY — no model call."""
    if not text:
        return []
    case_sensitive = [s for s in SKILL_VOCABULARY if s in _CASE_SENSITIVE_SKILLS]
    case_insensitive = [s for s in SKILL_VOCABULARY if s not in _CASE_SENSITIVE_SKILLS]
    return (
        _matching_phrases(text, case_insensitive, case_sensitive=False)
        + _matching_phrases(text, case_sensitive, case_sensitive=True)
    )
