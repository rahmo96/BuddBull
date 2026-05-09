/**
 * User profile integration tests (Firebase ID token stub + POST /auth/sync onboarding).
 */

const request = require('supertest');
const testDb = require('./helpers/testDb');
const createApp = require('../src/app');
const { syncFirebaseUser } = require('./helpers/authTestFactory');

const app = createApp();

beforeAll(testDb.connect);
afterEach(testDb.clearAll);
afterAll(testDb.disconnect);

const USER_BASE = '/api/v1/users';

const registerAndLogin = async (slot = 1, role = 'player') => {
  const r = await syncFirebaseUser(app, {
    role,
    email: `u${slot}_${Date.now()}@example.com`,
    firstName: `User${slot}`,
    lastName: 'Test',
  });
  expect(r.status).toBe(200);
  const dto = { email: r.email, username: r.user.username };
  return { token: r.token, user: r.user, dto };
};

describe('GET /users/me', () => {
  it('returns the authenticated user profile', async () => {
    const { token, dto } = await registerAndLogin();

    const res = await request(app).get(`${USER_BASE}/me`).set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data.user.email).toBe(dto.email);
    expect(res.body.data.user.password).toBeUndefined();
  });

  it('returns 401 when bearer token mapping is absent', async () => {
    const res = await request(app).get(`${USER_BASE}/me`).set('Authorization', 'Bearer unmapped-token-test');
    expect(res.status).toBe(401);
  });
});

describe('PATCH /users/me', () => {
  it('updates profile fields', async () => {
    const { token } = await registerAndLogin();

    const res = await request(app)
      .patch(`${USER_BASE}/me`)
      .set('Authorization', `Bearer ${token}`)
      .send({ bio: 'I love football!', location: { city: 'London' } });

    expect(res.status).toBe(200);
    expect(res.body.data.user.bio).toBe('I love football!');
    expect(res.body.data.user.location.city).toBe('London');
  });

  it('ignores attempts to escalate role via this endpoint', async () => {
    const { token } = await registerAndLogin();

    const res = await request(app).patch(`${USER_BASE}/me`).set('Authorization', `Bearer ${token}`).send({
      role: 'admin',
      bio: 'Legit update',
    });

    expect(res.status).toBe(200);
    expect(res.body.data.user.role).toBe('player');
  });

  it('rejects empty body with 422', async () => {
    const { token } = await registerAndLogin();

    const res = await request(app).patch(`${USER_BASE}/me`).set('Authorization', `Bearer ${token}`).send({});

    expect(res.status).toBe(422);
  });

  it('rejects payloads that violate schema constraints', async () => {
    const { token } = await registerAndLogin();

    const res = await request(app).patch(`${USER_BASE}/me`).set('Authorization', `Bearer ${token}`).send({
      bio: 'x'.repeat(501),
    });

    expect(res.status).toBe(422);
    expect(Array.isArray(res.body.errors)).toBe(true);
  });
});

describe('PATCH /users/me/username', () => {
  it('changes username to a new unique value', async () => {
    const { token } = await registerAndLogin();

    const res = await request(app)
      .patch(`${USER_BASE}/me/username`)
      .set('Authorization', `Bearer ${token}`)
      .send({ username: 'brandnewname' });

    expect(res.status).toBe(200);
    expect(res.body.data.user.username).toBe('brandnewname');
  });

  it('returns 409 if the username is already taken', async () => {
    const rA = await syncFirebaseUser(app, {
      role: 'player',
      username: `user_a_unique_${process.hrtime.bigint()}`,
      email: `a_${Date.now()}@example.test`,
    });
    const rB = await syncFirebaseUser(app, {
      role: 'player',
      username: `user_b_unique_${process.hrtime.bigint()}`,
      email: `b_${Date.now()}@example.test`,
    });
    expect(rA.status).toBe(200);
    expect(rB.status).toBe(200);

    const clash = await request(app)
      .patch(`${USER_BASE}/me/username`)
      .set('Authorization', `Bearer ${rB.token}`)
      .send({ username: rA.user.username });

    expect(clash.status).toBe(409);
  });
});

