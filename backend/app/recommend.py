"""
Job recommendations — the "% Match" on every job card, computed per user on the backend.

Two stages:

1. Eligibility (a gate, not a weight). A job only competes for Recommended when
   - its LEVEL fits the user's (students: intern + entry; professionals: by experience), and
   - its ROLE FAMILY is one the user wants (or a close neighbour of one).
   Ineligible jobs still appear in Explore More, scored honestly low (never above 60%).
   Before this gate existed a 3rd-year student's #1 match was "Sr. Software Engineer" and a
   Marketing internship scored 90% — see eval/run_eval.py for the regression checks.

2. Score (0–100) for eligible jobs:
   skills 45%   overlap with the user's skills, shrunk toward 50% when the posting names few
                skills (1 of 1 is weak evidence, not a perfect match)
   level  20%   exact level fit; unknown level is neutral (0.6), never a perfect fit
   experience 15%  required years vs. the user's experience; unknown is neutral
   preferences 20% role family, location, job type, work mode, preferred companies
   then personal adjustments from behaviour: "Not relevant" dismissals push similar roles and
   the same company down; liked/applied jobs pull similar roles up.

Job-side features (level, role family) are computed once per job in job_enrich.py.
"""
import json
import re
from datetime import datetime, timezone
from typing import Optional

from app.filters import extract_skills
from app.schemas import Job

# Levels, low to high
INTERN, ENTRY, MID, SENIOR, STAFF = 0, 1, 2, 3, 4
LEVEL_NAMES = {INTERN: "intern", ENTRY: "entry", MID: "mid", SENIOR: "senior", STAFF: "staff"}

RECOMMEND_THRESHOLD = 80  # the app's Recommended cutoff; kept here for eval reporting
INELIGIBLE_CAP = 60


# MARK: - Job features

_STAFF = re.compile(r"\b(staff|principal|architect|director|head of|vp|avp|vice president|distinguished|fellow)\b", re.I)
_MANAGER = re.compile(r"\b(manager|management)\b", re.I)
_SENIOR = re.compile(r"\b(senior|sr\.?|lead|leader|tech lead|iii|iv|v)\b|\b(sde|swe|engineer|developer)\s*-?\s*(3|iii|4)\b", re.I)
_MID = re.compile(r"\b(ii|mts)\b|\b(sde|swe|engineer|developer)\s*-?\s*2\b|\bsde\s*2\b", re.I)
_ENTRY = re.compile(r"\b(graduate|new grad|fresher|freshers|trainee|junior|jr\.?|entry[- ]level|associate engineer|apprentice|campus|university|early career|engineer i|developer i|sde\s*-?\s*1|sde-?i)\b", re.I)
_INTERN = re.compile(r"\b(intern|internship|co-?op)\b", re.I)


def job_level(job: Job) -> Optional[int]:
    """Best-supported level, or None when nothing in the posting says."""
    title = job.title
    if job.job_type == "internship" or _INTERN.search(title):
        return INTERN
    if _STAFF.search(title):
        return STAFF
    if _SENIOR.search(title):
        return SENIOR
    years = job.min_years_experience
    if years is not None:
        if years <= 1:
            return ENTRY
        if years <= 4:
            return MID
        return SENIOR
    if _MID.search(title):
        return MID
    if _ENTRY.search(title):
        return ENTRY
    if _MANAGER.search(title) and not re.search(r"product manager|program manager", title, re.I):
        return SENIOR
    return None


