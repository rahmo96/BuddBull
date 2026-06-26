/**
 * Admin user list integration tests.
 */
const request = require('supertest');
const testDb = require('./helpers/testDb');
const createApp = require('../src/app');
const { syncFirebaseUser } = require('./helpers/authTestFactory');

const app = createApp();

beforeAll(testDb.connect);
afterEach(testDb.clearAll);
afterAll(testDb.disconnect);

describe('GET /api/v1/admin/users', () => {
  it('lists all non-deleted users for admins', async () => {
    const admin = await syncFirebaseUser(app, {
      username: `admin_${process.hrtime.bigint()}`,
      role: 'admin',
    });
    await syncFirebaseUser(app, { username: 'alice_findme', firstName: 'Alice', lastName: 'Smith' });
    await syncFirebaseUser(app, { username: 'bob_findme', firstName: 'Bob', lastName: 'Jones' });

    const res = await request(app)
      .get('/api/v1/admin/users')
      .set('Authorization', `Bearer ${admin.token}`)
      .query({ limit: 50 });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.users.length).toBeGreaterThanOrEqual(3);
    expect(res.body.data.total).toBeGreaterThanOrEqual(3);
  });

  it('filters users by search term', async () => {
    const admin = await syncFirebaseUser(app, {
      username: `admin_${process.hrtime.bigint()}`,
      role: 'admin',
    });
    await syncFirebaseUser(app, { username: 'unique_alice_99', firstName: 'Alice', lastName: 'Wonder' });
    await syncFirebaseUser(app, { username: 'unique_bob_99', firstName: 'Bob', lastName: 'Builder' });

    const res = await request(app)
      .get('/api/v1/admin/users')
      .set('Authorization', `Bearer ${admin.token}`)
      .query({ search: 'alice', limit: 50 });

    expect(res.status).toBe(200);
    const usernames = res.body.data.users.map((u) => u.username);
    expect(usernames).toContain('unique_alice_99');
    expect(usernames).not.toContain('unique_bob_99');
  });
});
