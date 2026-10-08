const axios = require("axios");
const { TARGET_KEYWORDS, TARGET_ROLES } = require("../data/companies");
const { isJobSeen, markJobSeen, insertJob, logScrape } = require("../db/database");

const AXIOS_TIMEOUT = 15000;
const USER_AGENT =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36";

// ─── Relevance Filter ────────────────────────────────────────────────────────
function isRelevantJob(title, department = "") {
  const text = `${title} ${department}`.toLowerCase();

  const hasKeyword = TARGET_KEYWORDS.some((kw) => text.includes(kw));
  const hasRole = TARGET_ROLES.some((role) => text.includes(role));

  // Accept if it explicitly mentions an internship/new-grad keyword OR matches a role
  return hasKeyword || hasRole;
}

function normalizeLocation(loc) {
  if (!loc) return "Remote / Not specified";
  if (Array.isArray(loc)) return loc.join(", ");
  return String(loc).trim() || "Not specified";
}

// ─── Greenhouse ──────────────────────────────────────────────────────────────
async function scrapeGreenhouse(company) {
  const url = `https://boards-api.greenhouse.io/v1/boards/${company.slug}/jobs?content=true`;
  const res = await axios.get(url, {
    timeout: AXIOS_TIMEOUT,
    headers: { "User-Agent": USER_AGENT },
  });

  const jobs = res.data.jobs || [];
  const newJobs = [];

  for (const job of jobs) {
    const title = job.title || "";
    const department = (job.departments || []).map((d) => d.name).join(", ");

    if (!isRelevantJob(title, department)) continue;

    const jobId = `greenhouse_${company.slug}_${job.id}`;
    if (isJobSeen(jobId)) continue;

    const location = normalizeLocation(
      (job.offices || []).map((o) => o.name)
    );

    const jobRecord = {
      id: jobId,
      company: company.name,
      company_slug: company.slug,
      platform: "greenhouse",
      title: title.trim(),
      location,
      department,
      url: job.absolute_url || `https://boards.greenhouse.io/${company.slug}`,
      posted_at: job.updated_at || null,
      raw_json: JSON.stringify({ id: job.id, title, department }),
    };

    insertJob(jobRecord);
    markJobSeen(jobId, company.slug);
    newJobs.push(jobRecord);
  }

  return { total: jobs.length, newJobs };
}

// ─── Lever ───────────────────────────────────────────────────────────────────
async function scrapeLever(company) {
  const url = `https://api.lever.co/v0/postings/${company.slug}?mode=json`;
  const res = await axios.get(url, {
    timeout: AXIOS_TIMEOUT,
    headers: { "User-Agent": USER_AGENT },
  });

  const postings = Array.isArray(res.data) ? res.data : [];
  const newJobs = [];

  for (const post of postings) {
    const title = post.text || "";
    const department = post.categories?.team || post.categories?.department || "";

    if (!isRelevantJob(title, department)) continue;

    const jobId = `lever_${company.slug}_${post.id}`;
    if (isJobSeen(jobId)) continue;

    const location = normalizeLocation(
      post.categories?.location || post.workplaceType
    );

    const jobRecord = {
      id: jobId,
      company: company.name,
      company_slug: company.slug,
      platform: "lever",
      title: title.trim(),
      location,
      department,
      url: post.hostedUrl || `https://jobs.lever.co/${company.slug}`,
      posted_at: post.createdAt ? new Date(post.createdAt).toISOString() : null,
      raw_json: JSON.stringify({ id: post.id, title, department }),
    };

    insertJob(jobRecord);
    markJobSeen(jobId, company.slug);
    newJobs.push(jobRecord);
  }

  return { total: postings.length, newJobs };
}

