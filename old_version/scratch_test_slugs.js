const axios = require('axios');

const greenhouseSlugs = ['pinterest', 'roku', 'asana', 'patreon', 'zapier', 'webflow', 'postman', 'affirm', 'docusign', 'box', 'peloton', 'coursera', 'udemy', 'masterclass', 'quora', 'discord', 'reddit', 'canva', 'foursquare', 'classpass', 'instacart', 'doordash', 'glassdoor'];

const leverSlugs = ['yelp', 'canva', 'figma', 'gong', 'kiva', 'hopper', 'klook', 'leverdemo'];

const ashbySlugs = ['glean', 'vanta', 'mutiny', 'clay', 'ramp', 'notion', 'brex', 'ironclad', 'linear', 'arc', 'chronosphere'];

async function checkSlugs() {
  console.log("Checking Greenhouse...");
  for (const slug of greenhouseSlugs) {
    try {
      const res = await axios.get(`https://boards-api.greenhouse.io/v1/boards/${slug}/jobs`, { timeout: 5000 });
      console.log(`[Greenhouse] ${slug} -> ${res.data.jobs?.length || 0} jobs`);
    } catch (e) {
      // ignore
    }
  }

  console.log("Checking Lever...");
  for (const slug of leverSlugs) {
    try {
      const res = await axios.get(`https://api.lever.co/v0/postings/${slug}?mode=json`, { timeout: 5000 });
      console.log(`[Lever] ${slug} -> ${res.data?.length || 0} jobs`);
    } catch (e) {
      // ignore
    }
  }

  console.log("Checking Ashby...");
  for (const slug of ashbySlugs) {
    try {
      const res = await axios.get(`https://api.ashbyhq.com/posting-api/job-board/${slug}`, { timeout: 5000 });
      console.log(`[Ashby] ${slug} -> ${res.data?.jobPostings?.length || 0} jobs`);
    } catch (e) {
      // ignore
    }
  }
}

checkSlugs();
