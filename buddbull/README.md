# BuddBull — Social-Sport Platform

> Connect people for physical activities, group matches, and performance tracking.

---

## Tech Stack

| Layer        | Technology                               |
|--------------|------------------------------------------|
| Frontend     | Flutter (iOS & Android)                  |
| Backend      | Node.js 18+ · Express 4                  |
| Database     | MongoDB 7 · Mongoose 8                   |
| Real-time    | Socket.io 4                              |
| Auth         | JWT (access + refresh tokens) · bcryptjs |
| Email        | Nodemailer (SendGrid)                    |
| File storage | Local (dev) · AWS S3 (prod)              |
| Logging      | Winston                                  |
| Testing      | Jest · Supertest                         |
| Lint/Format  | ESLint (Airbnb) · Prettier               |
| DevOps       | Docker · GitHub Actions                  |

---

## Repository Structure

```
buddbull/
├── frontend/          # Flutter app (iOS & Android)
├── backend/           # Node.js / Express / MongoDB API
└── README.md
```

---

## Frontend (`frontend/`)

Flutter app for BuddBull — auth, games, performance, chat, ratings, admin.

### Stack
- **SDK:** Dart ≥3.5, Flutter ≥3.24
- **State:** Riverpod
- **Navigation:** go_router
- **Networking:** Dio, Socket.io client
- **Storage:** flutter_secure_storage, shared_preferences
- **UI:** Google Fonts, cached_network_image, image_picker, shimmer, fl_chart, table_calendar
- **Firebase:** firebase_core

### Layout

```
frontend/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/                    # Shared app layer
│   │   ├── constants/           # app_colors, app_text_styles
│   │   ├── network/             # api_client, api_endpoints
│   │   ├── router/              # app_router
│   │   ├── services/            # socket_service
│   │   └── theme/               # app_theme
│   ├── features/
│   │   ├── auth/                # login, register, forgot password, providers, repositories
│   │   ├── home/                # home_scaffold, home_screen
│   │   ├── profile/             # profile, edit profile, user_repository, stats
│   │   ├── games/               # games list, create game, calendar, game detail, filters
│   │   ├── performance/        # logs, create log, heatmap, streak, progress chart
│   │   ├── chat/                # chat list, chat screen, message bubbles, pinned
│   │   ├── rating/              # rate player, rating stars, rating repository
│   │   └── admin/               # admin dashboard, stat cards, admin repository
│   └── shared/
│       └── widgets/             # bb_button, bb_text_field, loading_overlay, error_view
├── assets/                      # images, icons, lottie
├── pubspec.yaml
└── (android/, ios/, etc.)
```

### Run

```bash
cd buddbull/frontend
flutter pub get
flutter run
```

### Build

```bash
flutter build apk
flutter build ios
```

---

## Backend (`backend/`)

Node.js / Express API — auth, users, games, performance, chat, ratings, admin, Socket.io.

### Layout

```
backend/
├── src/
│   ├── config/
│   │   ├── database.js          # Mongoose connection, retry & graceful shutdown
│   │   └── environment.js       # Joi-validated env loader
│   ├── models/
│   │   ├── User.model.js
│   │   ├── Game.model.js
│   │   ├── PerformanceLog.model.js
│   │   ├── Chat.model.js
│   │   ├── Message.model.js
│   │   ├── Rating.model.js
│   │   └── SportCategory.model.js
│   ├── routes/
│   │   ├── auth.routes.js
│   │   ├── user.routes.js
│   │   ├── game.routes.js
│   │   ├── performance.routes.js
│   │   ├── chat.routes.js
│   │   ├── rating.routes.js
│   │   └── admin.routes.js
│   ├── controllers/             # auth, user, game, performance, chat, rating, admin
│   ├── services/                # business logic + notification.service, admin.service
│   ├── validators/              # Joi/express-validator per domain
│   ├── middleware/
│   │   ├── auth.middleware.js
│   │   ├── upload.middleware.js
│   │   ├── errorHandler.js
│   │   └── notFound.js
│   ├── socket/
│   │   └── socket.manager.js
│   ├── utils/
│   │   ├── logger.js
│   │   ├── email.js
│   │   ├── token.js
│   │   ├── catchAsync.js
│   │   ├── AppError.js
│   │   └── csvExport.js
│   └── app.js                   # Express app (security, CORS, rate-limit)
├── tests/                       # Jest unit & integration
├── .env.example                 # Copy to .env and fill in
├── package.json
├── server.js                    # HTTP + Socket.io entry
└── Dockerfile
```

