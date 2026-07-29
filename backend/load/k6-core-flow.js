/**
 * BuddBull — k6 core user-flow load test
 *
 * Flow per VU iteration:
 *   1. POST /api/v1/auth/sync          (Firebase Bearer → Mongo user)
 *   2. Dashboard reads (me / games / notifications / performance)
 *   3. GET  /api/v1/games               (browse open games)
 *   4. POST /api/v1/games               (create entity)
 *
 * Staging defaults: 200 VUs, 3m ramp, 5m peak, p95 < 500ms, errors < 1%.
 *
 * Env:
 *   BASE_URL    API origin (default http://localhost:5000)
 *   VUS         peak virtual users (default 200)
 *   RAMP        ramp-up duration (default 3m)
 *   PEAK        sustained peak duration (default 5m)
 *   RAMP_DOWN   ramp-down duration (default 1m)
 *   TOKEN_FILE  path to tokens JSON (default ./tokens.json)
 */

import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { SharedArray } from 'k6/data';
import exec from 'k6/execution';

const BASE_URL = (__ENV.BASE_URL || 'http://localhost:5000').replace(/\/$/, '');
const VUS = Number(__ENV.VUS || 200);
const RAMP = __ENV.RAMP || '3m';
const PEAK = __ENV.PEAK || '5m';
const RAMP_DOWN = __ENV.RAMP_DOWN || '1m';
const TOKEN_FILE = __ENV.TOKEN_FILE || './tokens.json';

const tokens = new SharedArray('firebase_id_tokens', () => {
  const raw = JSON.parse(open(TOKEN_FILE));
  const list = Array.isArray(raw) ? raw : raw.tokens;
  if (!Array.isArray(list) || list.length === 0) {
    throw new Error(
      `TOKEN_FILE (${TOKEN_FILE}) must be a JSON array of tokens or { "tokens": ["..."] } with ≥1 entry`,
    );
  }
  return list.map((t) => String(t).trim()).filter(Boolean);
});

export const options = {
  stages: [
    { duration: RAMP, target: VUS },
    { duration: PEAK, target: VUS },
    { duration: RAMP_DOWN, target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],
    'http_req_duration{expected_response:true}': ['p(95)<500'],
    checks: ['rate>0.99'],
    'checks{endpoint:sync}': ['rate>0.99'],
    'checks{endpoint:dashboard}': ['rate>0.99'],
    'checks{endpoint:browse}': ['rate>0.99'],
    'checks{endpoint:create}': ['rate>0.99'],
  },
  summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

function authHeaders(token) {
  return {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
    Accept: 'application/json',
  };
}

function pickToken() {
  const vu = exec.vu.idInTest;
  return tokens[(vu - 1) % tokens.length];
}

function randomBetween(min, max) {
  return min + Math.random() * (max - min);
}

function parseJson(res) {
  try {
    return res.json();
  } catch {
    return null;
  }
}

function futureScheduledAt(hoursAhead) {
  return new Date(Date.now() + hoursAhead * 60 * 60 * 1000).toISOString();
}

function buildCreateGameBody(vu, iter) {
  return {
    title: `Load Test Game VU${vu}-I${iter}-${Date.now()}`,
    description: 'Created by k6 core-flow load test',
    sport: 'basketball',
    scheduledAt: futureScheduledAt(24 + (vu % 48)),
    durationMinutes: 90,
    location: {
      neighborhood: 'Downtown',
      city: 'Tel Aviv',
      country: 'IL',
      venueName: 'Load Test Court',
      // GeoJSON [lng, lat] — required by deployed API validation
      coordinates: {
        type: 'Point',
        coordinates: [34.7818, 32.0853],
      },
    },
    maxPlayers: 10,
    minPlayersToStart: 2,
    isPrivate: false,
    requiresApproval: false,
  };
}

export function setup() {
  const health = http.get(`${BASE_URL}/health`);
  const ok = check(health, {
    'setup: /health is 200': (r) => r.status === 200,
  });
  if (!ok) {
    throw new Error(
      `API health check failed at ${BASE_URL}/health (status ${health.status}). Start the API before load testing.`,
    );
  }
  return {
    baseUrl: BASE_URL,
    tokenCount: tokens.length,
    vus: VUS,
  };
}

export default function () {
  const token = pickToken();
  const headers = authHeaders(token);
  const vu = exec.vu.idInTest;
  const iter = exec.vu.iterationInScenario;

  group('1_auth_sync', () => {
    const res = http.post(
      `${BASE_URL}/api/v1/auth/sync`,
      JSON.stringify({
        firstName: `Load`,
        lastName: `User${vu}`,
        role: 'player',
      }),
      { headers, tags: { endpoint: 'sync', name: 'POST /auth/sync' } },
    );
    const body = parseJson(res);
    check(
      res,
      {
        'sync status 200': (r) => r.status === 200,
        'sync success true': () => body && body.success === true,
        'sync has user': () => body && body.data && body.data.user != null,
      },
      { endpoint: 'sync' },
    );
  });

  sleep(randomBetween(1, 3));

  group('2_dashboard', () => {
    const responses = http.batch([
      ['GET', `${BASE_URL}/api/v1/users/me`, null, { headers, tags: { endpoint: 'dashboard', name: 'GET /users/me' } }],
      ['GET', `${BASE_URL}/api/v1/games/me`, null, { headers, tags: { endpoint: 'dashboard', name: 'GET /games/me' } }],
      [
        'GET',
        `${BASE_URL}/api/v1/notifications?page=1&limit=20`,
        null,
        { headers, tags: { endpoint: 'dashboard', name: 'GET /notifications' } },
      ],
      [
        'GET',
        `${BASE_URL}/api/v1/performance/stats`,
        null,
        { headers, tags: { endpoint: 'dashboard', name: 'GET /performance/stats' } },
      ],
    ]);

    responses.forEach((res, idx) => {
      const body = parseJson(res);
      check(
        res,
        {
          [`dashboard[${idx}] status 200`]: (r) => r.status === 200,
          [`dashboard[${idx}] success true`]: () => body && body.success === true,
        },
        { endpoint: 'dashboard' },
      );
    });
  });

  sleep(randomBetween(1, 3));

  group('3_browse_games', () => {
    const res = http.get(`${BASE_URL}/api/v1/games?status=open&limit=20`, {
      headers,
      tags: { endpoint: 'browse', name: 'GET /games' },
    });
    const body = parseJson(res);
    const games = body && (Array.isArray(body.games) ? body.games : body.data && body.data.games);
    check(
      res,
      {
        'browse status 200': (r) => r.status === 200,
        'browse success true': () => body && body.success === true,
        'browse has games array': () => Array.isArray(games),
      },
      { endpoint: 'browse' },
    );
  });

  sleep(randomBetween(2, 5));

  group('4_create_game', () => {
    const payload = buildCreateGameBody(vu, iter);
    const res = http.post(`${BASE_URL}/api/v1/games`, JSON.stringify(payload), {
      headers,
      tags: { endpoint: 'create', name: 'POST /games' },
    });
    const body = parseJson(res);
    const game = body && body.data && body.data.game;
    check(
      res,
      {
        'create status 201': (r) => r.status === 201,
        'create success true': () => body && body.success === true,
        'create returns game id': () => game && (game._id || game.id),
      },
      { endpoint: 'create' },
    );
  });

  sleep(randomBetween(1, 2));
}
