# BuddBull

BuddBull is a social sports platform with a Node.js/Express backend and a Flutter mobile frontend. The backend provides REST APIs and Socket.IO real-time events for auth, users, games, chats, ratings, and admin features.

## Tech Stack

- Backend: Node.js, Express, MongoDB (Mongoose), Socket.IO, JWT auth
- Frontend: Flutter (Dart), Dio, Riverpod
- Dev infrastructure: Docker Compose (MongoDB, Mongo Express, Redis, API)
- Reverse proxy (production): Nginx (`nginx.conf`)

## Repository Structure

```text
BuddBull/
  backend/              # Node.js API server
  frontend/             # Flutter application
  docker-compose.yml    # Local development services
  nginx.conf            # Production reverse proxy example
```

## Prerequisites

- Node.js 18+ (Node 20 recommended)
- npm 9+
- Flutter 3.24+ and Dart 3.5+
- Docker Desktop (optional, recommended for local services)

## Quick Start (Docker)

1. Create `backend/.env` with required variables (see below).
2. Start the local stack:

```bash
docker compose up -d
```

3. Check API health:

- API health endpoint: `http://localhost:5000/health`
- Mongo Express UI: `http://localhost:8081`

4. Stream API logs (optional):

```bash
docker compose logs -f api
```

5. Stop services:

```bash
docker compose down
```

## Local Development (Without Docker)

### Backend

```bash
cd backend
npm install
npm run dev
```

The backend runs on `http://localhost:5000` by default.

### Frontend

```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1
```

`API_BASE_URL` defaults to `http://10.0.2.2:5000/api/v1` if not provided.

## Backend Environment Variables

Create `backend/.env` and define the required values:

```env
NODE_ENV=development
PORT=5000

MONGO_URI=mongodb://admin:secret@localhost:27017/buddbull?authSource=admin

JWT_SECRET=replace_with_min_32_char_secret
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=replace_with_min_32_char_refresh_secret
JWT_REFRESH_EXPIRES_IN=30d

BCRYPT_SALT_ROUNDS=12

EMAIL_HOST=smtp.example.com
EMAIL_PORT=587
EMAIL_SECURE=false
EMAIL_USER=your_user
EMAIL_PASS=your_password
EMAIL_FROM=BuddBull <noreply@buddbull.app>

UPLOAD_DRIVER=local
UPLOAD_DIR=uploads/

RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100

CLIENT_URL=http://localhost:3000
```

## Useful Commands

### Backend (`backend/`)

- `npm run dev` - start with nodemon
- `npm start` - start in normal mode
- `npm test` - run tests
- `npm run test:coverage` - run tests with coverage
- `npm run lint` - run ESLint
- `npm run lint:fix` - auto-fix lint issues

### Frontend (`frontend/`)

- `flutter pub get` - install dependencies
- `flutter run` - launch app
- `flutter test` - run tests
- `flutter analyze` - run static analysis

## API Base Paths

- Health: `/health`
- Auth: `/api/v1/auth`
- Users: `/api/v1/users`
- Games: `/api/v1/games`
- Performance: `/api/v1/performance`
- Chats: `/api/v1/chats`
- Ratings: `/api/v1/ratings`
- Admin: `/api/v1/admin`

## Notes

- The backend validates environment variables on startup and will fail fast if required values are missing.
- Docker Compose expects a `backend/.env` file to exist before bringing up the API service.
