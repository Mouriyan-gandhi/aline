"""
Derived, display-ready fields for a scraped Job — what the app's job detail screen shows in its
Overview / Requirements / Responsibilities tabs and metadata rows (job type, work mode,
eligible graduates).

Deterministic text parsing over the description each adapter already cleaned (see
adapters/common.py's html_to_text — block-level tags become newlines, so headings and bullets
arrive one per line). No model call: this runs over every job on every cache refresh. When a
posting doesn't state something, the field stays empty rather than guessed — the app shows
"Not specified" / hides the section instead of an invented requirement.
"""
import html
import re
from typing import Optional

from app.recommend import job_level, role_family
from app.schemas import Job

# Heading text (lowercased, trailing ":" stripped) -> which section the lines under it feed.
# Checked as "starts with" so "Minimum qualifications for this role" still lands correctly.
# Order matters: the first section whose phrase matches wins, so the specific phrases
# ("about the role") sit above the generic ones ("about ...", which is company boilerplate).
_SECTION_HEADINGS = [
    ("preferred", ["preferred qualifications", "preferred skills", "preferred requirements", "preferred experience",
                   "nice to have", "nice-to-have", "bonus points", "bonus", "good to have", "pluses",
                   "it would be great if", "what would make you stand out", "ideally you have", "ideally, you have",
                   "additional qualifications", "even better if", "we'd love to hear from people with",
                   "it's a plus if", "extra credit", "desired qualifications", "desired skills"]),
    ("minimum", ["minimum qualifications", "basic qualifications", "minimum requirements", "requirements",
                 "qualifications", "the qualifications you need", "what you'll need", "what you will need",
                 "what we're looking for", "what we are looking for", "what we look for", "who you are",
                 "you have", "you should have", "required skills", "required qualifications", "required experience",
                 "must have", "must-have", "skills and experience", "skills & experience", "about you",
                 "what you bring", "what you'll bring", "what you will bring", "your profile", "eligibility",
                 "experience", "education", "technical skills", "skills required", "key skills",
                 "what we need", "what you need", "who we're looking for", "who we are looking for",
                 "your skills", "your experience", "candidate profile", "job requirements"]),
    ("responsibilities", ["responsibilities", "key responsibilities", "roles and responsibilities",
                          "roles & responsibilities", "what you'll do", "what you will do", "your role", "the role",
                          "in this role", "day to day", "day-to-day", "what you'll be doing", "what you will be doing",
                          "your responsibilities", "job responsibilities", "duties", "your impact", "the impact you will have",
                          "the impact you'll have", "what you'll work on", "what you will work on",
                          "what you'll be working on", "the work you'll do", "role overview", "you will",
                          "position expectations", "role expectations", "what is the role", "your mission",
                          "what you'll achieve", "essential functions", "job duties", "key accountabilities"]),
    ("about", ["about the role", "about this role", "about the job", "about the position", "about this position",
               "job description", "role description", "an overview of this role", "overview", "the opportunity",
               "position summary", "job summary", "summary", "the job", "role summary", "purpose of the role"]),
    # Headings whose content belongs in none of the tabs — company boilerplate, benefits,
    # EEO statements. Recognizing them stops their lines leaking into the previous section.
    ("skip", ["about ", "who we are", "get to know us", "benefits", "perks", "what we offer", "why ", "how ",
              "compensation", "salary", "equal opportunity", "eeo", "our commitment", "our values", "diversity",
              "inclusion", "how to apply", "application process", "pay range", "the pay range",
              "pay transparency", "additional information", "life at", "accommodation", "your privacy", "privacy",
              "compliance", "fraud", "notice to", "#li", "what we can offer", "what you can expect from us",
              "the team", "who you'll work with", "our team", "team", "we offer", "what's in it for you",
              "disclaimer", "export control", "working at", "join us", "our culture", "culture"]),
]

_BULLET_PREFIX = re.compile(r"^\s*(?:[-•*·▪●◦–]|\d+[.)])\s*")
_INLINE_BULLET = re.compile(r"\s+[•·▪●◦]\s+")
_MAX_ITEMS = 12
_MAX_ITEM_CHARS = 280


