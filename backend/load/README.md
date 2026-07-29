# BuddBull k6 Load Testing

Production-oriented HTTP load test for the BuddBull Express API.

**Tool:** [k6](https://k6.io)  
**Default profile (Staging):** 200 VUs · 3m ramp · 5m peak · p95 &lt; 500ms · error rate &lt; 1%  
**Auth model:** Firebase ID token → `Authorization: Bearer …` (the API does **not** expose email/password login)

There is **no Redis** in this stack. Persistence and jobs use **MongoDB** (+ Agenda).

---

## User flow under test

| Step | Request | Maps from template |
|------|---------|--------------------|
| 1 | `POST /api/v1/auth/sync` | Login / session bootstrap |
| 2 | `GET /users/me`, `/games/me`, `/notifications`, `/performance/stats` | Dashboard |
| 3 | `GET /api/v1/games?status=open&limit=20` | Browse |
| 4 | `POST /api/v1/games` | Create resource |

Realistic think-times: 1–3s after sync, 1–3s after dashboard, 2–5s after browse, 1–2s after create.

---

## Prerequisites

1. **API + MongoDB running** (local or staging).
2. Confirm health: `GET {BASE_URL}/health` → `200`.
3. **k6 installed** (see below).
4. A `tokens.json` file with **valid Firebase ID tokens** (one per test user; VUs round-robin).

Default API port in code is `3000` (`PORT` env). Docker Compose publishes **5000**. Set `BASE_URL` to match how you run the API.

### Install k6 (Windows)

```bash
winget install k6 --source winget
```

Other platforms: https://grafana.com/docs/k6/latest/set-up/install-k6/

---

## Prepare Firebase tokens

Firebase ID tokens expire (~1 hour). Refresh them before long runs.

1. Create N Firebase Auth test users (Console or Admin SDK).
2. Obtain ID tokens (client SDK `getIdToken()`, Auth emulator, or Identity Toolkit `signInWithPassword`).
3. Copy the example file and fill tokens:

```bash
cd backend/load
copy tokens.example.json tokens.json
# edit tokens.json — replace placeholders with real ID tokens
```

`tokens.json` is gitignored. Shape:

```json
{
  "tokens": [
    "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
  ]
}
```

A flat JSON array of strings is also accepted.

**Tip:** Prefer at least as many tokens as peak VUs so users are not heavily shared. Sharing is allowed (round-robin) but amplifies per-user write contention on create-game.

Optional later: a small Node prep script that signs in test emails via Firebase Auth REST and writes `tokens.json`. Not required for v1.

---

## Rate-limit warning

In `NODE_ENV=production`, the API applies **`express-rate-limit`**: default **500 requests / 15 minutes** on `/api/` ([`src/app.js`](../src/app.js)).

A Staging run (200 VUs) will blow past that and produce **429**s that look like app failures.

Before any serious load against a production-like process:

```bash
RATE_LIMIT_MAX=100000 RATE_LIMIT_WINDOW_MS=60000 NODE_ENV=production npm start
```

Or keep `NODE_ENV=development` for local runs (global limiter is disabled).

Do **not** point 200+ VUs at a live production cluster without an isolated DB and raised limits.

---

## Run from the CLI

```bash
cd backend/load

# Staging defaults (200 VUs, 3m ramp, 5m peak)
k6 run -e BASE_URL=http://localhost:5000 -e TOKEN_FILE=./tokens.json k6-core-flow.js

# Local app on default PORT=3000
k6 run -e BASE_URL=http://localhost:3000 -e TOKEN_FILE=./tokens.json k6-core-flow.js

# Smoke (safe for laptop)
k6 run -e BASE_URL=http://localhost:3000 -e VUS=20 -e RAMP=1m -e PEAK=2m -e TOKEN_FILE=./tokens.json k6-core-flow.js

# Prod-like profile (dedicated staging only)
k6 run -e BASE_URL=https://staging.example -e VUS=1000 -e RAMP=5m -e PEAK=10m -e TOKEN_FILE=./tokens.json k6-core-flow.js
```

### Environment variables

| Variable | Default | Meaning |
|----------|---------|---------|
| `BASE_URL` | `http://localhost:5000` | API origin (no trailing slash) |
| `VUS` | `200` | Peak virtual users |
| `RAMP` | `3m` | Ramp-up to peak |
| `PEAK` | `5m` | Sustained peak |
| `RAMP_DOWN` | `1m` | Ramp-down to 0 |
| `TOKEN_FILE` | `./tokens.json` | Firebase ID token list |

### Thresholds (fail the run if breached)

- `http_req_failed` rate **&lt; 1%**
- `http_req_duration{expected_response:true}` **p95 &lt; 500ms**
- Checks overall and per tag (`sync`, `dashboard`, `browse`, `create`) **&gt; 99%**

Checks assert status codes (`200` / `201`), `success === true`, and create responses include a game id.

---

## Charts and visualizations (k6 dashboard)

You do **not** need Artillery for charts. k6 has a built-in web dashboard and HTML report.

### Easiest (Windows helper)

```powershell
cd backend/load
.\run-with-dashboard.ps1
# or customize:
.\run-with-dashboard.ps1 -BaseUrl http://178.105.65.91:8000 -Vus 20 -Ramp 1m -Peak 2m
```

- **Live charts** while running: [http://localhost:5665](http://localhost:5665) (opens automatically)
- **Saved HTML report** after the run: `backend/load/reports/k6-report-*.html` (open in browser)
- **JSON summary**: `backend/load/reports/k6-summary-*.json`

### Manual command

```powershell
cd backend/load
$env:K6_WEB_DASHBOARD = "true"
$env:K6_WEB_DASHBOARD_OPEN = "true"
$env:K6_WEB_DASHBOARD_EXPORT = "reports/k6-report.html"

k6 run `
  -e BASE_URL=http://178.105.65.91:8000 `
  -e VUS=20 -e RAMP=1m -e PEAK=2m `
  -e TOKEN_FILE=./tokens.json `
  --summary-export=reports/k6-summary.json `
  k6-core-flow.js
```

Graphs appear in the HTML export when the test is long enough (roughly &gt; ~30s with default aggregation). Prefer runs of **1–2+ minutes** for useful charts.

### Heavier option later

Grafana Cloud / InfluxDB + Grafana for historical dashboards across many runs. Not required for day-to-day local reports.

---

## Server-side metrics to monitor during the run

| Layer | Watch | Why |
|-------|--------|-----|
| Node process | CPU %, event-loop lag, heap / RSS | Express + Socket.io single-process saturation |
| HTTP | req/s, p50/p95/p99, 4xx vs 5xx | Correlate with k6 thresholds |
| Rate limiter | **429** count | Prod limiter masks true capacity |
| MongoDB | connections, opcounters, query latency, WiredTiger cache, slow ops (&gt;100ms) | Search + concurrent `POST /games` writes |
| Mongoose pool | active vs available connections | Pool exhaustion → latency cliffs |
| Agenda / cron | job locks on the same Mongo | Background work during peak |
| OS | memory pressure, open FDs, network | Host saturation |
| Disk / uploads | I/O wait | Not in this flow; ignore unless other traffic hits uploads |

Optional deep dive (not during the primary measurement window): Clinic.js / Node inspector.

---

## Files

| File | Purpose |
|------|---------|
| [`k6-core-flow.js`](./k6-core-flow.js) | Main scenario |
| [`run-with-dashboard.ps1`](./run-with-dashboard.ps1) | Run with live charts + HTML/JSON reports |
| [`tokens.example.json`](./tokens.example.json) | Token file shape |
| `tokens.json` | Real tokens (local only, gitignored) |
| `reports/` | Generated HTML/JSON reports (gitignored) |

## Out of scope (v1)

- Socket.io chat / presence load
- Join-game contention storms across shared game IDs
- Artillery / Locust / JMeter equivalents
