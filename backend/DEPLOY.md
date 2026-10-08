# Deploying the backend to Render (free tier)

Everything code-side is ready (`Dockerfile`, `render.yaml`, `/health` endpoint). The remaining
steps need your own accounts — I can't create those for you. Takes about 5 minutes.

## 1. Push this repo to GitHub

```bash
# From the aline/ project root:
gh repo create aline --private --source=. --remote=origin   # if you have gh CLI + are logged in
# OR, without gh CLI: create a new empty repo at github.com/new, then:
git remote add origin https://github.com/<your-username>/aline.git
git branch -M main
git push -u origin main
```

## 2. Create a Render account and connect the repo

1. Go to https://render.com and sign up (GitHub OAuth is the fastest option — it'll also
   grant repo access in the same step).
2. Click **New +** → **Blueprint**.
3. Select the `aline` repo you just pushed. Render will detect `backend/render.yaml`
   automatically and show the `aline-backend` service it defines.
4. Click **Apply** / **Create**. Render builds the Dockerfile and deploys — first build takes
   a few minutes.

## 3. Get the live URL

Once deployed, Render gives you a URL like `https://aline-backend.onrender.com`. Test it:

```bash
curl https://aline-backend.onrender.com/health
curl https://aline-backend.onrender.com/companies
```

## 4. Point the iOS app at it

In `ios/Aline/Networking/JobsAPI.swift`, change:

```swift
static let baseURL = URL(string: "http://127.0.0.1:8000")!
```

to your Render URL. (I'll do this part once you have the live URL — just paste it back to me.)

## Known trade-off on the free tier

Render's free web services spin down after 15 minutes of no traffic, and take about a minute
to wake up on the next request. The backend already handles this gracefully (the `/jobs`
endpoint waits for a fresh scrape if the cache is cold rather than returning nothing) — so the
first request after idle time is just slower, not broken. Fine for TestFlight-stage testing;
if it becomes annoying later, Render's $7/mo Starter tier removes the spin-down.
