# ⚡ JobPulse — Fortune 500 Job Notifier

Real-time job notifications from 80+ top tech & AI companies for **interns, new grads (2026/2027/2028), and entry-level roles** in software and AI.

## 🚀 Quick Start

```bash
# Install dependencies (first time only)
npm install

# Start the app
npm run dev
```

Then open **http://localhost:3721** in your browser.

---

## 🔍 How It Works

- **Polls 80+ companies** via their ATS (Applicant Tracking System) APIs:
  - **Greenhouse** — Google, Meta, Stripe, Databricks, Datadog, Cloudflare, MongoDB, Waymo, 40+ more
  - **Lever** — Netflix, Spotify, Atlassian, GitHub, Shopify, Okta, 10+ more
  - **Ashby** — Anthropic, OpenAI, Cursor, Mistral AI, Modal, 5+ more
- **Filters** for intern / new grad / entry-level roles with target keywords
- **Auto-scans every 2 hours** via cron
- **WebSocket real-time** updates push new jobs instantly to your dashboard
- **SQLite database** stores all jobs locally so nothing is lost

---

## 🎯 Targeted Roles

| Category | Examples |
|---|---|
| Software Engineering | SWE Intern, Backend Eng, Frontend Eng, Full Stack |
| AI / ML | ML Engineer, Research Scientist, AI Intern, NLP, LLM |
| Data | Data Scientist, Data Engineer |
| Product | Product Manager, APM |
| Systems | DevOps, SRE, Infrastructure, Security Engineer |

**Keywords matched:** intern, internship, new grad, new-grad, 2026, 2027, 2028, campus, university, entry level, junior, associate, co-op, early career

---

## 📱 Dashboard Features

- **🔔 Unread tab** — instantly see new jobs
- **⭐ Save jobs** — bookmark roles you want to apply to
- **🔍 Search** — filter by title or company (Ctrl+K)
- **🏢 Companies view** — see all monitored companies
- **📋 Scrape Log** — history of all API calls and errors
- **🔴 Live indicator** — shows when scraping is in progress
- **Scan Now button** — trigger a manual scan anytime

---

## ⚙️ Configuration

### Add More Companies

Edit [`data/companies.js`](data/companies.js) and add:

```js
{ name: "My Company", platform: "greenhouse", slug: "mycompany", logo: "🏢" }
```

Find the slug from the company's Greenhouse/Lever careers URL:
- `boards.greenhouse.io/stripe` → slug is `stripe`
- `jobs.lever.co/netflix` → slug is `netflix`
- Career page hosted on Ashby → find slug in the URL

### Change Scan Frequency

In [`server.js`](server.js), find the cron schedule:

```js
cron.schedule("0 */2 * * *", () => { // every 2 hours
```

Change to `"*/30 * * * *"` for every 30 minutes, etc.

### Adjust Role Filters

Edit `TARGET_KEYWORDS` and `TARGET_ROLES` in [`data/companies.js`](data/companies.js).

---

## 🗂️ Project Structure

```
job-notifier/
├── server.js          # Express server + WebSocket + cron
├── data/
│   └── companies.js   # Company list + role keywords
├── scraper/
│   └── scraper.js     # Greenhouse / Lever / Ashby scrapers
├── db/
│   ├── database.js    # SQLite layer
│   └── jobs.db        # Auto-created local database
└── public/
    ├── index.html     # Dashboard UI
    ├── style.css      # Dark theme styles
    └── app.js         # Frontend logic + WebSocket client
```

---

## 📌 Notes

- The app runs **entirely on your machine** — no cloud, no fees
- Jobs are stored in `db/jobs.db` — safe to delete to reset
- Some companies use Workday / custom portals — those require separate monitoring
- The `/api/log` endpoint shows scrape success/failure per company
