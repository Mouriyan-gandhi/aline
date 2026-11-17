"""
Recommendation quality checks — run before changing app/recommend.py.

    .venv/bin/python eval/run_eval.py                      # scores the live /jobs feed
    .venv/bin/python eval/run_eval.py --jobs saved.json    # or a saved /jobs response

For each persona in eval/personas.json it prints the Recommended count and top 10, and checks:
  - students never get roles above entry level in Recommended
  - nobody gets non-tech roles in Recommended unless they asked for them
  - experienced professionals don't get internships in Recommended
  - (warning only) every persona with skills or preferences gets at least MIN_RECOMMENDED jobs

Human labels (optional): eval/labels.csv with columns persona,job_id,label (great|ok|bad).
When present, precision@10 (great+ok among the top 10 labeled) is reported per persona.
Exit code 1 when any check fails, so it can gate a deploy.
"""
import argparse
import csv
import json
import sys
from pathlib import Path

import httpx

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent))

from app.filters import extract_skills  # noqa: E402
from app.job_enrich import enrich  # noqa: E402
from app.recommend import ENTRY, RECOMMEND_THRESHOLD, UserFeatures, recommend  # noqa: E402
from app.schemas import Job  # noqa: E402

MIN_RECOMMENDED = 5
LIVE_URL = "https://aline-backend-wdp6.onrender.com/jobs"


def load_jobs(path):
    raw = json.load(open(path)) if path else httpx.get(LIVE_URL, timeout=600).json()
    # Re-extract skills with the current vocabulary, so a saved feed reflects today's code
    jobs = [Job(**j) for j in raw]
    return [enrich(j.model_copy(update={"extracted_skills": extract_skills(f"{j.title} {j.description}")})) for j in jobs]


def persona_row(p):
    return {
        "career_stage": p.get("career_stage"), "headline": p.get("career_stage"),
        "graduation_year": p.get("graduation_year"),
        "skills": json.dumps(p.get("skills", [])), "experience": json.dumps(p.get("experience", [])),
        "projects": json.dumps(p.get("projects", [])), "achievements": json.dumps(p.get("achievements", [])),
        "preferences": json.dumps(p.get("preferences", {})),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--jobs", help="saved /jobs JSON (default: fetch live)")
    parser.add_argument("--top", type=int, default=10)
    args = parser.parse_args()

    jobs = load_jobs(args.jobs)
    by_id = {j.id: j for j in jobs}
    personas = json.load(open(ROOT / "personas.json"))
    labels = {}
    if (ROOT / "labels.csv").exists():
        for row in csv.DictReader(open(ROOT / "labels.csv")):
            labels[(row["persona"], row["job_id"])] = row["label"]

    failures, warnings = [], []
    print(f"{len(jobs)} jobs\n")
    for p in personas:
        user = UserFeatures(persona_row(p), [], [], by_id)
        results = recommend(jobs, user)
        rec = [r for r in results if r["score"] >= RECOMMEND_THRESHOLD]
        is_student = bool(user.levels)
        years = user.experience_years

        too_senior = [r for r in rec if is_student and by_id[r["job_id"]].level is not None and by_id[r["job_id"]].level > ENTRY]
        nontech = [r for r in rec if r["role_family"] == "nontech" and "nontech" not in user.families]
        interns = [r for r in rec if not is_student and years >= 3 and by_id[r["job_id"]].level == 0]
        has_signal = bool(p.get("skills") or p.get("preferences"))

        print(f"== {p['id']}: {p['description']}")
        print(f"   recommended: {len(rec)}   eligible: {sum(r['eligible'] for r in results)}")
        for r in results[: args.top]:
            j = by_id[r["job_id"]]
            label = labels.get((p["id"], j.id), "")
            print(f"   {r['score']:3d}%  {r['level'] or '?':6s} {r['role_family']:9s} {j.title[:52]:52s} @ {j.company[:18]} {label}")
        for name, bad in [("above-entry roles for a student", too_senior), ("non-tech roles", nontech), ("internships for an experienced pro", interns)]:
            if bad:
                failures.append(f"{p['id']}: {len(bad)} {name}, e.g. {by_id[bad[0]['job_id']].title}")
        if has_signal and len(rec) < MIN_RECOMMENDED:
            # Usually thin job supply for that role/location, not a ranking bug — reported, not failed
            warnings.append(f"{p['id']}: only {len(rec)} recommended (want ≥ {MIN_RECOMMENDED}); check supply for these roles")
        labeled = [labels[(p["id"], r["job_id"])] for r in results[:10] if (p["id"], r["job_id"]) in labels]
        if labeled:
            good = sum(1 for l in labeled if l in ("great", "ok"))
            print(f"   precision@10 (labeled {len(labeled)}): {good / len(labeled):.0%}")
        print()

    for w in warnings:
        print("warning:", w)
    if failures:
        print("FAILED:")
        for f in failures:
            print("  -", f)
        sys.exit(1)
    print("All checks passed.")


if __name__ == "__main__":
    main()
