# BuddBull — Social-Sport Platform

> Connect people for physical activities, group matches, and performance tracking.

BuddBull lets users discover open games nearby, join or organize them, chat with the group in real time,
log their own performance, rate other players after a game, and manage a friends network. Admins get a
dedicated dashboard for users, games, reports and sport categories.

Full technical documentation (Hebrew): [`docs/BuddBull_Technical_Documentation_HE.html`](docs/BuddBull_Technical_Documentation_HE.html)
([PDF](docs/BuddBull_Technical_Documentation_HE.pdf)). It is the source of truth for architecture, data model,
REST API, Socket.io events, notifications and code-review findings.

---

## Tech Stack

| Layer          | Technology                                                                 |
|----------------|----------------------------------------------------------------------------|
| Mobile app     | Flutter 3.24+ (Dart 3.5+) · Riverpod · go_router · Dio                     |
| Backend        | Node.js 20 · Express 4                                                     |
| Database       | MongoDB (Atlas or local) · Mongoose 8                                      |
| Real-time      | Socket.io 4                                                                |
| Auth           | **Firebase Authentication** (ID tokens verified server-side via Firebase Admin SDK) |
| Push           | Firebase Cloud Messaging (FCM) with deep-link routing                      |
| Background jobs| Agenda (one-off pre-game reminders, persisted in MongoDB) · node-cron (hourly auto-complete, daily retention) |
| Maps           | Google Places API (New) + Static Maps, proxied through the server          |
| Validation     | Joi                                                                        |
| Security       | helmet · cors · express-mongo-sanitize · express-xss-sanitizer · express-rate-limit (production) |
| File storage   | Local disk (`uploads/`). `UPLOAD_DRIVER=s3` is not implemented yet         |
| Logging        | Winston · Morgan                                                           |
| Testing        | Jest · Supertest · mongodb-memory-server · Flutter test · mocktail · k6 · Artillery |
| Lint/Format    | ESLint (Airbnb) · Prettier · flutter_lints                                 |
| DevOps         | Docker · docker-compose · Nginx · GitHub Actions                           |

> Passwords are managed entirely by Firebase; the server stores none. Email sending is currently a stub
> (logs a warning only).

---

## Repository Structure

```
BuddBull/
├── backend/               # Node.js / Express API
│   ├── server.js          # Entry point: DB, HTTP, Socket.io, Agenda, cron
│   ├── src/
│   │   ├── app.js         # Express factory (middleware + routes)
│   │   ├── config/        # environment.js (Joi), database.js, agenda.js
│   │   ├── middleware/    # auth, errorHandler, notFound, upload (multer)
│   │   ├── routes/        # 10 routers under /api/v1
│   │   ├── validators/    # Joi schemas
│   │   ├── controllers/   # thin HTTP adapters
│   │   ├── services/      # business logic
│   │   ├── models/        # 11 Mongoose models
│   │   ├── socket/        # socket.manager.js
│   │   └── utils/
│   ├── tests/             # Jest + Supertest
│   ├── load/              # k6 load tests + token generator
│   ├── scripts/           # seed / cleanup scripts
│   └── Dockerfile         # multi-stage: deps / development / production
├── frontend/              # Flutter app
│   ├── lib/
│   │   ├── core/          # network, router, services, theme, storage, location
│   │   ├── features/      # 13 feature modules (data / providers / presentation)
│   │   └── shared/widgets/
│   ├── test/              # widget + provider tests
│   └── Dockerfile         # builds a release APK
├── docs/                  # Technical documentation, UML (PlantUML + SVG), Qase test cases, presentation
├── docker-compose.yml     # local API container (MongoDB is external)
├── nginx.conf             # production reverse proxy (TLS, WebSocket upgrade)
└── .github/workflows/buddbull-ci.yml
```

---

## Features

- **Games** — create/edit/cancel, search by text, sport, city, neighborhood, skill level and dates, geo search by
  radius, direct join or approval-based join, invitations, schedule-conflict prevention, merging two
  under-filled games, manual or automatic completion, private games.
- **Chat** — automatic group chat per game and DMs, real-time via Socket.io, typing indicator, pinned messages
  (max 5), soft delete, unread counts, immediate access revocation when a player leaves or is removed.
- **Notifications** — in-app inbox, live Socket updates and FCM push; pre-game reminder (1 hour before) and a
  daily retention reminder.
- **Performance** — training/match/fitness logs, personal bests, activity streak, heatmap, weekly chart, per-sport
  breakdown, leaderboard.
- **Ratings** — post-game reliability and behavior scores (1–5), optional anonymity, pending-ratings queue.
- **Friends & profile** — sports and skill levels, location and radius, avatar or photo, friend requests,
  user search, onboarding flow.
- **Reports** — report users or games (harassment, unsafe play, cheating, other) with 24h duplicate prevention.
- **Admin** — dashboard (users, games, churn, daily signups), ban/restrict/delete users, delete games, handle
  reports, CSV export, broadcast, sport category management.

User roles are `player`, `organizer` and `admin`. Organizer permissions derive from game ownership; `admin`
unlocks `/api/v1/admin/*`. Admins can also set `isBanned` (blocked entirely) and `isRestricted` (read-only: cannot
create/join games or send messages).

---

## Backend (`backend/`)

### Prerequisites
- Node.js 20
- MongoDB (local or Atlas)
- A Firebase project with a service account (for token verification and FCM)
- A Google Maps API key with Places API (New) and Static Maps enabled (for `/maps/*`)