# Checked in order — specific families before the broad "software" one, so "Software QA
# Engineer" is QA and "Backend Software Engineer" is backend.
_FAMILIES = [
    ("nontech", r"marketing|sales|account (?:executive|manager)|financ|accountant|legal|counsel|\bhr\b|human resources|recruit|talent|customer success|customer support|support specialist|business development|operations (?:manager|executive|associate)|copywriter|content writer|social media|procurement|payroll|admin|clinical|technician|product specialist|retail|store associate|cashier|warehouse"),
    ("support", r"service desk|help ?desk|technical support|support engineer|desktop support|it support"),
    ("presales", r"solutions? engineer|sales engineer|pre-?sales|consulting engineer|application engineer|field engineer|technology consultant"),
    ("pm", r"product manager|program manager|product owner|\bapm\b|product management"),
    ("design", r"\bdesigner\b|\bux\b|\bui/ux\b|user experience|product design"),
    ("hardware", r"asic|vlsi|hardware|firmware|embedded|silicon|\brf\b|signal|analog|mechanical|electrical|pcb|fpga|physical design|verification|\bdft\b|circuit|\bip\b|\bsoc\b|rtl|design engineer|process control|semiconductor|memory|\bams\b"),
    ("security", r"security|cyber|soc analyst|penetration|appsec|infosec"),
    ("qa", r"\btest|\bqa\b|quality|sdet|automation engineer"),
    ("devops", r"devops|\bsre\b|site reliability|cloud|infrastructure|platform engineer|systems engineer|network engineer|it engineer"),
    ("ml", r"machine learning|\bml\b|\bai\b|artificial intelligence|deep learning|\bnlp\b|computer vision|llm|applied scientist|research scientist"),
    ("data", r"\bdata\b|analytics|analyst|business intelligence|\bbi\b|data scientist"),
    ("mobile", r"\bios\b|android|mobile|flutter|react native"),
    ("frontend", r"front[- ]?end|\bui engineer|web developer"),
    ("backend", r"back[- ]?end|\bapi\b|server[- ]side"),
    # Not plain "engineer": that word alone also titles hardware, clinical and process roles
    ("software", r"software|developer|\bsde\b|\bswe\b|full[- ]?stack|programmer|application development|\bmts\b|member of technical staff"),
]


def role_family(job: Job) -> str:
    title = job.title.lower()
    for family, pattern in _FAMILIES:
        if re.search(pattern, title):
            return family
    return "other"


# MARK: - User features

# Onboarding / Career Preferences role labels → the families they cover
_ROLE_LABEL_FAMILIES = {
    "software engineering": {"software", "backend", "frontend", "mobile"},
    "backend development": {"backend", "software"},
    "frontend development": {"frontend", "software"},
    "mobile development": {"mobile", "software"},
    "data science": {"data", "ml"},
    "data scientist": {"data", "ml"},
    "data analyst": {"data"},
    "ai / ml": {"ml", "data"},
    "ai/ml engineering": {"ml", "data"},
    "cloud / devops": {"devops"},
    "cybersecurity": {"security"},
    "product management": {"pm"},
    "ui/ux design": {"design"},
    "embedded systems": {"hardware"},
    "quality assurance": {"qa"},
}
# Close neighbours: eligible, with a smaller preference score
_ADJACENT = {
    "software": {"backend", "frontend", "mobile", "qa", "devops", "ml"},
    "backend": {"software", "devops"},
    "frontend": {"software", "mobile", "design"},
    "mobile": {"software", "frontend"},
    "data": {"ml", "software"},
    "ml": {"data", "software"},
    "devops": {"software", "backend", "security"},
    "security": {"devops"},
    "qa": {"software"},
    "pm": {"design"},
    "design": {"frontend", "pm"},
    "hardware": set(),
}
_TECH_FAMILIES = {"software", "backend", "frontend", "mobile", "data", "ml", "devops", "security", "qa", "hardware", "other"}
# support / presales / nontech / pm / design only reach Recommended when the user picked them

_MONTHS = {m: i for i, m in enumerate(["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"], 1)}


def _months(date_range: str) -> float:
    """'Jun 2026 – Aug 2026' / 'Jul 2025 - Present' / '2024 – 2025' → months; 0 when unparseable."""
    parts = re.split(r"\s*[-–—]\s*|\s+to\s+", date_range.strip(), maxsplit=1)

    def parse(text: str):
        text = text.strip().lower()
        if not text:
            return None
        if "present" in text or "current" in text or "now" in text:
            now = datetime.now(timezone.utc)
            return now.year, now.month
        year = re.search(r"(19|20)\d\d", text)
        if not year:
            return None
        month = next((v for k, v in _MONTHS.items() if text.startswith(k)), 1)
        return int(year.group()), month

    start = parse(parts[0]) if parts else None
    if not start:
        return 0.0
    end = parse(parts[1]) if len(parts) > 1 else start
    if not end:
        return 0.0
    return float(max(1, (end[0] - start[0]) * 12 + (end[1] - start[1]) + 1))


