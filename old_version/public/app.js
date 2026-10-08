/* ──────────────────────────────────────────────────────────────
   JobPulse — Frontend JavaScript
   ────────────────────────────────────────────────────────────── */

const API = "";  // same origin
let ws = null;
let currentFilter = "all";
let currentCompany = null;
let searchDebounce = null;
let allJobs = [];
let companies = [];
let companyCounts = {}; // slug -> job count

// ─── Init ─────────────────────────────────────────────────────
document.addEventListener("DOMContentLoaded", () => {
  connectWS();
  loadCompanies();
  loadStats();
  loadJobs();

  // Keyboard shortcut: Ctrl+K to focus search
  document.addEventListener("keydown", (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key === "k") {
      e.preventDefault();
      document.getElementById("search-input").focus();
    }
    if (e.key === "Escape") closeModal();
  });
});

// ─── WebSocket ────────────────────────────────────────────────
function connectWS() {
  const proto = location.protocol === "https:" ? "wss" : "ws";
  ws = new WebSocket(`${proto}://${location.host}`);

  ws.onopen = () => console.log("[WS] Connected");

  ws.onmessage = (evt) => {
    let msg;
    try { msg = JSON.parse(evt.data); } catch { return; }

    switch (msg.event) {
      case "scrape_start":
        setScrapeStatus("scanning", `Scanning ${msg.data.total} companies...`);
        showProgress(0, msg.data.total, "Starting...");
        break;

      case "scrape_progress":
        showProgress(msg.data.current, msg.data.total, msg.data.company);
        break;

      case "scrape_done":
        setScrapeStatus("done", `Done — ${msg.data.total_new} new jobs`);
        hideProgress();
        updateStats(msg.data.stats);
        if (msg.data.total_new > 0) {
          showToast("🎉 New Jobs Found!", `${msg.data.total_new} new postings just discovered`, "success");
          loadJobs();
          loadCompanies();
        } else {
          showToast("✅ Scan complete", "No new jobs this time", "");
        }
        document.getElementById("scan-btn").disabled = false;
        document.getElementById("scan-btn").innerHTML = '<span>🔍</span> Scan Now';
        break;

      case "new_jobs":
        showToast(`${msg.data.company}`, `${msg.data.count} new job(s) found!`, "success");
        // Prepend new jobs to grid
        msg.data.jobs.forEach(job => prependJobCard(job));
        break;

      case "all_read":
        document.querySelectorAll(".job-card.is-new").forEach(c => c.classList.remove("is-new"));
        document.querySelectorAll(".badge-new").forEach(b => b.remove());
        loadStats();
        break;
    }
  };

  ws.onclose = () => {
    console.log("[WS] Disconnected, reconnecting in 5s...");
    setTimeout(connectWS, 5000);
  };
}

// ─── Data loading ─────────────────────────────────────────────
async function loadJobs(filter = currentFilter, company = currentCompany, search = "") {
  const params = new URLSearchParams({ filter });
  if (company) params.set("company", company);
  if (search) params.set("search", search);

  const res = await fetch(`${API}/api/jobs?${params}`);
  allJobs = await res.json();
  renderJobs(allJobs);
}

async function loadStats() {
  const res = await fetch(`${API}/api/stats`);
  const stats = await res.json();
  updateStats(stats);

  if (stats.is_scraping) {
    setScrapeStatus("scanning", `Scanning... (${stats.scrape_progress.company || ""})`);
    showProgress(stats.scrape_progress.current, stats.scrape_progress.total, stats.scrape_progress.company);
  } else if (stats.last_scrape) {
    const dt = new Date(stats.last_scrape);
    setScrapeStatus("done", `Last: ${timeAgo(dt)}`);
  }
}

async function loadCompanies() {
  const res = await fetch(`${API}/api/companies`);
  companies = await res.json();

  document.getElementById("companies-count").textContent = companies.length;

  // Build company sidebar
  const list = document.getElementById("company-list");
  list.innerHTML = "";
  companies.forEach(c => {
    const btn = document.createElement("button");
    btn.className = "company-sidebar-item";
    btn.id = `sidebar-company-${c.slug}`;
    btn.onclick = () => filterByCompany(c.slug);
    btn.innerHTML = `
      <span class="company-emoji">${c.logo}</span>
      <span class="company-name">${c.name}</span>
      <span class="company-count" id="cc-${c.slug}" style="display:none">0</span>
    `;
    list.appendChild(btn);
  });

  // Build companies grid
  const grid = document.getElementById("companies-grid");
  grid.innerHTML = "";
  companies.forEach(c => {
    const div = document.createElement("div");
    div.className = "company-card";
    div.onclick = () => { filterByCompany(c.slug); setView("dashboard"); };
    div.innerHTML = `
      <span class="company-card-emoji">${c.logo}</span>
      <div class="company-card-name">${c.name}</div>
      <div class="company-card-platform">${c.platform}</div>
      <div class="company-card-jobs" id="gc-${c.slug}">Loading...</div>
    `;
    grid.appendChild(div);
  });

  // Load counts per company
  updateCompanyCounts();
}