// ─── Ashby ───────────────────────────────────────────────────────────────────
async function scrapeAshby(company) {
  const url = `https://api.ashbyhq.com/posting-api/job-board/${company.slug}`;
  const res = await axios.get(url, {
    timeout: AXIOS_TIMEOUT,
    headers: { "User-Agent": USER_AGENT },
  });

  const postings = res.data?.jobPostings || [];
  const newJobs = [];

  for (const post of postings) {
    const title = post.title || "";
    const department = post.departmentName || post.teamName || "";

    if (!isRelevantJob(title, department)) continue;

    const jobId = `ashby_${company.slug}_${post.id}`;
    if (isJobSeen(jobId)) continue;

    const location = normalizeLocation(
      post.isRemote ? "Remote" : post.locationName
    );

    const jobRecord = {
      id: jobId,
      company: company.name,
      company_slug: company.slug,
      platform: "ashby",
      title: title.trim(),
      location,
      department,
      url:
        post.jobUrl ||
        `https://www.ashbyhq.com/careers/${company.slug}`,
      posted_at: post.publishedDate || null,
      raw_json: JSON.stringify({ id: post.id, title, department }),
    };

    insertJob(jobRecord);
    markJobSeen(jobId, company.slug);
    newJobs.push(jobRecord);
  }

  return { total: postings.length, newJobs };
}

// ─── Workday ──────────────────────────────────────────────────────────────────
async function scrapeWorkday(company) {
  // We expect company.slug to be the full API endpoint: "https://{host}/wday/cxs/{tenant}/{site}/jobs"
  const apiUrl = company.slug.startsWith("http") ? company.slug : `https://${company.slug}`;
  
  let allPostings = [];
  
  // Workday returns 100 jobs max per request. Many enterprise companies have 1000+ jobs.
  // We fetch up to 1000 jobs to make sure we don't miss the internships/new-grad roles.
  for (let offset = 0; offset < 1000; offset += 100) {
    try {
      const res = await axios.post(apiUrl, {
        appliedFacets: {},
        limit: 100,
        offset: offset,
        searchText: ""
      }, {
        timeout: AXIOS_TIMEOUT,
        headers: { 
          "User-Agent": USER_AGENT,
          "Content-Type": "application/json",
          "Accept": "application/json"
        }
      });
      
      const postings = res.data?.jobPostings || [];
      allPostings = allPostings.concat(postings);
      if (postings.length < 100) break; // Reached the end
    } catch (e) {
      break;
    }
  }

  const newJobs = [];

  for (const post of allPostings) {
    const title = post.title || "";
    // Workday often doesn't give a department in the list API, so we rely on title
    const department = "";

    if (!isRelevantJob(title, department)) continue;

    const jobId = `workday_${company.name.replace(/\s+/g, '_')}_${post.bulletFields?.[0] || title}`;
    if (isJobSeen(jobId)) continue;

    const location = normalizeLocation(post.locationsText);
    
    // Convert API externalPath to a real URL
    // We expect company.urlBase to be like "https://nvidia.wd5.myworkdayjobs.com/en-US/NVIDIAExternalCareerSite"
    const url = company.urlBase ? `${company.urlBase}${post.externalPath}` : `${apiUrl}${post.externalPath}`;

    const jobRecord = {
      id: jobId,
      company: company.name,
      company_slug: company.slug.substring(0, 30), // keep it short
      platform: "workday",
      title: title.trim(),
      location,
      department,
      url,
      posted_at: post.postedOn || null,
      raw_json: JSON.stringify({ id: post.bulletFields?.[0], title }),
    };

    insertJob(jobRecord);
    markJobSeen(jobId, company.slug.substring(0, 30));
    newJobs.push(jobRecord);
  }

  return { total: postings.length, newJobs };
}

// ─── Main dispatcher ─────────────────────────────────────────────────────────
async function scrapeCompany(company) {
  const logEntry = {
    company_slug: company.slug.substring(0, 30),
    platform: company.platform,
    status: "ok",
    jobs_found: 0,
    new_jobs: 0,
    error: null,
  };

  try {
    let result;
    if (company.platform === "greenhouse") result = await scrapeGreenhouse(company);
    else if (company.platform === "lever") result = await scrapeLever(company);
    else if (company.platform === "ashby") result = await scrapeAshby(company);
    else if (company.platform === "workday") result = await scrapeWorkday(company);
    else throw new Error(`Unknown platform: ${company.platform}`);

    logEntry.jobs_found = result.total;
    logEntry.new_jobs = result.newJobs.length;
    logScrape(logEntry);
    return result.newJobs;
  } catch (err) {
    logEntry.status = "error";
    logEntry.error = err.message?.substring(0, 300);
    logScrape(logEntry);
    return [];
  }
}

module.exports = { scrapeCompany, isRelevantJob };
