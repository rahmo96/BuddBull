/**
 * Phase 4 — Private games + handleJoinRequest.
 *
 * Pins three behaviours:
 *
 *   1. Creating a game with `isPrivate: true` is accepted by the
 *      validator and round-trips through the API.
 *   2. Joining an `isPrivate` game lands the requester in `pending` —
 *      identical to the existing `requiresApproval` path — and fires a
 *      `gameJoinRequest` notification to the organiser.
 *   3. The new `PATCH /:id/join-request/:userId` endpoint approves or
 *      rejects a pending slot and emits the matching downstream
 *      notification (`gameApproved` / `gameJoinRequestDenied`).
 */

const request = require('supertest');
const testDb = require('./helpers/testDb');
const createApp = require('../src/app');
const Notification = require('../src/models/Notification.model');
const { syncFirebaseUser } = require('./helpers/authTestFactory');

const app = createApp();

beforeAll(testDb.connect);
afterEach(testDb.clearAll);
afterAll(testDb.disconnect);

const GAMES = '/api/v1/games';

const mkGame = (overrides = {}) => ({
  title: 'Sunday Football',
  sport: 'football',
  scheduledAt: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
  durationMinutes: 90,
  location: {
    neighborhood: 'Notting Hill',
    city: 'London',
    country: 'GB',
    formattedAddress: 'Notting Hill, London W11, UK',
    placeId: 'test-place-id',
    coordinates: { type: 'Point', coordinates: [-0.1955, 51.5099] },
  },
  maxPlayers: 10,
  requiredSkillLevel: 'any',
  ...overrides,
});

const registerAndLogin = async (slot, role = 'player') => {
  const r = await syncFirebaseUser(app, {
    role,
    firstName: `User${slot}`,
    lastName: 'Test',
  });
  expect(r.status).toBe(200);
  return { token: r.token, userId: r.userId };
};

const inboxOf = async (userId) =>
  Notification.find({ recipient: userId }).sort({ createdAt: -1 }).lean();

describe('Private games — join flow', () => {
  it('persists `isPrivate: true` through the create endpoint', async () => {
    const org = await registerAndLogin(1, 'organizer');
    const res = await request(app)
      .post(GAMES)
      .set('Authorization', `Bearer ${org.token}`)
      .send(mkGame({ isPrivate: true }));

    expect(res.status).toBe(201);
    expect(res.body.data.game.isPrivate).toBe(true);
  });

  it('puts joiners of a private game in `pending` status (no auto-approve)',
    async () => {
      const org = await registerAndLogin(1, 'organizer');
      const requester = await registerAndLogin(2);

      const game = await request(app)
        .post(GAMES)
        .set('Authorization', `Bearer ${org.token}`)
        .send(mkGame({ isPrivate: true }));
      const gameId = game.body.data.game._id;

      const join = await request(app)
        .post(`${GAMES}/${gameId}/join`)
        .set('Authorization', `Bearer ${requester.token}`);

      expect(join.status).toBe(200);
      // Backend signals approval-needed via the `status` field.
      expect(join.body.data.status).toBe('pending');

      // And the organiser receives a `gameJoinRequest` notification.
      const inbox = await inboxOf(org.userId);
      expect(inbox.find((n) => n.type === 'gameJoinRequest')).toBeDefined();
    });
});

describe('PATCH /games/:id/join-request/:userId', () => {
  // Set up a private game with a single pending requester. Returns
  // every id the assertions downstream need.
  const seedPrivateGameWithPending = async () => {
    const org = await registerAndLogin(1, 'organizer');
    const requester = await registerAndLogin(2);

    const game = await request(app)
      .post(GAMES)
      .set('Authorization', `Bearer ${org.token}`)
      .send(mkGame({ isPrivate: true }));
    const gameId = game.body.data.game._id;

    await request(app)
      .post(`${GAMES}/${gameId}/join`)
      .set('Authorization', `Bearer ${requester.token}`);

    // Clear the join-request notification so later inbox assertions
    // only see the downstream approve/reject row.
    await Notification.deleteMany({ recipient: org.userId });

    return { org, requester, gameId };
  };

  it('approves a pending player and fires `gameApproved` to them',
    async () => {
      const { org, requester, gameId } = await seedPrivateGameWithPending();

      const res = await request(app)
        .patch(`${GAMES}/${gameId}/join-request/${requester.userId}`)
        .set('Authorization', `Bearer ${org.token}`)
        .send({ decision: 'approve' });

      expect(res.status).toBe(200);

      const slot = res.body.data.game.players
        .find((p) => p.user.toString() === requester.userId);
      expect(slot.status).toBe('approved');

      const approved = (await inboxOf(requester.userId))
        .find((n) => n.type === 'gameApproved');
      expect(approved).toBeDefined();
      expect(approved.data).toMatchObject({ gameId: String(gameId) });
    });

  it('rejects a pending player and fires `gameJoinRequestDenied` to them',
    async () => {
      const { org, requester, gameId } = await seedPrivateGameWithPending();

      const res = await request(app)
        .patch(`${GAMES}/${gameId}/join-request/${requester.userId}`)
        .set('Authorization', `Bearer ${org.token}`)
        .send({ decision: 'reject', reason: 'wrong skill level' });

      expect(res.status).toBe(200);

      const slot = res.body.data.game.players
        .find((p) => p.user.toString() === requester.userId);
      expect(slot.status).toBe('rejected');

      const denied = (await inboxOf(requester.userId))
        .find((n) => n.type === 'gameJoinRequestDenied');
      expect(denied).toBeDefined();
      expect(denied.title).toBe('Join Request Denied');
      expect(denied.body).toBe('Your request to join the game was declined.');
      expect(denied.data).toMatchObject({ gameId: String(gameId) });
    });

  it('rejects a stale request when the slot is no longer pending',
    async () => {
      const { org, requester, gameId } = await seedPrivateGameWithPending();

      // First decision: approve.
      await request(app)
        .patch(`${GAMES}/${gameId}/join-request/${requester.userId}`)
        .set('Authorization', `Bearer ${org.token}`)
        .send({ decision: 'approve' });

      // Second decision arrives stale (the organiser tapped Approve
      // twice from the bell). Service must refuse — not silently
      // double-approve or downgrade the slot.
      const res = await request(app)
        .patch(`${GAMES}/${gameId}/join-request/${requester.userId}`)
        .set('Authorization', `Bearer ${org.token}`)
        .send({ decision: 'reject' });

      expect(res.status).toBe(409);
    });

  it('returns 422 for an invalid decision value', async () => {
    const { org, requester, gameId } = await seedPrivateGameWithPending();

    const res = await request(app)
      .patch(`${GAMES}/${gameId}/join-request/${requester.userId}`)
      .set('Authorization', `Bearer ${org.token}`)
      .send({ decision: 'maybe' });

    expect(res.status).toBe(422);
  });
});