### Prerequisites
- Node.js ≥18
- MongoDB 7 (local or Atlas)

### Install & run

```bash
cd buddbull/backend
npm install
cp .env.example .env
# Edit .env: MONGO_URI, JWT_SECRET, JWT_REFRESH_SECRET, email, etc.
```

```bash
npm run dev        # development (nodemon)
NODE_ENV=production npm start   # production
```

### Tests, lint, format

```bash
npm test
npm run test:watch
npm run test:coverage
npm run lint
npm run format
```

### Environment variables

See `backend/.env.example`. Minimum: `MONGO_URI`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, email settings.

---

## Build Phases

| Phase | Scope                                            | Status      |
|-------|--------------------------------------------------|-------------|
| 1     | Project Init · DB Schemas                        | Complete    |
| 2     | Auth Service · JWT Middleware · User CRUD        | Pending     |
| 3     | Matchmaking & Groups API · Geographic queries    | Pending     |
| 4     | Flutter Architecture · Auth UI · Profile screens | Pending     |
| 5     | Flutter Core — Matchmaking · Calendar · Stats    | Pending     |
| 6     | Real-time Chat (Socket.io) · Rating System       | Pending     |
| 7     | Admin Dashboard · Docker · GitHub Actions CI/CD  | Pending     |

---

## Security Highlights

- Passwords hashed with **bcrypt** (min 12 rounds, configurable).
- JWT access tokens (short-lived) + refresh tokens (long-lived, stored as hash).
- **Never** stores precise GPS coordinates — geographic queries use city / neighbourhood / postal code.
- `helmet` HTTP security headers on all responses.
- `express-mongo-sanitize` prevents NoSQL injection.
- Global rate limiter (`express-rate-limit`) on all `/api/` routes.
- CORS whitelist — only approved origins accepted.
- Centralised error handler prevents stack-trace leaks in production.

---

## Data Models Summary

### User
Auth credentials, role (player/organizer/admin), sports interests with skill levels,
privacy-safe location (city + neighbourhood + radius preference), social graph (followers/following),
aggregate stats (games played, win rate, streaks, community rating), push tokens, soft delete.

### Game
Title, sport, organizer, schedule (date + duration), area-level location, capacity (min/max),
player slots with approval workflow, skill filter, lifecycle status, merge support, group chat ref,
double-booking detection via `hasConflict` static.

### PerformanceLog
Match results and standalone training sessions. Sport-agnostic flexible KV stats, universal
physical metrics, mood, self-rating, personal best snapshots, streak capture, aggregation
pipeline for dashboard stats.

### Chat
Group (tied to a Game) and DM (2-person) rooms. Per-participant read pointers for unread counts,
mute preferences, last-message denormalised snapshot, pinned messages (max 5).

### Message
Paginated message feed per chat. Types: text, image, video, file, system. Reply threading,
emoji reactions (Map), read receipts, soft delete (content replaced), edit audit trail (original
content retained for moderation, `select: false`).

### Rating
Post-game peer ratings — reliability score (1–5) + behavior score (1–5) → composite score.
One rating per rater–ratee–game triple (unique index). Post-save hook rolls up into
`User.stats.averageRating`. Anonymous option. Admin moderation flags. Distribution aggregation
pipeline for profile rating card.
