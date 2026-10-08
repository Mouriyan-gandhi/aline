"""
Deterministic ingestion filters — no AI involved, per the plan's AI usage map.

Ported and extended from old_version/data/companies.js (TARGET_KEYWORDS/TARGET_ROLES),
plus the two filters added at the plan stage: India location, and one-sided seniority
exclusion (only drop postings that read as ~10+ years / senior-staff-and-up).
"""
import re

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
    "principal", "distinguished engineer",
    "director", "vp ", "vice president", "head of", "chief ", "svp", "executive",
    "senior director", "group manager", "engineering manager",
]

# "staff" as a standalone word (Staff Engineer, Staff Software Engineer, Staff PM, ...) —
# a substring check on "staff engineer" alone misses titles with a word in between.
_STAFF_WORD_PATTERN = re.compile(r"\bstaff\b", re.IGNORECASE)

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
    lowered = (slug_text or "").lower()
    if any(sig in lowered for sig in SENIOR_EXCLUDE_TITLE_SIGNALS):
        return True
    if _STAFF_WORD_PATTERN.search(lowered):
        return True
    for match in _SLUG_YEARS_PATTERN.finditer(slug_text or ""):
        if int(match.group(1)) >= 8:
            return True
    return False


def is_relevant_job(title: str, department: str = "") -> bool:
    text = f"{title} {department}".lower()
    has_keyword = any(kw in text for kw in TARGET_KEYWORDS)
    has_role = any(role in text for role in TARGET_ROLES)
    return has_keyword or has_role


def is_india_location(location: str) -> bool:
    if not location:
        return False
    text = location.lower()
    return any(sig in text for sig in INDIA_LOCATION_SIGNALS)


def is_senior_excluded(title: str, description: str = "") -> bool:
    """One-sided: True only for postings that read as ~10+ years / senior-staff-and-up."""
    title_lower = (title or "").lower()
    if any(sig in title_lower for sig in SENIOR_EXCLUDE_TITLE_SIGNALS):
        return True
    if _STAFF_WORD_PATTERN.search(title_lower):
        return True
    for match in _YEARS_PATTERN.finditer(description or ""):
        years = int(match.group(1))
        if years >= 8:
            return True
    return False


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
    lowered = text.lower()
    return [skill for skill in SKILL_VOCABULARY if skill.lower() in lowered]
