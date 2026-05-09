/**
 * Additional edge-case smoke tests surfaced during backend audit gap analysis.
 */

const request = require('supertest');
const testDb = require('./helpers/testDb');
const createApp = require('../src/app');
const User = require('../src/models/User.model');
const { syncFirebaseUser } = require('./helpers/authTestFactory');

const app = createApp();

beforeAll(testDb.connect);
afterEach(testDb.clearAll);
afterAll(testDb.disconnect);

const GAMES = '/api/v1/games';

describe('Public catalogue access (optionalAuth)', () => {
  it('returns 200 when GET /games is called without bearer credentials', async () => {
    const res = await request(app).get(`${GAMES}?status=open&limit=5`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.games)).toBe(true);
  });

  it('returns 401 for GET /games/me without authentication', async () => {
    const res = await request(app).get(`${GAMES}/me`);
    expect(res.status).toBe(401);
  });
});

describe('Account health enforced after Firebase verification', () => {
  it('returns 401 for banned accounts even when their Firebase UID still verifies', async () => {
    const onboarded = await syncFirebaseUser(app, {
      role: 'player',
      username: `ban_edge_${process.hrtime.bigint()}`,
      email: `ban_${Date.now()}@audit.test`,
    });
    expect(onboarded.status).toBe(200);

    await User.updateOne(
      { _id: onboarded.userId },
      { $set: { isBanned: true, banReason: 'automated qa ban' } },
    );

    const res = await request(app).get('/api/v1/users/me').set('Authorization', `Bearer ${onboarded.token}`);

    expect(res.status).toBe(401);
    expect(res.body.message || '').toMatch(/account|authenticate|logged/i);
  });
});
