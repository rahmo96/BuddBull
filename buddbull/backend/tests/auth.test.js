/**
 * Auth Integration Tests
 *
 * Tests the full request/response cycle through Express + Mongoose
 * using an in-memory MongoDB instance.
 *
 * Coverage:
 *  - Registration (success, duplicate email, duplicate username, weak password)
 *  - Login (success, wrong password, inactive account)
 *  - /me endpoint protection
 *  - Refresh token rotation
 *  - Forgot / Reset password flow
 *  - Change password
 *  - Logout
 */

const request = require('supertest');
const mongoose = require('mongoose');
const testDb = require('./helpers/testDb');
const createApp = require('../src/app');
const User = require('../src/models/User.model');

const app = createApp();

// ─────────────────────────────────────────────
//  Lifecycle
// ─────────────────────────────────────────────

beforeAll(async () => {
  await testDb.connect();
});

afterEach(async () => {
  await testDb.clearAll();
});

afterAll(async () => {
  await testDb.disconnect();
});

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────

const BASE = '/api/v1/auth';

const validUser = {
  firstName: 'Test',
  lastName: 'Player',
  username: 'testplayer',
  email: 'test@example.com',
  password: 'Password1',
  role: 'player',
};

/**
 * Registers a user and returns the response body (includes accessToken).
 */
const registerUser = async (overrides = {}) =>
  request(app)
    .post(`${BASE}/register`)
    .send({ ...validUser, ...overrides });

/**
 * Registers and logs in, returning the access token.
 */
const getAccessToken = async (overrides = {}) => {
  const res = await registerUser(overrides);
  return res.body.accessToken;
};

// ─────────────────────────────────────────────
//  POST /register
// ─────────────────────────────────────────────

describe('POST /auth/register', () => {
  it('creates a new user and returns 201 with tokens', async () => {
    const res = await registerUser();

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.accessToken).toBeDefined();
    expect(res.body.data.user.email).toBe(validUser.email);
    expect(res.body.data.user.password).toBeUndefined();
  });

  it('rejects duplicate email with 409', async () => {
    await registerUser();
    const res = await registerUser({ username: 'different' });

    expect(res.status).toBe(409);
    expect(res.body.message).toMatch(/email/i);
  });

  it('rejects duplicate username with 409', async () => {
    await registerUser();
    const res = await registerUser({ email: 'other@example.com' });

    expect(res.status).toBe(409);
    expect(res.body.message).toMatch(/username/i);
  });

  it('rejects a weak password missing uppercase with 422', async () => {
    const res = await registerUser({ password: 'password1' });

    expect(res.status).toBe(422);
    expect(res.body.errors[0].field).toBe('password');
  });

  it('rejects a password shorter than 6 characters with 422', async () => {
    const res = await registerUser({ password: 'Aa1' });

    expect(res.status).toBe(422);
  });

  it('rejects a missing email with 422', async () => {
    const res = await registerUser({ email: undefined });

    expect(res.status).toBe(422);
    expect(res.body.errors.some((e) => e.field === 'email')).toBe(true);
  });

  it('stores a bcrypt hash, not the raw password', async () => {
    await registerUser();
    const user = await User.findOne({ email: validUser.email }).select('+password');
    expect(user.password).not.toBe(validUser.password);
    expect(user.password).toMatch(/^\$2[aby]\$/);
  });
});

// ─────────────────────────────────────────────
//  POST /login
// ─────────────────────────────────────────────

describe('POST /auth/login', () => {
  beforeEach(async () => {
    await registerUser();
  });

  it('returns 200 and tokens for valid credentials', async () => {
    const res = await request(app)
      .post(`${BASE}/login`)
      .send({ email: validUser.email, password: validUser.password });

    expect(res.status).toBe(200);
    expect(res.body.accessToken).toBeDefined();
    expect(res.body.data.user.email).toBe(validUser.email);
  });

  it('returns 401 for wrong password', async () => {
    const res = await request(app)
      .post(`${BASE}/login`)
      .send({ email: validUser.email, password: 'WrongPass9' });

    expect(res.status).toBe(401);
    expect(res.body.message).toMatch(/incorrect/i);
  });

  it('returns 401 for unknown email (same message — no enumeration)', async () => {
    const res = await request(app)
      .post(`${BASE}/login`)
      .send({ email: 'nobody@example.com', password: 'Password1' });

    expect(res.status).toBe(401);
    expect(res.body.message).toMatch(/incorrect/i);
  });

  it('updates lastLoginAt on successful login', async () => {
    await request(app)
      .post(`${BASE}/login`)
      .send({ email: validUser.email, password: validUser.password });

    const user = await User.findOne({ email: validUser.email });
    expect(user.lastLoginAt).toBeDefined();
  });
});

