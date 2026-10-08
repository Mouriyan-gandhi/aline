const Database = require("better-sqlite3");
const path = require("path");
const fs = require("fs");

const DB_DIR = path.join(__dirname, "..", "db");
if (!fs.existsSync(DB_DIR)) fs.mkdirSync(DB_DIR, { recursive: true });

const DB_PATH = path.join(DB_DIR, "jobs.db");

let db;

function getDb() {
  if (!db) {
    db = new Database(DB_PATH);
    db.pragma("journal_mode = WAL");
    initSchema();
  }
  return db;
}

function initSchema() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS jobs (
      id TEXT PRIMARY KEY,
      company TEXT NOT NULL,
      company_slug TEXT NOT NULL,
      platform TEXT NOT NULL,
      title TEXT NOT NULL,
      location TEXT,
      department TEXT,
      url TEXT NOT NULL,
      posted_at TEXT,
      discovered_at TEXT NOT NULL DEFAULT (datetime('now')),
      is_new INTEGER NOT NULL DEFAULT 1,
      is_dismissed INTEGER NOT NULL DEFAULT 0,
      is_saved INTEGER NOT NULL DEFAULT 0,
      raw_json TEXT
    );

    CREATE TABLE IF NOT EXISTS seen_ids (
      id TEXT PRIMARY KEY,
      company_slug TEXT,
      seen_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS scrape_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      company_slug TEXT NOT NULL,
      platform TEXT NOT NULL,
      status TEXT NOT NULL,
      jobs_found INTEGER DEFAULT 0,
      new_jobs INTEGER DEFAULT 0,
      error TEXT,
      scraped_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT
    );

    CREATE INDEX IF NOT EXISTS idx_jobs_discovered ON jobs(discovered_at DESC);
    CREATE INDEX IF NOT EXISTS idx_jobs_company ON jobs(company_slug);
    CREATE INDEX IF NOT EXISTS idx_jobs_new ON jobs(is_new, is_dismissed);
  `);
}

function isJobSeen(jobId) {
  const row = getDb().prepare("SELECT 1 FROM seen_ids WHERE id = ?").get(jobId);
  return !!row;
}

function markJobSeen(jobId, companySlug) {
  getDb()
    .prepare(
      "INSERT OR IGNORE INTO seen_ids (id, company_slug) VALUES (?, ?)"
    )
    .run(jobId, companySlug);
}

function insertJob(job) {
  getDb()
    .prepare(
      `INSERT OR IGNORE INTO jobs 
       (id, company, company_slug, platform, title, location, department, url, posted_at, raw_json)
       VALUES (@id, @company, @company_slug, @platform, @title, @location, @department, @url, @posted_at, @raw_json)`
    )
    .run(job);
}

function getJobs(filters = {}) {
  let query = `
    SELECT id, company, company_slug, platform, title, location, department, 
           url, posted_at, discovered_at, is_new, is_dismissed, is_saved
    FROM jobs
    WHERE 1=1
  `;
  const params = [];

  if (filters.company) {
    query += " AND company_slug = ?";
    params.push(filters.company);
  }
  if (filters.is_new !== undefined) {
    query += " AND is_new = ?";
    params.push(filters.is_new ? 1 : 0);
  }
  if (filters.is_dismissed !== undefined) {
    query += " AND is_dismissed = ?";
    params.push(filters.is_dismissed ? 1 : 0);
  }
  if (filters.is_saved !== undefined) {
    query += " AND is_saved = ?";
    params.push(filters.is_saved ? 1 : 0);
  }
  if (filters.search) {
    query += " AND (LOWER(title) LIKE ? OR LOWER(company) LIKE ?)";
    const term = `%${filters.search.toLowerCase()}%`;
    params.push(term, term);
  }

  query += " ORDER BY discovered_at DESC LIMIT 500";
  return getDb().prepare(query).all(...params);
}

function markAsRead(jobId) {
  getDb().prepare("UPDATE jobs SET is_new = 0 WHERE id = ?").run(jobId);
}

function markAllRead() {
  getDb().prepare("UPDATE jobs SET is_new = 0 WHERE is_dismissed = 0").run();
}

function dismissJob(jobId) {
  getDb()
    .prepare("UPDATE jobs SET is_dismissed = 1, is_new = 0 WHERE id = ?")
    .run(jobId);
}

function saveJob(jobId) {
  getDb()
    .prepare("UPDATE jobs SET is_saved = CASE WHEN is_saved = 1 THEN 0 ELSE 1 END WHERE id = ?")
    .run(jobId);
}

function logScrape(entry) {
  getDb()
    .prepare(
      `INSERT INTO scrape_log (company_slug, platform, status, jobs_found, new_jobs, error)
       VALUES (@company_slug, @platform, @status, @jobs_found, @new_jobs, @error)`
    )
    .run(entry);
}

function getStats() {
  const db = getDb();
  return {
    total: db.prepare("SELECT COUNT(*) as n FROM jobs WHERE is_dismissed = 0").get().n,
    unread: db.prepare("SELECT COUNT(*) as n FROM jobs WHERE is_new = 1 AND is_dismissed = 0").get().n,
    saved: db.prepare("SELECT COUNT(*) as n FROM jobs WHERE is_saved = 1").get().n,
    companies: db.prepare("SELECT COUNT(DISTINCT company_slug) as n FROM jobs WHERE is_dismissed = 0").get().n,
    today: db.prepare(
      "SELECT COUNT(*) as n FROM jobs WHERE date(discovered_at) = date('now') AND is_dismissed = 0"
    ).get().n,
  };
}

function getLastScrapeLog() {
  return getDb()
    .prepare("SELECT * FROM scrape_log ORDER BY scraped_at DESC LIMIT 50")
    .all();
}

function getSetting(key, defaultValue = null) {
  const row = getDb().prepare("SELECT value FROM settings WHERE key = ?").get(key);
  return row ? row.value : defaultValue;
}

function setSetting(key, value) {
  getDb()
    .prepare("INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)")
    .run(key, String(value));
}

module.exports = {
  getDb,
  isJobSeen,
  markJobSeen,
  insertJob,
  getJobs,
  markAsRead,
  markAllRead,
  dismissJob,
  saveJob,
  logScrape,
  getStats,
  getLastScrapeLog,
  getSetting,
  setSetting,
};