async function updateCompanyCounts() {
  const res = await fetch(`${API}/api/jobs?filter=all`);
  const jobs = await res.json();

  companyCounts = {};
  jobs.forEach(j => {
    companyCounts[j.company_slug] = (companyCounts[j.company_slug] || 0) + 1;
  });

  companies.forEach(c => {
    const count = companyCounts[c.slug] || 0;
    const sidebarEl = document.getElementById(`cc-${c.slug}`);
    const gridEl = document.getElementById(`gc-${c.slug}`);
    if (sidebarEl) {
      if (count > 0) { sidebarEl.style.display = ""; sidebarEl.textContent = count; }
      else sidebarEl.style.display = "none";
    }
    if (gridEl) gridEl.textContent = count === 0 ? "No jobs yet" : `${count} job${count > 1 ? "s" : ""}`;
  });
}

async function loadLog() {
  const res = await fetch(`${API}/api/log`);
  const logs = await res.json();
  const tbody = document.getElementById("log-tbody");
  tbody.innerHTML = "";
  logs.forEach(l => {
    const tr = document.createElement("tr");
    const dt = new Date(l.scraped_at);
    tr.innerHTML = `
      <td>${l.company_slug}</td>
      <td><span style="text-transform:capitalize">${l.platform}</span></td>
      <td class="${l.status === "ok" ? "log-status-ok" : "log-status-error"}">${l.status === "ok" ? "✓ OK" : "✗ Error"}</td>
      <td>${l.jobs_found}</td>
      <td class="log-new-count">${l.new_jobs > 0 ? "+" + l.new_jobs : "—"}</td>
      <td>${timeAgo(dt)}</td>
      <td style="color:var(--accent-red);font-size:11px;max-width:200px;overflow:hidden;text-overflow:ellipsis">${l.error || "—"}</td>
    `;
    tbody.appendChild(tr);
  });
}

// ─── Rendering ────────────────────────────────────────────────
function renderJobs(jobs) {
  const grid = document.getElementById("jobs-grid");
  const empty = document.getElementById("empty-state");

  if (jobs.length === 0) {
    grid.innerHTML = "";
    empty.style.display = "flex";
    return;
  }
  empty.style.display = "none";
  grid.innerHTML = jobs.map(jobCardHTML).join("");
}

function jobCardHTML(job) {
  const company = companies.find(c => c.slug === job.company_slug);
  const emoji = company?.logo || "🏢";
  const isNew = job.is_new === 1;
  const isSaved = job.is_saved === 1;
  const discovered = new Date(job.discovered_at + "Z");

  return `
    <div class="job-card ${isNew ? "is-new" : ""}" id="card-${job.id}" onclick="openJobModal('${escapeJs(job.id)}')">
      <div class="job-card-header">
        <div class="job-company">
          <div class="company-emoji-badge">${emoji}</div>
          <div class="company-info">
            <div class="company-name-text">${escHtml(job.company)}</div>
            <div class="platform-badge">${job.platform}</div>
          </div>
        </div>
        <div class="job-badges">
          ${isNew ? '<span class="badge-new">NEW</span>' : ""}
          ${isSaved ? '<span class="badge-saved">⭐</span>' : ""}
        </div>
      </div>
      <div class="job-title">${escHtml(job.title)}</div>
      <div class="job-meta">
        <span class="job-meta-chip">📍 ${escHtml(job.location || "Remote")}</span>
        ${job.department ? `<span class="job-meta-chip">🏷️ ${escHtml(job.department)}</span>` : ""}
      </div>
      <div class="job-card-footer">
        <span class="job-time">${timeAgo(discovered)}</span>
        <div class="job-actions" onclick="event.stopPropagation()">
          <button class="job-action-btn ${isSaved ? "active" : ""}" title="Save" id="save-${job.id}" onclick="toggleSave(event, '${escapeJs(job.id)}')">⭐</button>
          <button class="job-action-btn" title="Dismiss" onclick="dismissJob(event, '${escapeJs(job.id)}')">✕</button>
        </div>
      </div>
    </div>
  `;
}