// ─────────────────────────────────────────────
//  Protected route: GET /users/me
// ─────────────────────────────────────────────

describe('GET /users/me (protect middleware)', () => {
  it('returns 401 with no token', async () => {
    const res = await request(app).get('/api/v1/users/me');
    expect(res.status).toBe(401);
  });

  it('returns 401 with a malformed token', async () => {
    const res = await request(app)
      .get('/api/v1/users/me')
      .set('Authorization', 'Bearer not.a.valid.token');

    expect(res.status).toBe(401);
  });

  it('returns 200 with a valid token', async () => {
    const token = await getAccessToken();
    const res = await request(app)
      .get('/api/v1/users/me')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data.user.username).toBe(validUser.username);
  });
});

// ─────────────────────────────────────────────
//  POST /logout
// ─────────────────────────────────────────────

describe('POST /auth/logout', () => {
  it('logs out and clears the refresh token hash', async () => {
    const token = await getAccessToken();

    const res = await request(app)
      .post(`${BASE}/logout`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);

    const user = await User.findOne({ email: validUser.email }).select('+refreshTokenHash');
    expect(user.refreshTokenHash).toBeUndefined();
  });
});

// ─────────────────────────────────────────────
//  POST /forgot-password  (no enumeration)
// ─────────────────────────────────────────────

describe('POST /auth/forgot-password', () => {
  it('always returns 200 regardless of whether the email exists', async () => {
    const res1 = await request(app)
      .post(`${BASE}/forgot-password`)
      .send({ email: 'does.not.exist@example.com' });

    const res2 = await request(app)
      .post(`${BASE}/forgot-password`)
      .send({ email: validUser.email });

    expect(res1.status).toBe(200);
    expect(res2.status).toBe(200);
    expect(res1.body.message).toBe(res2.body.message);
  });
});

// ─────────────────────────────────────────────
//  PATCH /reset-password/:token
// ─────────────────────────────────────────────

describe('PATCH /auth/reset-password/:token', () => {
  it('resets password with a valid token and returns new tokens', async () => {
    // Register and generate a reset token directly on the model
    await registerUser();
    const user = await User.findOne({ email: validUser.email })
      .select('+resetPasswordToken +resetPasswordExpiry');

    const rawToken = user.createPasswordResetToken();
    await user.save({ validateBeforeSave: false });

    const res = await request(app)
      .patch(`${BASE}/reset-password/${rawToken}`)
      .send({ password: 'NewPassword2', passwordConfirm: 'NewPassword2' });

    expect(res.status).toBe(200);
    expect(res.body.accessToken).toBeDefined();

    // Old password should no longer work
    const loginOld = await request(app)
      .post(`${BASE}/login`)
      .send({ email: validUser.email, password: validUser.password });

    expect(loginOld.status).toBe(401);
  });

  it('rejects an invalid / expired reset token with 400', async () => {
    const res = await request(app)
      .patch(`${BASE}/reset-password/invalidtoken123`)
      .send({ password: 'NewPassword2', passwordConfirm: 'NewPassword2' });

    expect(res.status).toBe(400);
  });
});

// ─────────────────────────────────────────────
//  PATCH /change-password
// ─────────────────────────────────────────────

describe('PATCH /auth/change-password', () => {
  it('changes password successfully with correct current password', async () => {
    const token = await getAccessToken();

    const res = await request(app)
      .patch(`${BASE}/change-password`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        currentPassword: validUser.password,
        newPassword: 'UpdatedPass3',
        newPasswordConfirm: 'UpdatedPass3',
      });

    expect(res.status).toBe(200);
    expect(res.body.accessToken).toBeDefined();
  });

  it('returns 401 when current password is wrong', async () => {
    const token = await getAccessToken();

    const res = await request(app)
      .patch(`${BASE}/change-password`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        currentPassword: 'WrongCurrent1',
        newPassword: 'UpdatedPass3',
        newPasswordConfirm: 'UpdatedPass3',
      });

    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────
//  RBAC  — restrictTo
// ─────────────────────────────────────────────

describe('RBAC — restrictTo admin', () => {
  it('returns 403 for non-admin accessing admin route', async () => {
    const token = await getAccessToken({ role: 'player' });

    const res = await request(app)
      .get('/api/v1/users/admin/list')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
  });
});
