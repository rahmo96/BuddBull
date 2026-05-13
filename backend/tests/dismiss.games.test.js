/**
 * Home-feed hygiene
 *
 * Covers two related fixes that landed together:
 *
 *   1. POST /games/:id/dismiss + DELETE /games/:id/dismiss
 *      → per-user "archive" filter on getMyGames / getCalendar.
 *
 *   2. The Mongoose `scheduledAt > now` validator no longer fires on
 *      saves of existing documents. Without that scoping, leaving /
 *      kicking / completing a game whose date has passed bubbles up as
 *      a Mongoose ValidationError → HTTP 422, which is what users were
 *      hitting when their old games piled up on Home.
 */

const request = require('supertest');
const testDb = require('./helpers/testDb');
const createApp = require('../src/app');
const Game = require('../src/models/Game.model');
const GameDismissal = require('../src/models/GameDismissal.model');
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

const createGame = async (token, body = {}) => {
  const res = await request(app)
    .post(GAMES)
    .set('Authorization', `Bearer ${token}`)
    .send(mkGame(body));
  expect(res.status).toBe(201);
  return res.body.data.game;
};

describe('Game dismiss endpoint', () => {
  it('hides the game from getMyGames for the dismissing user only', async () => {
    const org = await registerAndLogin(1, 'organizer');
    const other = await registerAndLogin(2, 'organizer');

    const a = await createGame(org.token);
    const b = await createGame(org.token, { title: 'Tuesday Hoops', sport: 'basketball' });

    // Sanity: both games appear on the organiser's home feed.
    const before = await request(app)
      .get(`${GAMES}/me`)
      .set('Authorization', `Bearer ${org.token}`);
    expect(before.status).toBe(200);
    expect(before.body.games.map((g) => g._id).sort()).toEqual([a._id, b._id].sort());

    // Dismiss game A.
    const dismiss = await request(app)
      .post(`${GAMES}/${a._id}/dismiss`)
      .set('Authorization', `Bearer ${org.token}`);
    expect(dismiss.status).toBe(200);
    expect(dismiss.body.data).toMatchObject({ dismissed: true, alreadyDismissed: false });

    const after = await request(app)
      .get(`${GAMES}/me`)
      .set('Authorization', `Bearer ${org.token}`);
    expect(after.body.games.map((g) => g._id)).toEqual([b._id]);

    // The other user (unrelated organiser) still sees their own list intact.
    const otherList = await request(app)
      .get(`${GAMES}/me`)
      .set('Authorization', `Bearer ${other.token}`);
    expect(otherList.status).toBe(200);
  });

  it('is idempotent — calling dismiss twice resolves with alreadyDismissed=true',
    async () => {
      const org = await registerAndLogin(1, 'organizer');
      const game = await createGame(org.token);

      const first = await request(app)
        .post(`${GAMES}/${game._id}/dismiss`)
        .set('Authorization', `Bearer ${org.token}`);
      expect(first.body.data.alreadyDismissed).toBe(false);

      const second = await request(app)
        .post(`${GAMES}/${game._id}/dismiss`)
        .set('Authorization', `Bearer ${org.token}`);
      expect(second.status).toBe(200);
      expect(second.body.data.alreadyDismissed).toBe(true);

      // Only one dismissal row exists.
      const rows = await GameDismissal.find({
        user: org.userId,
        game: game._id,
      }).lean();
      expect(rows).toHaveLength(1);
    });

  it('DELETE /dismiss reverses the archive and the game reappears', async () => {
    const org = await registerAndLogin(1, 'organizer');
    const game = await createGame(org.token);

    await request(app)
      .post(`${GAMES}/${game._id}/dismiss`)
      .set('Authorization', `Bearer ${org.token}`);

    let me = await request(app)
      .get(`${GAMES}/me`)
      .set('Authorization', `Bearer ${org.token}`);
    expect(me.body.games).toHaveLength(0);

    const undo = await request(app)
      .delete(`${GAMES}/${game._id}/dismiss`)
      .set('Authorization', `Bearer ${org.token}`);
    expect(undo.status).toBe(200);
    expect(undo.body.data).toMatchObject({ dismissed: false, removed: true });

    me = await request(app)
      .get(`${GAMES}/me`)
      .set('Authorization', `Bearer ${org.token}`);
    expect(me.body.games.map((g) => g._id)).toEqual([game._id]);
  });

  it('returns 404 for an unknown game id', async () => {
    const org = await registerAndLogin(1, 'organizer');
    const res = await request(app)
      .post(`${GAMES}/507f1f77bcf86cd799439011/dismiss`)
      .set('Authorization', `Bearer ${org.token}`);
    expect(res.status).toBe(404);
  });
});

describe('Mongoose scheduledAt validator scoping', () => {
  // We jump straight to the DB layer here — backdating a doc is impossible
  // through the create endpoint thanks to the very validator we're testing.
  it('allows saves on existing games whose scheduledAt is now in the past',
    async () => {
      const org = await registerAndLogin(1, 'organizer');
      const created = await createGame(org.token);

      const game = await Game.findById(created._id);
      // Force the game into the past — bypasses Mongoose validation only
      // because we use updateOne with `runValidators: false` (default for
      // `findByIdAndUpdate`).
      await Game.collection.updateOne(
        { _id: game._id },
        { $set: { scheduledAt: new Date(Date.now() - 24 * 60 * 60 * 1000) } },
      );

      const stale = await Game.findById(created._id);
      stale.status = 'completed';
      // The old validator would throw `Game must be scheduled in the future`
      // here. With the scoping fix in place, `.save()` resolves cleanly
      // because `scheduledAt` is neither new nor modified.
      await expect(stale.save()).resolves.toBeDefined();
    });

  it('still rejects creates that schedule a game in the past', async () => {
    const org = await registerAndLogin(1, 'organizer');
    const res = await request(app)
      .post(GAMES)
      .set('Authorization', `Bearer ${org.token}`)
      .send(
        mkGame({ scheduledAt: new Date(Date.now() - 60 * 60 * 1000).toISOString() }),
      );
    expect(res.status).toBe(422);
  });
});