function prependJobCard(job) {
  const grid = document.getElementById("jobs-grid");
  const empty = document.getElementById("empty-state");
  empty.style.display = "none";

  // Only prepend if on the right view
  const div = document.createElement("div");
  div.innerHTML = jobCardHTML(job);
  const card = div.firstElementChild;
  card.style.animation = "toast-in 0.4s ease";
  grid.prepend(card);

  loadStats();
  updateCompanyCounts();
}

// ─── Actions ──────────────────────────────────────────────────
async function triggerScrape() {
  const btn = document.getElementById("scan-btn");
  btn.disabled = true;
  btn.innerHTML = '<span>⏳</span> Scanning...';

  const res = await fetch(`${API}/api/scrape`, { method: "POST" });
  if (!res.ok) {
    const err = await res.json();
    showToast("⚠️ Scan busy", err.error || "Already scanning", "warning");
    btn.disabled = false;
    btn.innerHTML = '<span>🔍</span> Scan Now';
  }
}

async function markAllRead() {
  await fetch(`${API}/api/jobs/read-all`, { method: "POST" });
  showToast("✓ Done", "All jobs marked as read", "success");
  loadStats();
  loadJobs(currentFilter, currentCompany);
}

async function toggleSave(e, jobId) {
  e.stopPropagation();
  await fetch(`${API}/api/jobs/${encodeURIComponent(jobId)}/save`, { method: "PATCH" });
  const btn = document.getElementById(`save-${jobId}`);
  if (btn) btn.classList.toggle("active");
  loadStats();
}

async function dismissJob(e, jobId) {
  e.stopPropagation();
  await fetch(`${API}/api/jobs/${encodeURIComponent(jobId)}/dismiss`, { method: "PATCH" });
  const card = document.getElementById(`card-${jobId}`);
  if (card) {
    card.style.transition = "opacity 0.3s, transform 0.3s";
    card.style.opacity = "0";
    card.style.transform = "scale(0.95)";
    setTimeout(() => card.remove(), 300);
  }
  loadStats();
}

// ─── Modal ────────────────────────────────────────────────────
let currentJobId = null;

async function openJobModal(jobId) {
  const job = allJobs.find(j => j.id === jobId);
  if (!job) return;

  currentJobId = jobId;

  // Mark as read
  if (job.is_new) {
    fetch(`${API}/api/jobs/${encodeURIComponent(jobId)}/read`, { method: "PATCH" });
    const card = document.getElementById(`card-${jobId}`);
    if (card) {
      card.classList.remove("is-new");
      const badge = card.querySelector(".badge-new");
      if (badge) badge.remove();
    }
    job.is_new = 0;
    loadStats();
  }

  const company = companies.find(c => c.slug === job.company_slug);
  const emoji = company?.logo || "🏢";
  const discovered = new Date(job.discovered_at + "Z");

  document.getElementById("modal-body").innerHTML = `
    <div class="modal-company-header">
      <div class="modal-company-emoji">${emoji}</div>
      <div>
        <div class="modal-company-name">${escHtml(job.company)} · <span style="color:var(--text-muted);font-size:12px;text-transform:capitalize">${job.platform}</span></div>
        <div class="modal-job-title">${escHtml(job.title)}</div>
      </div>
    </div>
    <div class="modal-meta-grid">
      <div class="modal-meta-item">
        <div class="modal-meta-label">📍 Location</div>
        <div class="modal-meta-value">${escHtml(job.location || "Not specified")}</div>
      </div>
      <div class="modal-meta-item">
        <div class="modal-meta-label">🏷️ Department</div>
        <div class="modal-meta-value">${escHtml(job.department || "Not specified")}</div>
      </div>
      <div class="modal-meta-item">
        <div class="modal-meta-label">📅 Discovered</div>
        <div class="modal-meta-value">${timeAgo(discovered)}</div>
      </div>
      <div class="modal-meta-item">
        <div class="modal-meta-label">📡 ATS Platform</div>
        <div class="modal-meta-value" style="text-transform:capitalize">${job.platform}</div>
      </div>
    </div>
    <div class="modal-actions">
      <a href="${escHtml(job.url)}" target="_blank" rel="noopener" class="btn-primary">
        🚀 Apply Now
      </a>
      <button class="btn-secondary" onclick="toggleSave(event, '${escapeJs(job.id)}')">
        ${job.is_saved ? "★ Saved" : "☆ Save"}
      </button>
      <button class="btn-secondary" onclick="dismissJob(event, '${escapeJs(job.id)}'); closeModal()">
        Dismiss
      </button>
    </div>
  `;

  document.getElementById("modal-overlay").style.display = "flex";
}

function closeModal() {
  document.getElementById("modal-overlay").style.display = "none";
  currentJobId = null;
}