class UserFeatures:
    def __init__(self, user_row, marks: list[dict], dismissed: list[dict], jobs_by_id: dict[str, Job]):
        def load(column, default):
            try:
                return json.loads(user_row[column]) if user_row[column] else default
            except (ValueError, TypeError, IndexError, KeyError):
                return default

        prefs = load("preferences", {}) or {}
        experience = load("experience", [])
        projects = load("projects", [])
        achievements = load("achievements", [])

        # Skills: the profile's list plus tools named in experience/project text
        skills = {s.lower() for s in load("skills", [])}
        text = " ".join(
            [" ".join(e.get("bullets", [])) for e in experience]
            + [p.get("tech_stack", "") + " " + " ".join(p.get("bullets", [])) for p in projects]
        )
        skills |= {s.lower() for s in extract_skills(text)}
        self.skills = skills
        self.experience_years = sum(_months(e.get("date_range", "")) for e in experience) / 12.0
        self.credential_text = " ".join(
            f"{a.get('title', '')} {a.get('issuer', '')} {a.get('description', '')}" for a in achievements
        ).lower()

        self.levels = self._target_levels(user_row, prefs)
        roles = [r.lower() for r in prefs.get("preferred_roles", [])]
        families: set[str] = set()
        for role in roles:
            families |= _ROLE_LABEL_FAMILIES.get(role, set())
            # Free-text roles typed in Career Preferences
            if role not in _ROLE_LABEL_FAMILIES:
                families.add(role_family(Job(id="", company="", platform="", title=role, location="", apply_url="")))
        self.families = families - {"other"} if families - {"other"} else set()
        self.adjacent = set().union(*(_ADJACENT.get(f, set()) for f in self.families)) - self.families if self.families else set()

        self.locations = [] if prefs.get("is_open_to_any_location", True) else [l.lower() for l in prefs.get("preferred_locations", [])]
        self.job_types = {t.lower().replace("-", "").replace(" ", "") for t in prefs.get("opportunity_types", [])}
        self.work_modes = {w.lower().replace("-", "") for w in prefs.get("work_arrangements", [])}
        self.companies = [c.lower() for c in prefs.get("preferred_companies", [])]

        # Behaviour: dismissed families/companies count against similar jobs, liked/applied for
        self.dismissed_ids = {d["job_id"] for d in dismissed}
        self.family_feedback: dict[str, float] = {}
        self.company_feedback: dict[str, float] = {}
        for d in dismissed:
            self._feedback(d.get("job"), jobs_by_id.get(d["job_id"]), -1.0)
        for m in marks:
            snapshot = Job(**json.loads(m["job_json"])) if m.get("job_json") else None
            self._feedback(snapshot, jobs_by_id.get(m["job_id"]), +0.5 if m.get("liked") else 0)
            self._feedback(snapshot, jobs_by_id.get(m["job_id"]), +0.5 if m.get("applied") else 0)

    def _feedback(self, snapshot: Optional[Job], live: Optional[Job], weight: float) -> None:
        job = live or snapshot
        if job is None or weight == 0:
            return
        family = live.role_family if live and live.role_family else role_family(job)
        self.family_feedback[family] = self.family_feedback.get(family, 0) + weight
        key = job.company.lower()
        self.company_feedback[key] = self.company_feedback.get(key, 0) + weight

    @staticmethod
    def _target_levels(user_row, prefs: dict) -> set[int]:
        stage = " ".join(
            str(x or "") for x in (user_row["career_stage"], user_row["headline"], prefs.get("experience_level"))
        ).lower()
        grad_year = user_row["graduation_year"]
        still_studying = grad_year is not None and grad_year >= datetime.now(timezone.utc).year
        if "student" in stage or "fresher" in stage or still_studying:
            return {INTERN, ENTRY}
        if "recent graduate" in stage or "graduate" in stage:
            return {INTERN, ENTRY}
        return set()  # decided per job from experience years, see level_fit


# MARK: - Scoring

def _professional_level_fit(level: int, years: float) -> float:
    if level == INTERN:
        return 0.3
    ideal = ENTRY if years < 1.5 else MID if years < 4.5 else SENIOR if years < 9 else STAFF
    return {0: 1.0, 1: 0.6}.get(abs(level - ideal), 0.1)