def normalize(description: str) -> str:
    """Some sources leave entities in (double-encoded &amp;nbsp; and the like — see
    adapters/common.py's unescape_text) and use typographic apostrophes; headings only match
    reliably once both are flattened."""
    text = html.unescape(html.unescape(description))
    for odd in ("\xa0", "\u202f", "\u2009", "\u200b"):
        text = text.replace(odd, " ")
    return text.replace("\u2019", "'").replace("\u2018", "'")


def _all_heading_phrases() -> list[str]:
    phrases = [p for _, ps in _SECTION_HEADINGS for p in ps if not p.endswith(" ") and len(p) > 4]
    return sorted(set(phrases), key=len, reverse=True)


# Run-in headings in single-line descriptions (every Workday posting arrives this way): a known
# phrase in Title Case or followed by a colon, mid-paragraph. Breaking a line around it lets the
# same line-based parser handle both shapes.
_RUN_IN_HEADING = re.compile(
    r"(?:(?<=[.!?:)])|(?<=\s))\s*(" + "|".join(re.escape(p) for p in _all_heading_phrases()) + r")(\s*:|(?=\s+(?-i:[A-Z•·])))",
    re.IGNORECASE,
)


# Phrases that open ordinary sentences too often ("Experience with Kafka…", "The role will…")
# to be trusted as a run-in heading without a colon after them.
_COLON_ONLY = {"experience", "education", "the role", "the job", "you will", "you have", "summary", "overview",
               "duties", "bonus", "requirements", "qualifications", "responsibilities", "your role", "in this role",
               "who you are", "about you", "pluses", "eligibility", "the opportunity", "your impact"}
_MINOR_WORDS = {"a", "an", "the", "to", "of", "on", "in", "and", "&", "for", "with", "you", "we", "this", "is"}


def _is_title_case(phrase: str) -> bool:
    words = phrase.split()
    return all(w[0].isupper() or w.lower() in _MINOR_WORDS for w in words) and words[0][0].isupper()


def _break_run_in_headings(text: str) -> str:
    def replace(match: re.Match) -> str:
        phrase = match.group(1)
        has_colon = ":" in match.group(2)
        # Without a colon, only accept a multi-word Title Case phrase followed by a capital —
        # "What You'll Do Build…" yes, "Experience with Azure" or "you will build" no.
        if not has_colon and (phrase.lower() in _COLON_ONLY or not _is_title_case(phrase)):
            return match.group(0)
        return "\n" + phrase + ":\n"
    return _RUN_IN_HEADING.sub(replace, text)


def _heading_section(line: str) -> Optional[str]:
    text = line.strip().rstrip(":").strip().lower()
    if not text or len(text) > 70:
        return None
    # A heading is short and isn't a sentence; a long line ending in "." is body text that
    # merely starts with a heading-like phrase ("Experience with Kafka is required.").
    if text.endswith(".") or len(text.split()) > 9:
        return None
    for section, prefixes in _SECTION_HEADINGS:
        for p in prefixes:
            if p.endswith(" "):
                if text.startswith(p):
                    return section
            elif text == p or text.startswith(p + " ") or text.startswith(p + ":") or text.startswith(p + " ("):
                return section
    return None


def _clean_item(line: str) -> str:
    return _BULLET_PREFIX.sub("", line).strip()


def _split_long(item: str) -> list[str]:
    """A section recovered from a run-in paragraph is one long blob; sentences read as bullets."""
    if len(item) <= _MAX_ITEM_CHARS:
        return [item]
    parts = [p.strip() for p in re.split(r"(?<=[.;!?])\s+(?=[A-Z])", item) if p.strip()]
    return parts or [item]


def split_sections(description: str) -> dict[str, list[str]]:
    sections: dict[str, list[str]] = {"about": [], "minimum": [], "preferred": [], "responsibilities": [], "lead": []}
    text = normalize(description)
    if text.count("\n") < 3:
        text = _break_run_in_headings(text)
    text = _INLINE_BULLET.sub("\n", text)
    current = "lead"
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        heading = _heading_section(line)
        if heading:
            current = heading
            # "Requirements: Python, SQL" — a heading with its content on the same line.
            _, _, rest = line.partition(":")
            if rest.strip() and current != "skip":
                sections[current].extend(_split_long(rest.strip()))
            continue
        if current == "skip":
            continue
        item = _clean_item(line)
        if item and item != "&":
            sections[current].extend(_split_long(item) if current != "lead" and current != "about" else [item])
    return sections