// ─── Filters & Views ─────────────────────────────────────────
function setFilter(filter) {
  currentFilter = filter;
  currentCompany = null;

  // Update tabs
  ["all", "unread", "saved"].forEach(f => {
    document.getElementById(`tab-${f}`)?.classList.toggle("active", f === filter);
  });

  // Remove sidebar active highlight
  document.querySelectorAll(".company-sidebar-item").forEach(el => el.classList.remove("active"));

  loadJobs(filter, null, document.getElementById("search-input").value);
}

function filterByCompany(slug) {
  currentCompany = slug;
  currentFilter = "all";

  // Deselect filter tabs
  ["all", "unread", "saved"].forEach(f => {
    document.getElementById(`tab-${f}`)?.classList.remove("active");
  });

  // Highlight sidebar
  document.querySelectorAll(".company-sidebar-item").forEach(el => el.classList.remove("active"));
  const active = document.getElementById(`sidebar-company-${slug}`);
  if (active) active.style.fontWeight = "700";

  loadJobs("all", slug, document.getElementById("search-input").value);
}

function setView(view) {
  document.querySelectorAll(".view").forEach(v => v.classList.remove("active"));
  document.querySelectorAll(".nav-item").forEach(n => n.classList.remove("active"));

  document.getElementById(`view-${view}`)?.classList.add("active");
  document.getElementById(`nav-${view}`)?.classList.add("active");

  const titles = {
    dashboard: ["Job Notifications", "Monitoring Fortune 500 companies"],
    companies: ["Companies", "All monitored companies"],
    log: ["Scrape Log", "History of all scrape runs"],
  };
  const [title, subtitle] = titles[view] || ["", ""];
  document.getElementById("view-title").textContent = title;
  document.getElementById("view-subtitle").textContent = subtitle;

  if (view === "log") loadLog();
}

function toggleSidebar() {
  document.getElementById("sidebar").classList.toggle("collapsed");
}

// ─── Search debounce ─────────────────────────────────────────
function debounceSearch() {
  clearTimeout(searchDebounce);
  searchDebounce = setTimeout(() => {
    const val = document.getElementById("search-input").value.trim();
    loadJobs(currentFilter, currentCompany, val);
  }, 300);
}

// ─── Stats update ─────────────────────────────────────────────
function updateStats(stats) {
  if (!stats) return;
  const set = (id, val) => { const el = document.getElementById(id); if (el) el.textContent = val ?? "—"; };
  set("stat-unread", stats.unread);
  set("stat-today", stats.today);
  set("stat-total", stats.total);
  set("stat-companies", stats.companies || stats.companiesCount);
  set("stat-saved", stats.saved);
}

// ─── Scrape status ────────────────────────────────────────────
function setScrapeStatus(state, text) {
  const dot = document.getElementById("status-dot");
  const label = document.getElementById("status-text");
  dot.className = `status-dot ${state}`;
  label.textContent = text;
}

function showProgress(current, total, company) {
  const wrap = document.getElementById("progress-wrap");
  const bar = document.getElementById("progress-bar-fill");
  const txt = document.getElementById("progress-text");
  wrap.style.display = "flex";
  const pct = total > 0 ? Math.round((current / total) * 100) : 0;
  bar.style.width = `${pct}%`;
  txt.textContent = company ? `Scanning ${company}... (${current}/${total})` : "Starting...";
}

function hideProgress() {
  setTimeout(() => {
    document.getElementById("progress-wrap").style.display = "none";
  }, 1500);
}

// ─── Toast notifications ──────────────────────────────────────
function showToast(title, subtitle, type = "") {
  const container = document.getElementById("toast-container");
  const icon = type === "success" ? "✅" : type === "warning" ? "⚠️" : type === "error" ? "❌" : "ℹ️";

  const toast = document.createElement("div");
  toast.className = `toast ${type}`;
  toast.innerHTML = `
    <span class="toast-icon">${icon}</span>
    <div class="toast-text">
      <div class="toast-title">${escHtml(title)}</div>
      ${subtitle ? `<div class="toast-subtitle">${escHtml(subtitle)}</div>` : ""}
    </div>
  `;

  container.appendChild(toast);

  setTimeout(() => {
    toast.style.animation = "toast-out 0.3s ease forwards";
    setTimeout(() => toast.remove(), 320);
  }, 4500);
}

// ─── Helpers ──────────────────────────────────────────────────
function timeAgo(date) {
  const now = new Date();
  const diff = now - date;
  if (isNaN(diff)) return "Unknown";
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return "Just now";
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days === 1) return "Yesterday";
  if (days < 7) return `${days}d ago`;
  return date.toLocaleDateString();
}

function escHtml(str) {
  if (!str) return "";
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function escapeJs(str) {
  return String(str).replace(/'/g, "\\'").replace(/\\/g, "\\\\");
}