def score_job(job: Job, user: UserFeatures) -> dict:
    level = job.level
    family = job.role_family or "other"
    reasons: list[str] = []

    # --- Stage 1: eligibility
    if user.levels:
        level_ok = level is None or level in user.levels
        level_fit = 1.0 if level in user.levels else (0.6 if level is None else 0.0)
    else:
        level_fit = 0.6 if level is None else _professional_level_fit(level, user.experience_years)
        level_ok = level_fit >= 0.6
    if user.families:
        family_ok = family in user.families or family in user.adjacent or family == "other"
    else:
        family_ok = family in _TECH_FAMILIES  # no preference set: any tech role
    eligible = level_ok and family_ok

    # --- Stage 2: score
    job_skills = {s.lower() for s in job.extracted_skills}
    matched = [s for s in job.extracted_skills if s.lower() in user.skills]
    missing = [s for s in job.extracted_skills if s.lower() not in user.skills]
    skill_score = (len(matched) + 0.5 * 2) / (len(job_skills) + 2)

    years = job.min_years_experience
    if years is None:
        experience_score = 0.6
    elif years <= user.experience_years + 0.5:
        experience_score = 1.0
    else:
        experience_score = max(0.0, 1 - (years - user.experience_years) * 0.3)

    prefs: list[float] = []
    if user.families:
        prefs.append(1.0 if family in user.families else 0.6 if family in user.adjacent else 0.4)
    if user.locations:
        loc = job.location.lower()
        aliases = {"bengaluru": ["bangalore"], "bangalore": ["bengaluru"], "delhi ncr": ["delhi", "gurgaon", "gurugram", "noida"],
                   "gurugram": ["gurgaon"], "mumbai": ["navi mumbai"]}
        hit = any(l in loc or any(a in loc for a in aliases.get(l, [])) for l in user.locations)
        prefs.append(1.0 if hit else 0.3)
        if hit:
            reasons.append("In your preferred location")
    if user.job_types:
        kind = {"internship": "internship", "full_time": "fulltime", "contract": "contract"}[job.job_type]
        prefs.append(1.0 if kind in user.job_types else 0.3)
    if user.work_modes:
        mode = job.work_mode.replace("_", "")
        prefs.append(1.0 if mode in user.work_modes else 0.5)
    if user.companies and any(c in job.company.lower() for c in user.companies):
        prefs.append(1.0)
        reasons.append("A company you follow")
    preference_score = sum(prefs) / len(prefs) if prefs else 0.6

    raw = skill_score * 0.45 + level_fit * 0.20 + experience_score * 0.15 + preference_score * 0.20
    if user.credential_text and any(s in user.credential_text for s in job_skills):
        raw += 0.02

    # Behaviour: capped so feedback nudges ranking without overriding fit
    raw += max(-0.15, min(0.06, 0.04 * user.family_feedback.get(family, 0)))
    raw += max(-0.10, min(0.04, 0.05 * user.company_feedback.get(job.company.lower(), 0)))

    # Calibrated so a strong, eligible fit lands at 80–95 (the app's Recommended band)
    score = round(min(1.0, max(0.0, raw)) ** 0.75 * 100)
    if not eligible:
        score = min(score, INELIGIBLE_CAP)

    if eligible and level in (INTERN, ENTRY) and user.levels:
        reasons.insert(0, "Right level for you" if level is not None else "")
    if job_skills:
        reasons.append(f"You have {len(matched)} of {len(job_skills)} listed skills")
    if not level_ok and level is not None:
        reasons.append(f"{LEVEL_NAMES[level].capitalize()}-level role")
    if not family_ok:
        reasons.append("Outside the roles you picked")

    return {
        "job_id": job.id,
        "score": score,
        "eligible": eligible,
        "level": LEVEL_NAMES.get(level) if level is not None else None,
        "role_family": family,
        "matched_skills": matched,
        "missing_skills": missing,
        "reasons": [r for r in reasons if r],
    }


def recommend(jobs: list[Job], user: UserFeatures) -> list[dict]:
    results = [score_job(job, user) for job in jobs if job.id not in user.dismissed_ids]
    results.sort(key=lambda r: (r["eligible"], r["score"]), reverse=True)
    return results
