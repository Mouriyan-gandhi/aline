const express = require("express");
const cors = require("cors");
const path = require("path");
const WebSocket = require("ws");
const http = require("http");
const cron = require("node-cron");

const { COMPANIES } = require("./data/companies");
const { scrapeCompany } = require("./scraper/scraper");
const db = require("./db/database");

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

// ─── WebSocket broadcast ─────────────────────────────────────────────────────
function broadcast(event, data) {
  const payload = JSON.stringify({ event, data, ts: new Date().toISOString() });
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) client.send(payload);
  });
}

// ─── Scrape runner ────────────────────────────────────────────────────────────
let isScraping = false;
let lastScrapeTime = null;
let scrapeProgress = { current: 0, total: 0, company: "" };

async function runScrape(targetCompanies = COMPANIES) {
  if (isScraping) {
    console.log("Scrape already in progress, skipping.");
    return;
  }
  isScraping = true;
  scrapeProgress = { current: 0, total: targetCompanies.length, company: "" };
  broadcast("scrape_start", { total: targetCompanies.length });

  let totalNew = 0;

  for (let i = 0; i < targetCompanies.length; i++) {
    const company = targetCompanies[i];
    scrapeProgress = { current: i + 1, total: targetCompanies.length, company: company.name };
    broadcast("scrape_progress", scrapeProgress);

    try {
      const newJobs = await scrapeCompany(company);
      totalNew += newJobs.length;

      if (newJobs.length > 0) {
        broadcast("new_jobs", {
          company: company.name,
          count: newJobs.length,
          jobs: newJobs,
        });
      }
    } catch (e) {
      // already handled inside scrapeCompany
    }

    // Small delay to be polite to APIs
    await new Promise((r) => setTimeout(r, 300));
  }

  lastScrapeTime = new Date().toISOString();
  isScraping = false;
  broadcast("scrape_done", {
    total_new: totalNew,
    time: lastScrapeTime,
    stats: db.getStats(),
  });
  console.log(`[Scrape done] ${totalNew} new jobs found at ${lastScrapeTime}`);
}

// ─── REST API ─────────────────────────────────────────────────────────────────

// GET /api/jobs — list jobs with optional filters
app.get("/api/jobs", (req, res) => {
  const { company, search, filter } = req.query;
  const filters = { company, search };

  if (filter === "unread") {
    filters.is_new = true;
    filters.is_dismissed = false;
  } else if (filter === "saved") {
    filters.is_saved = true;
  } else if (filter === "all") {
    filters.is_dismissed = false;
  }

  const jobs = db.getJobs(filters);
  res.json(jobs);
});

// GET /api/stats
app.get("/api/stats", (req, res) => {
  res.json({
    ...db.getStats(),
    is_scraping: isScraping,
    last_scrape: lastScrapeTime,
    scrape_progress: scrapeProgress,
    companies: COMPANIES.length,
  });
});

// GET /api/companies
app.get("/api/companies", (req, res) => {
  res.json(
    COMPANIES.map((c) => ({
      name: c.name,
      slug: c.slug,
      platform: c.platform,
      logo: c.logo,
    }))
  );
});

// POST /api/scrape — trigger a manual scrape
app.post("/api/scrape", (req, res) => {
  if (isScraping) {
    return res.status(409).json({ error: "Scrape already in progress" });
  }
  runScrape(); // fire-and-forget
  res.json({ message: "Scrape started" });
});

// POST /api/scrape/:slug — scrape a single company
app.post("/api/scrape/:slug", (req, res) => {
  const company = COMPANIES.find((c) => c.slug === req.params.slug);
  if (!company) return res.status(404).json({ error: "Company not found" });
  runScrape([company]);
  res.json({ message: `Scraping ${company.name}` });
});

// PATCH /api/jobs/:id/read
app.patch("/api/jobs/:id/read", (req, res) => {
  db.markAsRead(req.params.id);
  broadcast("job_updated", { id: req.params.id, is_new: 0 });
  res.json({ ok: true });
});

// POST /api/jobs/read-all
app.post("/api/jobs/read-all", (req, res) => {
  db.markAllRead();
  broadcast("all_read", {});
  res.json({ ok: true });
});

// PATCH /api/jobs/:id/dismiss
app.patch("/api/jobs/:id/dismiss", (req, res) => {
  db.dismissJob(req.params.id);
  broadcast("job_updated", { id: req.params.id, is_dismissed: 1 });
  res.json({ ok: true });
});

// PATCH /api/jobs/:id/save
app.patch("/api/jobs/:id/save", (req, res) => {
  db.saveJob(req.params.id);
  res.json({ ok: true });
});

// GET /api/log — scrape history
app.get("/api/log", (req, res) => {
  res.json(db.getLastScrapeLog());
});

// ─── Scheduled scrape: every 2 hours ─────────────────────────────────────────
cron.schedule("0 */2 * * *", () => {
  console.log("[Cron] Running scheduled scrape...");
  runScrape();
});

// ─── Boot ─────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3721;
server.listen(PORT, () => {
  console.log(`\n🚀 Job Notifier running at http://localhost:${PORT}`);
  console.log(`📡 Monitoring ${COMPANIES.length} companies across Greenhouse, Lever & Ashby`);
  console.log(`🔄 Auto-scrape every 2 hours\n`);

  // Run first scrape after 3 seconds
  setTimeout(() => runScrape(), 3000);
});