def _about(sections: dict[str, list[str]], description: str) -> str:
    paragraphs = sections["about"] or sections["lead"]
    text = " ".join(paragraphs[:4]).strip()
    if not text:
        text = normalize(description).strip().split("\n\n")[0]
    if len(text) > 900:
        cut = text[:900]
        text = cut[: cut.rfind(". ") + 1] if ". " in cut else cut.rstrip() + "…"
    return text


_INTERN_PATTERN = re.compile(r"\b(intern|internship|co-?op|apprentice(ship)?|trainee)\b", re.IGNORECASE)
_CONTRACT_PATTERN = re.compile(r"\b(contract(or)?|temporary|fixed[- ]term|freelance)\b", re.IGNORECASE)


def job_type(title: str, description: str, stated: str = "") -> str:
    stated = stated.lower().replace("-", "").replace("_", "").replace(" ", "")
    if "intern" in stated:
        return "internship"
    if any(word in stated for word in ("contract", "temporary", "temp", "freelance")):
        return "contract"
    if _INTERN_PATTERN.search(title):
        return "internship"
    if _CONTRACT_PATTERN.search(title):
        return "contract"
    return "full_time"


def _stated_work_mode(stated: str) -> Optional[str]:
    stated = stated.lower().replace("-", "").replace("_", "").replace(" ", "")
    if "hybrid" in stated:
        return "hybrid"
    if "remote" in stated or "telecommute" in stated:
        return "remote"
    if "onsite" in stated or "office" in stated:
        return "on_site"
    return None


def work_mode(location: str, description: str) -> str:
    loc = location.lower()
    if "hybrid" in loc:
        return "hybrid"
    if "remote" in loc or "anywhere" in loc:
        return "remote"
    head = description[:3000].lower()
    if re.search(r"\bhybrid\b", head):
        return "hybrid"
    if re.search(r"\b(fully remote|100% remote|remote[- ]first|work from home|remote role|this is a remote)\b", head):
        return "remote"
    return "on_site"


_GRAD_YEAR_CONTEXT = re.compile(
    r"(?:graduat\w*|class of|batch|passing out|pass(?:ing)?[- ]out|degree completion|expected to complete)"
    r"[^.\n]{0,60}?((?:20\d\d)(?:\s*(?:,|/|-|–|or|and|&)\s*(?:20\d\d))*)",
    re.IGNORECASE,
)


def eligible_grad_years(title: str, description: str) -> str:
    """'2026 – 2027' when the posting names graduation years, '' when it doesn't."""
    years: set[int] = set()
    for match in _GRAD_YEAR_CONTEXT.finditer(f"{title}\n{normalize(description)}"):
        years.update(int(y) for y in re.findall(r"20\d\d", match.group(1)))
    years = {y for y in years if 2015 <= y <= 2035}
    if not years:
        return ""
    lo, hi = min(years), max(years)
    return str(lo) if lo == hi else f"{lo} – {hi}"


def enrich(job: Job) -> Job:
    sections = split_sections(job.description)
    enriched = job.model_copy(update={
        "job_type": job_type(job.title, job.description, job.employment_type),
        "work_mode": _stated_work_mode(job.workplace_type) or work_mode(job.location, job.description),
        "about": _about(sections, job.description),
        "minimum_qualifications": sections["minimum"][:_MAX_ITEMS],
        "preferred_qualifications": sections["preferred"][:_MAX_ITEMS],
        "responsibilities": sections["responsibilities"][:_MAX_ITEMS],
        "eligible_grad_years": eligible_grad_years(job.title, job.description),
    })
    # Level reads job_type, so it's computed on the enriched copy
    return enriched.model_copy(update={"level": job_level(enriched), "role_family": role_family(enriched)})
