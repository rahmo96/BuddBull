/**
 * Firebase-first auth integration smoke tests.
 *
 * Legacy email/password JWT routes are not mounted in src/app — coverage targets /auth/sync and token verification.
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

const BASE = '/api/v1/auth';

describe('POST /auth/sync', () => {
  it('creates a Mongo profile for a freshly verified Firebase UID', async () => {
    const raw = await syncFirebaseUser(app, {
      username: `sync_${process.hrtime.bigint()}`,
      role: 'player',
      email: `sync_${Date.now()}@auth.test`,
    });

    expect(raw.status).toBe(200);
    expect(raw.body.success).toBe(true);
    expect(raw.user.firebaseUid).toBe(raw.firebaseUid);
    expect(raw.user.username).toBeDefined();
    const persisted = await User.findOne({ firebaseUid: raw.firebaseUid });
    expect(persisted).not.toBeNull();
  });

  it('updates profile fields idempotently for an existing firebaseUid', async () => {
    const first = await syncFirebaseUser(app, {
      bearerToken: 'stable-registration-token-alpha',
      firebaseUid: 'fb-stable-alpha',
      email: `stable_${Date.now()}@auth.test`,
      username: `stable_${process.hrtime.bigint()}`,
      role: 'player',
      lastName: 'Original',
    });
    expect(first.status).toBe(200);

    const second = await request(app)
      .post(`${BASE}/sync`)
      .set('Authorization', 'Bearer stable-registration-token-alpha')
      .send({
        firstName: 'Updated',
        lastName: 'Synced',
        username: first.user.username,
        role: 'organizer',
      });

    expect(second.status).toBe(200);
    const doc = await User.findOne({ firebaseUid: 'fb-stable-alpha' });
    expect(doc.lastName).toBe('Synced');
    expect(doc.role).toBe('organizer');
  });

  it('rejects organisers without valid Firebase tokens when hitting protected endpoints', async () => {
    const res = await request(app).post(`${BASE}/sync`).send({
      firstName: 'Hack',
      lastName: 'Attempt',
      username: 'bogus',
      role: 'organizer',
    });

    expect(res.status).toBe(401);
  });

  it('returns validation errors when synced profile violates User model constraints', async () => {
    const r = await syncFirebaseUser(app, {
      bearerToken: 'tiny-username-sync',
      email: `tiny_${Date.now()}@auth.test`,
      username: 'ab',
    });
    expect(r.status).toBeGreaterThanOrEqual(400);
  });
});

describe('GET /users/me protection', () => {
  it('returns 401 without authorization header', async () => {
    const res = await request(app).get('/api/v1/users/me');
    expect(res.status).toBe(401);
  });

  it('returns 401 when Firebase verifier rejects synthetic token strings', async () => {
    const res = await request(app).get('/api/v1/users/me').set('Authorization', 'Bearer not-registered-mapping');

    expect(res.status).toBe(401);
  });

  it('returns Mongo-bound user payload after onboarding through /auth/sync', async () => {
    const seeded = await syncFirebaseUser(app, {
      username: `gate_${process.hrtime.bigint()}`,
      email: `gate_${Date.now()}@auth.test`,
    });
    expect(seeded.status).toBe(200);

    const res = await request(app).get('/api/v1/users/me').set('Authorization', `Bearer ${seeded.token}`);

    expect(res.status).toBe(200);
    expect(`${res.body.data.user._id}`).toBe(`${seeded.userId}`);
    expect(res.body.data.user.firebaseUid).toBe(seeded.firebaseUid);
  });
});

describe('RBAC baseline', () => {
  it('returns 403 for non-admin callers hitting admin catalogue routes', async () => {
    const player = await syncFirebaseUser(app, {
      username: `nonadmin_${process.hrtime.bigint()}`,
      role: 'player',
    });
    expect(player.status).toBe(200);

    const res = await request(app).get('/api/v1/users/admin/list').set('Authorization', `Bearer ${player.token}`);

    expect(res.status).toBe(403);
  });

  it('allows configured admin accounts through restrictTo(admin)', async () => {
    const admin = await syncFirebaseUser(app, {
      username: `admin_${process.hrtime.bigint()}`,
      role: 'admin',
    });
    expect(admin.status).toBe(200);

    const res = await request(app).get('/api/v1/users/admin/list').set('Authorization', `Bearer ${admin.token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});