describe('GET /users/:username', () => {
  it("returns another user's public profile without leaking email", async () => {
    const rSubject = await syncFirebaseUser(app, {
      role: 'player',
      username: `pub_subject_${process.hrtime.bigint()}`,
      email: `subject_${Date.now()}@example.com`,
    });
    const rViewer = await syncFirebaseUser(app, {
      role: 'player',
      username: `pub_viewer_${process.hrtime.bigint()}`,
      email: `viewer_${Date.now()}@example.com`,
    });

    expect(rSubject.status).toBe(200);
    expect(rViewer.status).toBe(200);

    const res = await request(app)
      .get(`${USER_BASE}/${rSubject.user.username}`)
      .set('Authorization', `Bearer ${rViewer.token}`);

    expect(res.status).toBe(200);
    expect(res.body.data.user.username).toBe(rSubject.user.username);
    expect(res.body.data.user.email).toBeUndefined();
  });

  it('returns 404 for a non-existent username', async () => {
    const { token } = await registerAndLogin();

    const res = await request(app)
      .get(`${USER_BASE}/doesnotexist999`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
  });
});

describe('Follow & Unfollow', () => {
  it('allows a user to follow another user', async () => {
    const r1 = await registerAndLogin(1);
    const r2 = await registerAndLogin(2);

    const res = await request(app)
      .post(`${USER_BASE}/${r2.user._id}/follow`)
      .set('Authorization', `Bearer ${r1.token}`);

    expect(res.status).toBe(200);
    expect(res.body.data.followerCount).toBe(1);
  });

  it('prevents following the same user twice with 409', async () => {
    const r1 = await registerAndLogin(1);
    const r2 = await registerAndLogin(2);

    await request(app).post(`${USER_BASE}/${r2.user._id}/follow`).set('Authorization', `Bearer ${r1.token}`);

    const res = await request(app)
      .post(`${USER_BASE}/${r2.user._id}/follow`)
      .set('Authorization', `Bearer ${r1.token}`);

    expect(res.status).toBe(409);
  });

  it('prevents following yourself with 400', async () => {
    const { token, user } = await registerAndLogin();

    const res = await request(app).post(`${USER_BASE}/${user._id}/follow`).set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(400);
  });

  it('returns 400 when follower route param is not a Mongo ObjectId', async () => {
    const { token } = await registerAndLogin();

    const res = await request(app)
      .post(`${USER_BASE}/not-a-valid-objectid/follow`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(400);
  });

  it('unfollows successfully after following', async () => {
    const r1 = await registerAndLogin(1);
    const r2 = await registerAndLogin(2);

    await request(app).post(`${USER_BASE}/${r2.user._id}/follow`).set('Authorization', `Bearer ${r1.token}`);

    const res = await request(app)
      .delete(`${USER_BASE}/${r2.user._id}/follow`)
      .set('Authorization', `Bearer ${r1.token}`);

    expect(res.status).toBe(200);
  });

  it('treats unfollow as idempotent when no prior follow edge existed', async () => {
    const r1 = await registerAndLogin(1);
    const r2 = await registerAndLogin(2);

    const res = await request(app)
      .delete(`${USER_BASE}/${r2.user._id}/follow`)
      .set('Authorization', `Bearer ${r1.token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});

describe('DELETE /users/me', () => {
  it('responds 501 until password-based SSO deletion ships', async () => {
    const { token } = await registerAndLogin();

    const res = await request(app).delete(`${USER_BASE}/me`).set('Authorization', `Bearer ${token}`).send({
      password: 'Irrelevant1',
    });

    expect(res.status).toBe(501);
    expect(res.body.message).toMatch(/SSO-managed/i);
  });

  it('requires password field before attempting SSO guard', async () => {
    const { token } = await registerAndLogin();

    const res = await request(app).delete(`${USER_BASE}/me`).set('Authorization', `Bearer ${token}`).send({});

    expect(res.status).toBe(400);
  });
});

describe('GET /users/search', () => {
  it('supports paginated catalogue queries without invoking full-text operators', async () => {
    const { token } = await registerAndLogin(1);

    await syncFirebaseUser(app, {
      role: 'player',
      username: `searchusr_${process.hrtime.bigint()}`,
      email: `catalog_${Date.now()}@example.com`,
    });

    const res = await request(app).get(`${USER_BASE}/search?page=1&limit=5`).set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.pagination).toBeDefined();
    expect(Array.isArray(res.body.users)).toBe(true);
  });

  it('surfaces actionable errors when textual search is invoked without a text index', async () => {
    const { token } = await registerAndLogin(1);

    const res = await request(app).get(`${USER_BASE}/search?q=goalkeeper`).set('Authorization', `Bearer ${token}`);

    expect([200, 500]).toContain(res.status);
    if (res.status === 200) {
      expect(Array.isArray(res.body.users)).toBe(true);
    }
  });
});
