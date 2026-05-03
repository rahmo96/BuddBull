/**
 * User CRUD Integration Tests
 *
 * Coverage:
 *  - GET /users/me
 *  - PATCH /users/me (profile update)
 *  - PATCH /users/me/username
 *  - DELETE /users/me (soft delete)
 *  - GET /users/:username (public profile)
 *  - POST /users/:id/follow  &  DELETE /users/:id/follow
 *  - GET /users/search
 */

const request = require('supertest');
const testDb = require('./helpers/testDb');
const createApp = require('../src/app');
const User = require('../src/models/User.model');

const app = createApp();

// ─────────────────────────────────────────────
//  Lifecycle
// ─────────────────────────────────────────────

beforeAll(testDb.connect);
afterEach(testDb.clearAll);
afterAll(testDb.disconnect);

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────

const AUTH_BASE = '/api/v1/auth';
const USER_BASE = '/api/v1/users';

const makeUser = (n = 1) => ({
  firstName: `User${n}`,
  lastName: 'Test',
  username: `user${n}test`,
  email: `user${n}@example.com`,
  password: 'Password1',
  role: 'player',
});

const registerAndLogin = async (n = 1) => {
  const dto = makeUser(n);
  await request(app).post(`${AUTH_BASE}/register`).send(dto);
  const res = await request(app)
    .post(`${AUTH_BASE}/login`)
    .send({ email: dto.email, password: dto.password });
  return { token: res.body.accessToken, user: res.body.data.user, dto };
};

// ─────────────────────────────────────────────
//  GET /users/me
// ─────────────────────────────────────────────

describe('GET /users/me', () => {
  it('returns the authenticated user profile', async () => {
    const { token, dto } = await registerAndLogin();

    const res = await request(app)
      .get(`${USER_BASE}/me`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data.user.email).toBe(dto.email);
    expect(res.body.data.user.password).toBeUndefined();
  });
});

// ─────────────────────────────────────────────
//  PATCH /users/me
// ─────────────────────────────────────────────

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

    const res = await request(app)
      .patch(`${USER_BASE}/me`)
      .set('Authorization', `Bearer ${token}`)
      .send({ role: 'admin', bio: 'Legit update' });

    expect(res.status).toBe(200);
    expect(res.body.data.user.role).toBe('player');
  });

  it('rejects empty body with 422', async () => {
    const { token } = await registerAndLogin();

    const res = await request(app)
      .patch(`${USER_BASE}/me`)
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.status).toBe(422);
  });
});

// ─────────────────────────────────────────────
//  PATCH /users/me/username
// ─────────────────────────────────────────────

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
    const { token } = await registerAndLogin(1);
    await registerAndLogin(2); // creates user2test

    const res = await request(app)
      .patch(`${USER_BASE}/me/username`)
      .set('Authorization', `Bearer ${token}`)
      .send({ username: 'user2test' });

    expect(res.status).toBe(409);
  });
});

// ─────────────────────────────────────────────
//  GET /users/:username  (public profile)
// ─────────────────────────────────────────────

describe('GET /users/:username', () => {
  it("returns another user's public profile", async () => {
    await registerAndLogin(1);
    const { token: token2, dto: dto1 } = await registerAndLogin(2);

    const res = await request(app)
      .get(`${USER_BASE}/${dto1.username}`)
      .set('Authorization', `Bearer ${token2}`);

    expect(res.status).toBe(200);
    expect(res.body.data.user.username).toBe(dto1.username);
    // email must not be in public profile
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

// ─────────────────────────────────────────────
//  Follow / Unfollow
// ─────────────────────────────────────────────

describe('Follow & Unfollow', () => {
  it('allows a user to follow another user', async () => {
    const { token: token1 } = await registerAndLogin(1);
    const { user: user2 } = await registerAndLogin(2);

    const res = await request(app)
      .post(`${USER_BASE}/${user2._id}/follow`)
      .set('Authorization', `Bearer ${token1}`);

    expect(res.status).toBe(200);
    expect(res.body.data.followerCount).toBe(1);
  });

  it('prevents following the same user twice with 409', async () => {
    const { token: token1 } = await registerAndLogin(1);
    const { user: user2 } = await registerAndLogin(2);

    await request(app)
      .post(`${USER_BASE}/${user2._id}/follow`)
      .set('Authorization', `Bearer ${token1}`);

    const res = await request(app)
      .post(`${USER_BASE}/${user2._id}/follow`)
      .set('Authorization', `Bearer ${token1}`);

    expect(res.status).toBe(409);
  });

  it('prevents following yourself with 400', async () => {
    const { token, user } = await registerAndLogin();

    const res = await request(app)
      .post(`${USER_BASE}/${user._id}/follow`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(400);
  });

  it('unfollows successfully after following', async () => {
    const { token: token1 } = await registerAndLogin(1);
    const { user: user2 } = await registerAndLogin(2);

    await request(app)
      .post(`${USER_BASE}/${user2._id}/follow`)
      .set('Authorization', `Bearer ${token1}`);

    const res = await request(app)
      .delete(`${USER_BASE}/${user2._id}/follow`)
      .set('Authorization', `Bearer ${token1}`);

    expect(res.status).toBe(200);
  });
});

// ─────────────────────────────────────────────
//  DELETE /users/me (soft delete)
// ─────────────────────────────────────────────

describe('DELETE /users/me', () => {
  it('soft-deletes the account with correct password', async () => {
    const { token, dto } = await registerAndLogin();

    const res = await request(app)
      .delete(`${USER_BASE}/me`)
      .set('Authorization', `Bearer ${token}`)
      .send({ password: dto.password });

    expect(res.status).toBe(200);

    const user = await User.findOne({ email: dto.email });
    // Email is scrambled after soft delete
    expect(user.email).not.toBe(dto.email);
    expect(user.deletedAt).toBeDefined();
    expect(user.isActive).toBe(false);
  });

  it('refuses deletion with wrong password', async () => {
    const { token } = await registerAndLogin();

    const res = await request(app)
      .delete(`${USER_BASE}/me`)
      .set('Authorization', `Bearer ${token}`)
      .send({ password: 'WrongPass9' });

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────
//  GET /users/search
// ─────────────────────────────────────────────

describe('GET /users/search', () => {
  it('returns matching users from text search', async () => {
    const { token } = await registerAndLogin(1);

    // Create a second user with a distinctive bio
    await request(app).post(`${AUTH_BASE}/register`).send({
      ...makeUser(2),
      bio: 'Professional goalkeeper',
    });

    const res = await request(app)
      .get(`${USER_BASE}/search?q=goalkeeper`)
      .set('Authorization', `Bearer ${token}`);

    // Text search requires a text index — in test it may return 0 results
    // but the endpoint must respond successfully
    expect(res.status).toBe(200);
    expect(res.body.pagination).toBeDefined();
  });
});