### Install & run

```bash
cd backend
npm install
# create backend/.env (see variables below)
npm run dev                      # development (nodemon)
NODE_ENV=production npm start    # production
```

The API is served under `/api/v1`; `GET /health` is an unauthenticated liveness check.

### Environment variables

| Variable | Default | Notes |
|---|---|---|
| `NODE_ENV` | `development` | Affects rate limiting, log level, Socket CORS |
| `PORT` / `HOST` | `3000` / `0.0.0.0` | Set `PORT` explicitly (Docker compose maps 8000 and 5000 to container port 5000) |
| `MONGO_URI` | required | Must start with `mongodb://` or `mongodb+srv://` (multi-host Atlas URIs supported) |
| `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` | — | Service account. If missing, auth falls back to application default credentials and FCM is silently disabled |
| `GOOGLE_MAPS_API_KEY` | empty | If empty, `/maps/*` returns 500 |
| `CLIENT_URL` | `http://localhost:3000` | Allowed CORS origin |
| `RATE_LIMIT_WINDOW_MS` / `RATE_LIMIT_MAX` | `900000` / `500` | Applied in production only |
| `UPLOAD_DRIVER` / `UPLOAD_DIR` | `local` / `uploads/` | `s3` switches multer to memory storage; S3 upload is not implemented |
| `PRE_GAME_REMINDER_MS` | `3600000` | How long before a game the reminder is sent |
| `RETENTION_CRON_HOUR` / `RETENTION_CRON_TZ` | `19` / `UTC` | Daily retention reminder schedule |
| `JWT_SECRET`, `JWT_REFRESH_SECRET`, `EMAIL_HOST/USER/PASS` | required by validation | Legacy: still required by the Joi schema but not used (auth is Firebase, email is a stub) |

### Tests, lint, format

```bash
npm test                  # Jest on in-memory MongoDB, Firebase Admin mocked
npm run test:watch
npm run test:coverage
npm run lint
npm run format
```

About 131 backend tests across 14 files.

### Seed data

```bash
npm run seed:games            # 20 sample games (--count, --dry-run)
npm run seed:demo-activity    # demo performance logs and activity
```

### Load tests

- **k6** (`backend/load/`): full user flow with up to 200 VUs; see `backend/load/README.md`.
- **Artillery**: `npm run load-test` (public routes `/health`, `/games`).

---

## Frontend (`frontend/`)

Flutter app, feature-first architecture (`data/` → `providers/` → `presentation/`) with Riverpod.
13 feature modules: auth, onboarding, home, games, chat, notifications, performance, profile, rating, reports,
search, admin and settings.

### Run

```bash
cd frontend
flutter pub get
flutter run
```

The API base URL defaults to the current production server and can be overridden:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1   # Android emulator → local API
```

Firebase must be configured for the app (Auth + Messaging).

### Test & build

```bash
flutter analyze
flutter test              # ~60 tests
flutter build apk --release
```

---

## Docker & Deployment

- `docker-compose.yml` runs the API in the `development` stage with hot reload, `env_file: backend/.env`, a
  persistent `uploads_data` volume and a healthcheck on `/health`. **MongoDB is not included**; use Atlas or a
  local instance.
- `backend/Dockerfile` production stage runs as a non-root user with a `HEALTHCHECK`.
- `frontend/Dockerfile` builds the release APK.
- `nginx.conf` is the production reverse proxy: HTTP→HTTPS, TLS 1.2/1.3, WebSocket upgrade for `/socket.io/`,
  `/api/` proxy, and cached `/uploads/`.

```bash
docker compose up --build
```

## CI

`.github/workflows/buddbull-ci.yml` runs on push/PR to `main` (path-filtered) and manually:
backend lint + tests (Node 20), and frontend `flutter analyze`, `flutter test` and a release APK build
(uploaded as an artifact).

---

## Security Highlights

- Identity is handled by Firebase; the server verifies the ID token on every HTTP request and Socket handshake.
- `helmet` security headers, CORS allow-list, `express-mongo-sanitize` (NoSQL injection), `express-xss-sanitizer`.
- Rate limiting on `/api/` in production (500 req / 15 min) and on `/admin` (200 req / 15 min).
- Request body limited to 10KB; uploads restricted to JPEG/PNG/WebP up to 5MB.
- Centralized error handler hides stack traces in production.
- Games store venue coordinates (GeoJSON, `2dsphere` index) for nearby search; user profiles store
  city/neighborhood and a search radius, not live GPS position.
- Google Maps key stays on the server (proxy endpoints).

Known issues and recommendations are listed in section 15 of the technical documentation.

---

## Data Models (11 collections)

`User`, `Game`, `Chat`, `Message`, `Rating`, `RatingDismissal`, `PerformanceLog`, `Notification`,
`FriendRequest`, `Report`, `SportCategory` — plus `agendaJobs`, managed by Agenda for pre-game reminders.
Field-level details are in section 4 of the technical documentation.

---

## More Documentation

- `docs/BuddBull_Technical_Documentation_HE.html` / `.pdf` — full technical documentation
- `docs/*.svg`, `docs/buddbull-uml.puml` — UML diagrams (architecture, domain model, sequences)
- `docs/qase-manual-test-cases.md` — manual test cases
- `docs/presentation/` — project defense presentation
