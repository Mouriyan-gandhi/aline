# Aline

Aline is an iOS career app for students and early-career engineers in India. It pulls real
job openings straight from company career sites, scores each one against your profile,
helps you tailor your resume to a role with on-device AI, and hosts an anonymous community
for interview experiences and interview questions.

```
┌──────────────────────────── iPhone (iOS 27) ────────────────────────────┐
│  SwiftUI views ─▶ view models ─▶ Services                               │
│                                   ├─ AlineAPI / APIClient ──── HTTPS ───┼──▶ FastAPI backend (Render)
│                                   ├─ MatchEngine (offline fallback)     │      ├─ job scrapers → in-memory cache
│                                   ├─ OnDeviceAI         (Foundation     │      │   (460 companies, 6 ATS platforms)
│                                   │                      Models)        │      ├─ recommender (per-user ranking)
│                                   │                                     │      └─ SQLite: users, community,
│                                   ├─ ResumeStructurer / PDF export      │          interview Qs, resumes, marks, files
│                                   └─ JobAlerts (local notifications)    │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Repository layout

| Path | What it is |
|---|---|
| `Aline-iOS/` | **The iOS app** — the final frontend, integrated with the backend. Open this one. |
| `backend/` | FastAPI backend: job scraping, community, interview questions, profile, resumes, files. |
| `ios/` | The previous iOS app. Kept for reference; it still works against the same backend. |
| `old_version/` | The original Node.js prototype (JobPulse). Historical only. |

---

## Architecture

### Backend (`backend/`)

Python 3.12, FastAPI, httpx, SQLite (stdlib `sqlite3`). One process, deployed as a Docker
container on Render.

**Jobs pipeline**

1. `app/companies.py` holds the company registry: 460 companies across Greenhouse (160),
   Ashby (131), Workday (82), SmartRecruiters (57), Lever (29) and Amazon (1). Another 106
   uncertain matches sit in `NEEDS_REVIEW`, waiting for manual confirmation.
2. `app/adapters/*.py` has one adapter per platform. Each calls that platform's public job
   API (for Workday, the sitemap plus the `JobPosting` JSON-LD on each job page). Adapters
   keep what the source states: description, posted date, employment type, workplace type,
   published salary, and structured sections such as Lever's Responsibilities and
   Qualifications lists.
3. `app/filters.py` keeps India-located, tech-relevant, non-senior roles, and extracts
   skills and minimum years of experience.
4. `app/job_enrich.py` derives the job detail screen's fields: job type, work mode, about,
   minimum and preferred qualifications, responsibilities, and eligible graduation years.
   Source-stated values win; text heuristics are the fallback.
5. `app/main.py` keeps jobs in an in-memory cache, refreshed every 10 minutes. A company
   whose scrape fails keeps its last good jobs for up to 3 cycles. `/jobs` serves the cache;
   on a cold start it waits for the first scrape.

**Persistence:** `app/community_db.py` holds the SQLite schema and queries, with lightweight
`ALTER TABLE` migrations at startup. The database file is `backend/data/community.db`
(gitignored).

**Identity:** there is no real auth yet. The app generates a UUID once (`device_id`) and
sends it with every request. The backend maps it to one `users` row holding the anonymous
community handle and avatar, the profile, resumes, liked/applied jobs and attachments.
`DELETE /profile` removes everything tied to that identity.

**API**

| Area | Endpoints |
|---|---|
| Health / status | `GET /health`, `GET /companies` (registry and cache status) |
| Jobs | `GET /jobs`, `GET /jobs/marks?device_id=`, `PUT /jobs/{id}/mark` (liked / applied), `PUT /jobs/{id}/dismiss` (Not relevant) |
| Recommendations | `GET /recommendations?device_id=` (every job scored for the user, best first) |
| Profile | `GET /profile`, `PUT /profile` (partial update), `DELETE /profile` (delete account) |
| Resumes | `GET /resumes`, `PUT /resumes/{id}`, `DELETE /resumes/{id}` (JSON documents) |
| Files | `PUT /files/{id}` (base64, max 8 MB, PDF/images), `GET /files/{id}`, `DELETE /files/{id}` |
| Community | `POST /community/identity`, `GET/POST /community/discussions`, `GET /community/discussions/{id}`, `POST …/comments` (`parent_id` makes it a reply), `POST …/like`, `POST …/save`, `POST …/share`, `DELETE /community/comments/{id}`, `POST /community/comments/{id}/like`, `GET /community/companies`, `GET/POST /community/following…`, `GET /community/notifications`, `GET /community/categories`, `GET /community/topics` |
| Interview Qs | `GET /interview/questions` (filter: `companies`, `roles`, `topics`, `only_saved`), `POST /interview/questions`, `POST …/upvote`, `POST …/save`, `GET /interview/topics` |
| Feedback | `POST /feedback` |

Interactive docs are available at `/docs` on any running backend.

### iOS app (`Aline-iOS/`)

SwiftUI, iOS 27, Swift 5 language mode. No third-party dependencies.

```
Aline/
├─ AlineApp.swift            entry point; registers job-alert background refresh
├─ Models/                   frontend models (Opportunity, ResumeDocument, DiscussionPost, …)
├─ ViewModels/               one view model per tab + app navigation; all data loading lives here
├─ Views/                    the UI (Discover, Resume, Community, Profile, Onboarding, Auth)
├─ Theme/                    colors, spacing, animation tokens
├─ Services/
│  ├─ Networking/            APIClient (HTTP + device identity), AlineAPI (endpoints),
│  │                         APIModels (wire DTOs), ModelMapping (DTO → frontend models)
│  ├─ Matching/              MatchEngine: % Match, done on device
│  ├─ AI/                    OnDeviceAI (Foundation Models), ResumeStructurer (PDF → resume),
│  │                         PDFTextExtractor, SkillVocabulary
│  ├─ Resume/                ResumeRecord (stored form of a resume), ResumePDFExporter (real PDF output)
│  ├─ JobAlerts.swift        Opportunity Alerts (local notifications + background refresh)
│  ├─ AttachmentStore.swift  achievement files (upload, local cache, Quick Look)
│  ├─ OnboardingAnswers.swift  onboarding → preferences/profile; resume → profile autofill
│  └─ PreviewFixtures.swift  DEBUG-only placeholders for Xcode previews
└─ Info.plist                background-task keys merged into the generated Info.plist
```

**Data flow:** views → view models → `AlineAPI` → backend. The views never see wire types;
`ModelMapping.swift` converts them. Once you're signed in and onboarded, `MainAppView` loads
everything, and refreshes when the app returns to the foreground.

**Recommendations** are computed by the backend (`backend/app/recommend.py`, served at
`GET /recommendations`), per user, from their profile on the server:

1. **Eligibility gate.** Each job is tagged with a level (intern, entry, mid, senior, staff+)
   and a role family (software, backend, data, ML, QA, hardware, non-tech, …). Students and
   recent graduates only get intern and entry roles in Recommended. Professionals get roles
   matching their years of experience. Everyone gets only the role families they picked, or
   close neighbours of them. Ineligible jobs still appear in Explore More, capped at 60%.
2. **Score** for eligible jobs, out of 100:
   - skills 45%: overlap with the posting's skills, discounted when the posting names only a few
   - level fit 20%
   - experience 15%: required years vs. the user's actual experience
   - preferences 20%: location, job type, work mode, companies
   Unknown counts as neutral, never as a perfect fit.
3. **Behaviour.** "Not relevant" (thumbs-down on job detail, or long-press a card) hides the
   job and pushes similar roles and the same company down. Liked and applied jobs pull
   similar roles up.

Jobs at **80% or above** are Recommended. The app falls back to its on-device `MatchEngine`
only when it has no server score (offline, before the first fetch).

**Evaluating changes:** `backend/eval/run_eval.py` scores 8 realistic personas
(`eval/personas.json`) against the live feed (or a saved one with `--jobs`). It fails if a
student is recommended an above-entry role, if anyone gets non-tech roles they didn't pick, or
if an experienced professional gets internships. It also prints each persona's top 10.
Human ratings in `eval/labels.csv` (persona, job_id, great/ok/bad) add precision@10. Run it
before changing `recommend.py`.

**On-device AI** (`OnDeviceAI.swift`, Apple Foundation Models) needs Apple Intelligence. Without it, every
feature shows a plain "not available" message rather than placeholder text.
- Job detail: splits postings that couldn't be parsed into sections, and finds missing keywords against your profile.
- Resume chat: rewrites a selected point, or answers questions about the whole resume.
- Job tailoring: uses the selected resume, full profile, achievement gallery and target job to write a role-specific summary, point out profile items missing from the resume, and rewrite points to show missing skills and keywords.
- Interview questions: generates solutions, and the contribute sheet's "Give Answer with AI".
- Resume upload: turns a PDF into resume sections (`ResumeStructurer`, with a heuristic fallback).

---

## Setup

### Backend (local)

```bash
cd backend
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/uvicorn app.main:app --reload --port 8000
# http://127.0.0.1:8000/docs
```

The first `/jobs` request waits for a full scrape of every company, which takes several
minutes. After that it's served from cache.

| Env var | Default | Purpose |
|---|---|---|
| `SEED_DEMO_QUESTIONS` | `1` | Seeds 27 **demo** interview questions once at startup. Set `0` to stop. |

**Removing the demo interview questions** when the real question bank arrives: set
`SEED_DEMO_QUESTIONS=0`, then run `remove_demo_questions()` from `app/demo_questions.py`.
All demo questions belong to one system account, so nothing else is touched.

### Backend (deploy)

`backend/render.yaml` defines the Render service, and pushing to `main` deploys it. Full
steps are in [`backend/DEPLOY.md`](backend/DEPLOY.md).
Production URL: `https://aline-backend-wdp6.onrender.com`.

> **Known limitation:** the Render free plan has no persistent disk, so the SQLite database
> resets whenever the service restarts or redeploys (free services also sleep after ~15 minutes
> idle). Profiles, resumes, posts and attachments don't survive that. Fix: add a Render disk
> (paid plan) or move to a hosted Postgres.

### iOS app

1. Xcode 27 with the iOS 27 simulator runtime.
2. Open `Aline-iOS/Aline.xcodeproj`, pick an **iOS 27** simulator (e.g. iPhone 18 Pro), and Run.
3. Sign up or sign in (local stand-in for now), finish onboarding, and the app loads live data.

To point a debug build at a local backend, add an environment variable to the scheme
(Product → Scheme → Edit Scheme → Run → Arguments):
`ALINE_API_BASE_URL = http://127.0.0.1:8000`.

**Adding Swift files:** the project lists every file explicitly. After creating new
`.swift` files under `Aline-iOS/Aline/`, run `python3 Aline-iOS/add_sources.py` to register
them (or add them in Xcode).

---

## Rolling back

The production state before the frontend integration is tagged `pre-frontend-integration`.

- **Backend only, fastest:** Render dashboard → aline-backend → Deploys → **Rollback** on an earlier deploy.
- **Code:** `git push --force origin pre-frontend-integration:main` resets `main` (and Render redeploys).
  Or, to keep history, revert the commits after the tag: `git revert pre-frontend-integration..main`.

---

## Status

| Area | State |
|---|---|
| Discover, job detail, liked/applied, filters, alerts | Live data |
| Resume (upload, build from profile, AI tailoring, PDF export) | Live data + on-device AI |
| Community (posts, replies, likes, saves, follows, notifications) | Live data |
| Interview questions | Live endpoints, **demo content** until the real question bank is added |
| Profile (incl. achievements, attachments, preferences) | Live data |
| Sign in / sign up | Local stand-in; real auth not built yet |
| Persistent storage in production | Not yet; see the known limitation above |
