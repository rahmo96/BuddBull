/**
 * Notification producers — Phase 2.
 *
 * These tests pin the contract between `game.service.notify(...)` and the
 * `Notification` collection: every game-lifecycle event that used to
 * fire the `[notification:stub]` debug log now persists a row into the
 * recipient's inbox. The tests live at the HTTP boundary (Supertest)
 * because that's the surface real producers run through in prod, and
 * because routing through Express also exercises the validators and
 * auth middleware along the way.
 *
 * The Notification inbox endpoints themselves are covered separately;
 * here we only assert "an event landed in the right person's inbox
 * with the right shape".
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

const registerAndLogin = async (slot, role = 'player', extra = {}) => {
  const r = await syncFirebaseUser(app, {
    role,
    firstName: `User${slot}`,
    lastName: 'Test',
    ...extra,
  });
  expect(r.status).toBe(200);
  return { token: r.token, userId: r.userId };
};

const inboxOf = async (userId) =>
  Notification.find({ recipient: userId }).sort({ createdAt: -1 }).lean();

// ─────────────────────────────────────────────────────────────────────────────
//  game:invite  → gameInvite (target user)
// ─────────────────────────────────────────────────────────────────────────────

describe('game.service.notify — Phase 2 inbox writes', () => {
  it('writes a `gameInvite` row to the invitee when an organiser invites them',
    async () => {
      const org = await registerAndLogin(1, 'organizer');
      const target = await registerAndLogin(2);

      const game = await request(app)
        .post(GAMES)
        .set('Authorization', `Bearer ${org.token}`)
        .send(mkGame({ title: 'Friday 5-a-side' }));
      expect(game.status).toBe(201);
      const gameId = game.body.data.game._id;

      const invite = await request(app)
        .post(`${GAMES}/${gameId}/invite/${target.userId}`)
        .set('Authorization', `Bearer ${org.token}`);
      expect(invite.status).toBeLessThan(400);

      const inbox = await inboxOf(target.userId);
      expect(inbox).toHaveLength(1);
      expect(inbox[0]).toMatchObject({
        type: 'gameInvite',
        title: 'Game Invite',
        read: false,
      });
      expect(inbox[0].body).toMatch(/User1 Test invited you to join their game!/);
      expect(inbox[0].data).toMatchObject({ gameId: String(gameId) });

      // The organiser is NOT also notified about their own invite —
      // recipients are scoped strictly to the target user.
      const orgInbox = await inboxOf(org.userId);
      expect(orgInbox).toHaveLength(0);
    });

  // ───────────────────────────────────────────────────────────────────────────
  //  game:joinRequest  → gameJoinRequest (organiser)
  //  game:playerJoined → gamePlayerJoined (organiser)
  // ───────────────────────────────────────────────────────────────────────────

  it('writes `gameJoinRequest` to the organiser when a private game receives a request',
    async () => {
      const org = await registerAndLogin(1, 'organizer');
      const requester = await registerAndLogin(2);

      const game = await request(app)
        .post(GAMES)
        .set('Authorization', `Bearer ${org.token}`)
        .send(mkGame({ requiresApproval: true }));
      const gameId = game.body.data.game._id;

      const join = await request(app)
        .post(`${GAMES}/${gameId}/join`)
        .set('Authorization', `Bearer ${requester.token}`);
      expect(join.status).toBeLessThan(400);

      const inbox = await inboxOf(org.userId);
      expect(inbox).toHaveLength(1);
      expect(inbox[0]).toMatchObject({
        type: 'gameJoinRequest',
        title: 'New Join Request',
      });
      expect(inbox[0].data).toMatchObject({
        gameId: String(gameId),
        requesterId: String(requester.userId),
      });
    });

  it('writes `gamePlayerJoined` to the organiser when an auto-approved player joins',
    async () => {
      const org = await registerAndLogin(1, 'organizer');
      const joiner = await registerAndLogin(2);

      // requiresApproval defaults to false → auto-approve flow.
      const game = await request(app)
        .post(GAMES)
        .set('Authorization', `Bearer ${org.token}`)
        .send(mkGame());
      const gameId = game.body.data.game._id;

      await request(app)
        .post(`${GAMES}/${gameId}/join`)
        .set('Authorization', `Bearer ${joiner.token}`);

      const inbox = await inboxOf(org.userId);
      expect(inbox).toHaveLength(1);
      expect(inbox[0]).toMatchObject({
        type: 'gamePlayerJoined',
        title: 'New Player Joined',
      });
      expect(inbox[0].data).toMatchObject({
        gameId: String(gameId),
        userId: String(joiner.userId),
      });

      // The joiner does NOT get notified about their own join.
      expect(await inboxOf(joiner.userId)).toHaveLength(0);
    });

  // ───────────────────────────────────────────────────────────────────────────
  //  game:approved → gameApproved (target)
  // ───────────────────────────────────────────────────────────────────────────

  it('writes `gameApproved` to the player when an organiser approves their request',
    async () => {
      const org = await registerAndLogin(1, 'organizer');
      const requester = await registerAndLogin(2);

      const game = await request(app)
        .post(GAMES)
        .set('Authorization', `Bearer ${org.token}`)
        .send(mkGame({ requiresApproval: true }));
      const gameId = game.body.data.game._id;

      await request(app)
        .post(`${GAMES}/${gameId}/join`)
        .set('Authorization', `Bearer ${requester.token}`);

      const approve = await request(app)
        .patch(`${GAMES}/${gameId}/players/${requester.userId}/approve`)
        .set('Authorization', `Bearer ${org.token}`);
      expect(approve.status).toBeLessThan(400);

      const inbox = await inboxOf(requester.userId);
      // 1 = the gameApproved row (the gameJoinRequest row was written
      // to the organiser, not the requester).
      const approved = inbox.find((n) => n.type === 'gameApproved');
      expect(approved).toBeDefined();
      expect(approved).toMatchObject({
        title: 'Join Request Approved',
        body: 'You are in the game!',
      });
      expect(approved.data).toMatchObject({ gameId: String(gameId) });
    });

  // ───────────────────────────────────────────────────────────────────────────
  //  game:kicked → gameKicked (target)
  // ───────────────────────────────────────────────────────────────────────────

  it('writes `gameKicked` to a kicked player and includes the reason in the body',
    async () => {
      const org = await registerAndLogin(1, 'organizer');
      const target = await registerAndLogin(2);

      const game = await request(app)
        .post(GAMES)
        .set('Authorization', `Bearer ${org.token}`)
        .send(mkGame());
      const gameId = game.body.data.game._id;

      await request(app)
        .post(`${GAMES}/${gameId}/join`)
        .set('Authorization', `Bearer ${target.token}`);

      const kick = await request(app)
        .delete(`${GAMES}/${gameId}/players/${target.userId}`)
        .set('Authorization', `Bearer ${org.token}`)
        .send({ reason: 'no-show last time' });
      expect(kick.status).toBeLessThan(400);

      const kicked = (await inboxOf(target.userId)).find((n) => n.type === 'gameKicked');
      expect(kicked).toBeDefined();
      expect(kicked.title).toBe('Removed From Game');
      expect(kicked.body).toBe(
        'You have been removed from the game. Reason: no-show last time',
      );
      expect(kicked.data).toMatchObject({ gameId: String(gameId) });
    });

  // ───────────────────────────────────────────────────────────────────────────
  //  game:cancelled → fan-out to every approved player
  // ───────────────────────────────────────────────────────────────────────────

  it('fans `gameCancelled` out to every approved player (not the organiser)',
    async () => {
      const org = await registerAndLogin(1, 'organizer');
      const p2 = await registerAndLogin(2);
      const p3 = await registerAndLogin(3);

      const game = await request(app)
        .post(GAMES)
        .set('Authorization', `Bearer ${org.token}`)
        .send(mkGame({ title: 'Squad Practice' }));
      const gameId = game.body.data.game._id;

      for (const p of [p2, p3]) {
        // eslint-disable-next-line no-await-in-loop
        await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p.token}`);
      }

      const cancel = await request(app)
        .delete(`${GAMES}/${gameId}`)
        .set('Authorization', `Bearer ${org.token}`)
        .send({ reason: 'pitch waterlogged' });
      expect(cancel.status).toBeLessThan(400);

      for (const p of [p2, p3]) {
        // eslint-disable-next-line no-await-in-loop
        const inbox = await inboxOf(p.userId);
        const cancelled = inbox.find((n) => n.type === 'gameCancelled');
        expect(cancelled).toBeDefined();
        expect(cancelled.title).toBe('Game Cancelled');
        expect(cancelled.body).toMatch(/Squad Practice/);
        expect(cancelled.body).toMatch(/pitch waterlogged/);
        expect(cancelled.data).toMatchObject({ gameId: String(gameId) });
      }
    });

  // ───────────────────────────────────────────────────────────────────────────
  //  game:completed → fan-out to every approved player
  // ───────────────────────────────────────────────────────────────────────────

  it('fans `gameCompleted` out to every approved player so they can rate',
    async () => {
      const org = await registerAndLogin(1, 'organizer');
      const p2 = await registerAndLogin(2);
      const p3 = await registerAndLogin(3);

      const game = await request(app)
        .post(GAMES)
        .set('Authorization', `Bearer ${org.token}`)
        .send(mkGame());
      const gameId = game.body.data.game._id;

      for (const p of [p2, p3]) {
        // eslint-disable-next-line no-await-in-loop
        await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p.token}`);
      }

      const complete = await request(app)
        .patch(`${GAMES}/${gameId}/complete`)
        .set('Authorization', `Bearer ${org.token}`)
        .send({ score: '3-2', winnerDescription: 'Home' });
      expect(complete.status).toBe(200);

      for (const player of [org, p2, p3]) {
        // eslint-disable-next-line no-await-in-loop
        const completed = (await inboxOf(player.userId)).find((n) => n.type === 'gameCompleted');
        expect(completed).toBeDefined();
        expect(completed).toMatchObject({
          title: 'Game Completed',
          body: 'Tap to rate the players.',
        });
        expect(completed.data).toMatchObject({ gameId: String(gameId) });
      }
    });
});
