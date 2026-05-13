/**
 * Rating system — service & integration tests.
 *
 * Three big surfaces are covered:
 *
 *  1. POST /api/v1/ratings — creating a peer rating, the User.stats
 *     rollup it triggers, and the negative paths (self-rate, dedup,
 *     non-completed game).
 *
 *  2. GET /api/v1/ratings/pending + POST /api/v1/ratings/dismiss —
 *     surfacing un-rated opponents and the persistent "Don't rate this
 *     game" skip flag.
 *
 *  3. Rating.recalculateAllUserStats — the admin reconciliation pass
 *     that backfills legacy `compositeScore` values and bulk-syncs every
 *     ratee's User.stats from the live Rating corpus. This is the
 *     migration path for documents written before the service started
 *     computing compositeScore explicitly (legacy upserts via
 *     `findOneAndUpdate` bypassed Mongoose document middleware).
 */

const request = require('supertest');
const mongoose = require('mongoose');
const testDb = require('./helpers/testDb');
const createApp = require('../src/app');
const User = require('../src/models/User.model');
const Rating = require('../src/models/Rating.model');
const RatingDismissal = require('../src/models/RatingDismissal.model');
const ratingService = require('../src/services/rating.service');
const { syncFirebaseUser } = require('./helpers/authTestFactory');

const app = createApp();

beforeAll(testDb.connect);
afterEach(testDb.clearAll);
afterAll(testDb.disconnect);

const GAMES = '/api/v1/games';
const RATINGS = '/api/v1/ratings';

// ─────────────────────────────────────────────────────────────────────────────
// Fixtures
// ─────────────────────────────────────────────────────────────────────────────

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
    firstName: `Rater${slot}`,
    lastName: 'Test',
  });
  expect(r.status).toBe(200);
  return { token: r.token, userId: r.userId };
};

/**
 * Stands up a fully-played 3-player game ready to be rated. Returns the
 * gameId and the three actors (organizer + two extra approved players).
 */
const seedCompletedGame = async () => {
  const org = await registerAndLogin(1, 'organizer');
  const p2 = await registerAndLogin(2, 'player');
  const p3 = await registerAndLogin(3, 'player');

  const create = await request(app)
    .post(GAMES)
    .set('Authorization', `Bearer ${org.token}`)
    .send(mkGame());
  expect(create.status).toBe(201);
  const gameId = create.body.data.game._id;

  for (const p of [p2, p3]) {
    // eslint-disable-next-line no-await-in-loop
    const join = await request(app)
      .post(`${GAMES}/${gameId}/join`)
      .set('Authorization', `Bearer ${p.token}`);
    expect(join.status).toBeLessThan(400);
  }

  const complete = await request(app)
    .patch(`${GAMES}/${gameId}/complete`)
    .set('Authorization', `Bearer ${org.token}`)
    .send({ score: '3-1', winnerDescription: 'Team A' });
  expect(complete.status).toBe(200);
  expect(complete.body.data.game.status).toBe('completed');

  return { gameId, org, p2, p3 };
};

// ─────────────────────────────────────────────────────────────────────────────
// Scenario 1 — service ratePlayer creates a doc and rolls up User.stats
// ─────────────────────────────────────────────────────────────────────────────

describe('Scenario 1 — POST /ratings rolls a Rating doc + invokes recalculateUserStats', () => {
  it('creates a Rating document with the computed compositeScore and rolls up User.stats', async () => {
    const { gameId, p2, p3 } = await seedCompletedGame();

    const res = await request(app)
      .post(RATINGS)
      .set('Authorization', `Bearer ${p2.token}`)
      .send({
        rateeId: p3.userId,
        gameId,
        reliabilityScore: 5,
        behaviorScore: 4,
        comment: 'Great teammate',
      });

    expect(res.status).toBe(201);
    expect(res.body.data.rating.compositeScore).toBeCloseTo(4.5, 2);

    // Doc on disk
    const persisted = await Rating.findOne({
      rater: p2.userId,
      ratee: p3.userId,
      game: gameId,
    });
    expect(persisted).not.toBeNull();
    expect(persisted.compositeScore).toBeCloseTo(4.5, 2);

    // Side effect: ratee's User.stats was rolled up by Rating.recalculateUserStats
    const ratee = await User.findById(p3.userId);
    expect(ratee.stats.totalRatings).toBe(1);
    expect(ratee.stats.averageRating).toBeCloseTo(4.5, 2);
  });

  it('invokes Rating.recalculateUserStats once per successful submission (spy verification)', async () => {
    const { gameId, p2, p3 } = await seedCompletedGame();
    const spy = jest.spyOn(Rating, 'recalculateUserStats');

    try {
      const res = await request(app)
        .post(RATINGS)
        .set('Authorization', `Bearer ${p2.token}`)
        .send({ rateeId: p3.userId, gameId, reliabilityScore: 5, behaviorScore: 5 });
      expect(res.status).toBe(201);

      expect(spy).toHaveBeenCalledTimes(1);
      // The spy is called with the ratee id (Mongoose ObjectId or string).
      const arg = spy.mock.calls[0][0].toString();
      expect(arg).toBe(p3.userId.toString());
    } finally {
      spy.mockRestore();
    }
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Scenario 2 — multiple ratings aggregate accurately
// ─────────────────────────────────────────────────────────────────────────────

describe('Scenario 2 — User.stats.averageRating + totalRatings reflect every submitted rating', () => {
  it('averages multiple ratings from different raters correctly', async () => {
    const { gameId, org, p2, p3 } = await seedCompletedGame();

    // org rates p3:   reliability=5, behavior=3  → composite 4.0
    // p2 rates p3:    reliability=4, behavior=4  → composite 4.0
    // Expected average for p3 = 4.0 over 2 ratings.
    const r1 = await request(app)
      .post(RATINGS)
      .set('Authorization', `Bearer ${org.token}`)
      .send({ rateeId: p3.userId, gameId, reliabilityScore: 5, behaviorScore: 3 });
    const r2 = await request(app)
      .post(RATINGS)
      .set('Authorization', `Bearer ${p2.token}`)
      .send({ rateeId: p3.userId, gameId, reliabilityScore: 4, behaviorScore: 4 });
    expect(r1.status).toBe(201);
    expect(r2.status).toBe(201);

    const ratee = await User.findById(p3.userId);
    expect(ratee.stats.totalRatings).toBe(2);
    expect(ratee.stats.averageRating).toBeCloseTo(4.0, 2);
  });

  it('rolls up an asymmetric two-rater scenario without rounding drift', async () => {
    const { gameId, org, p2, p3 } = await seedCompletedGame();

    // org → p3:  5/5 = 5.0
    // p2  → p3:  2/3 = 2.5
    // Expected average for p3 = (5.0 + 2.5) / 2 = 3.75
    await request(app)
      .post(RATINGS)
      .set('Authorization', `Bearer ${org.token}`)
      .send({ rateeId: p3.userId, gameId, reliabilityScore: 5, behaviorScore: 5 });
    await request(app)
      .post(RATINGS)
      .set('Authorization', `Bearer ${p2.token}`)
      .send({ rateeId: p3.userId, gameId, reliabilityScore: 2, behaviorScore: 3 });

    const ratee = await User.findById(p3.userId);
    expect(ratee.stats.totalRatings).toBe(2);
    expect(ratee.stats.averageRating).toBeCloseTo(3.75, 2);
  });

  it('keeps each user\'s stats independent', async () => {
    const { gameId, org, p2, p3 } = await seedCompletedGame();

    // p2 rates p3 (high) and org (low). p2's own stats stay zero.
    await request(app)
      .post(RATINGS)
      .set('Authorization', `Bearer ${p2.token}`)
      .send({ rateeId: p3.userId, gameId, reliabilityScore: 5, behaviorScore: 5 });
    await request(app)
      .post(RATINGS)
      .set('Authorization', `Bearer ${p2.token}`)
      .send({ rateeId: org.userId, gameId, reliabilityScore: 2, behaviorScore: 2 });

    const ratee1 = await User.findById(p3.userId);
    const ratee2 = await User.findById(org.userId);
    const rater = await User.findById(p2.userId);

    expect(ratee1.stats.averageRating).toBeCloseTo(5.0, 2);
    expect(ratee1.stats.totalRatings).toBe(1);
    expect(ratee2.stats.averageRating).toBeCloseTo(2.0, 2);
    expect(ratee2.stats.totalRatings).toBe(1);
    // p2 received zero ratings, so their stats should remain pristine.
    expect(rater.stats.totalRatings).toBe(0);
    expect(rater.stats.averageRating).toBe(0);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Scenario 3 — recalculate-all migration backfills legacy compositeScore
// ─────────────────────────────────────────────────────────────────────────────

describe('Scenario 3 — Rating.recalculateAllUserStats migration', () => {
  it('backfills compositeScore on legacy rows and bulk-updates User.stats', async () => {
    // Make a self-consistent fixture: two real users + a game they were
    // both approved in. We then drop legacy rating rows directly through
    // the raw collection so the pre-save hook (which would compute
    // compositeScore) is bypassed — exactly the historical shape we need
    // to migrate away from.
    const { gameId, p2, p3 } = await seedCompletedGame();

    // Reset User.stats so we know the migration brought them up to date,
    // not the on-write rollup from `ratePlayer`.
    await User.updateMany(
      { _id: { $in: [p2.userId, p3.userId] } },
      { $set: { 'stats.averageRating': 0, 'stats.totalRatings': 0 } },
    );

    const legacyRows = [
      {
        rater: new mongoose.Types.ObjectId(p2.userId),
        ratee: new mongoose.Types.ObjectId(p3.userId),
        game: new mongoose.Types.ObjectId(gameId),
        reliabilityScore: 5,
        behaviorScore: 3,
        // compositeScore intentionally missing — this is the corruption
        // the migration repairs.
        isAnonymous: false,
        isFlagged: false,
        isHidden: false,
        deletedAt: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        rater: new mongoose.Types.ObjectId(p3.userId),
        ratee: new mongoose.Types.ObjectId(p2.userId),
        game: new mongoose.Types.ObjectId(gameId),
        reliabilityScore: 4,
        behaviorScore: 4,
        isAnonymous: false,
        isFlagged: false,
        isHidden: false,
        deletedAt: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    ];
    await Rating.collection.insertMany(legacyRows);

    // Pre-condition: rows have null/undefined compositeScore.
    const beforeMigration = await Rating.find({}).lean();
    expect(beforeMigration).toHaveLength(2);
    for (const r of beforeMigration) {
      expect(r.compositeScore == null).toBe(true);
    }

    const result = await ratingService.recalculateAllStats();

    // Counters returned by the migration.
    expect(result.compositeBackfilled).toBe(2);
    expect(result.rateesProcessed).toBe(2);
    expect(result.usersUpdated).toBeGreaterThanOrEqual(2);

    // Post-condition 1: every rating row now has a numeric compositeScore.
    const afterMigration = await Rating.find({}).lean();
    expect(afterMigration).toHaveLength(2);
    const byRatee = Object.fromEntries(
      afterMigration.map((r) => [r.ratee.toString(), r]),
    );
    expect(byRatee[p3.userId.toString()].compositeScore).toBeCloseTo(4.0, 2);
    expect(byRatee[p2.userId.toString()].compositeScore).toBeCloseTo(4.0, 2);

    // Post-condition 2: both users' denormalised User.stats reflect the
    // recomputed totals.
    const refreshedP2 = await User.findById(p2.userId);
    const refreshedP3 = await User.findById(p3.userId);
    expect(refreshedP3.stats.totalRatings).toBe(1);
    expect(refreshedP3.stats.averageRating).toBeCloseTo(4.0, 2);
    expect(refreshedP2.stats.totalRatings).toBe(1);
    expect(refreshedP2.stats.averageRating).toBeCloseTo(4.0, 2);
  });

  it('is idempotent — running the migration a second time changes nothing', async () => {
    const { gameId, p2, p3 } = await seedCompletedGame();

    await Rating.collection.insertOne({
      rater: new mongoose.Types.ObjectId(p2.userId),
      ratee: new mongoose.Types.ObjectId(p3.userId),
      game: new mongoose.Types.ObjectId(gameId),
      reliabilityScore: 5,
      behaviorScore: 5,
      isAnonymous: false,
      isFlagged: false,
      isHidden: false,
      deletedAt: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const first = await ratingService.recalculateAllStats();
    const second = await ratingService.recalculateAllStats();

    // Backfill counter is zero on the second pass — everything already
    // has a compositeScore from the first pass.
    expect(first.compositeBackfilled).toBe(1);
    expect(second.compositeBackfilled).toBe(0);

    const ratee = await User.findById(p3.userId);
    expect(ratee.stats.totalRatings).toBe(1);
    expect(ratee.stats.averageRating).toBeCloseTo(5.0, 2);
  });

  it('resets stats for users whose only ratings have been soft-deleted', async () => {
    const { gameId, p2, p3 } = await seedCompletedGame();

    // Live rating: stats should rise.
    await request(app)
      .post(RATINGS)
      .set('Authorization', `Bearer ${p2.token}`)
      .send({ rateeId: p3.userId, gameId, reliabilityScore: 5, behaviorScore: 5 });
    const before = await User.findById(p3.userId);
    expect(before.stats.totalRatings).toBe(1);

    // Soft-delete every rating; until the migration runs, the rolled-up
    // stats stay stale.
    await Rating.updateMany({}, { $set: { deletedAt: new Date() } });

    const result = await ratingService.recalculateAllStats();
    expect(result.usersReset).toBeGreaterThanOrEqual(1);

    const after = await User.findById(p3.userId);
    expect(after.stats.totalRatings).toBe(0);
    expect(after.stats.averageRating).toBe(0);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Edge cases
// ─────────────────────────────────────────────────────────────────────────────

describe('Edge cases — self-rating + dedup', () => {
  it('rejects self-rating with 400', async () => {
    const { gameId, p2 } = await seedCompletedGame();
    const res = await request(app)
      .post(RATINGS)
      .set('Authorization', `Bearer ${p2.token}`)
      .send({ rateeId: p2.userId, gameId, reliabilityScore: 5, behaviorScore: 5 });
    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/yourself/i);
  });

  it('rejects rating a game that has not been completed', async () => {
    const org = await registerAndLogin(1, 'organizer');
    const p2 = await registerAndLogin(2);
    const create = await request(app)
      .post(GAMES)
      .set('Authorization', `Bearer ${org.token}`)
      .send(mkGame());
    const gameId = create.body.data.game._id;
    await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p2.token}`);

    const res = await request(app)
      .post(RATINGS)
      .set('Authorization', `Bearer ${p2.token}`)
      .send({ rateeId: org.userId, gameId, reliabilityScore: 5, behaviorScore: 5 });
    expect(res.status).toBe(404);
  });

  it('upserts on (rater, ratee, game) — a second submission overwrites the first, never duplicates', async () => {
    const { gameId, p2, p3 } = await seedCompletedGame();

    const first = await request(app)
      .post(RATINGS)
      .set('Authorization', `Bearer ${p2.token}`)
      .send({ rateeId: p3.userId, gameId, reliabilityScore: 1, behaviorScore: 1 });
    const second = await request(app)
      .post(RATINGS)
      .set('Authorization', `Bearer ${p2.token}`)
      .send({ rateeId: p3.userId, gameId, reliabilityScore: 5, behaviorScore: 5 });

    expect(first.status).toBe(201);
    expect(second.status).toBe(201);

    // Single row on disk — the unique index on (rater, ratee, game) plus
    // the service's findOneAndUpdate/upsert guarantee dedup.
    const rows = await Rating.find({ rater: p2.userId, ratee: p3.userId, game: gameId });
    expect(rows).toHaveLength(1);
    expect(rows[0].compositeScore).toBeCloseTo(5.0, 2);

    // Ratee's stats reflect only the latest (5.0) value.
    const ratee = await User.findById(p3.userId);
    expect(ratee.stats.totalRatings).toBe(1);
    expect(ratee.stats.averageRating).toBeCloseTo(5.0, 2);
  });

  it('the unique compound index physically rejects a parallel duplicate insert', async () => {
    const { gameId, p2, p3 } = await seedCompletedGame();

    const raterId = new mongoose.Types.ObjectId(p2.userId);
    const rateeId = new mongoose.Types.ObjectId(p3.userId);
    const gameOid = new mongoose.Types.ObjectId(gameId);

    await Rating.collection.insertOne({
      rater: raterId,
      ratee: rateeId,
      game: gameOid,
      reliabilityScore: 5,
      behaviorScore: 5,
      compositeScore: 5,
      isAnonymous: false,
      isFlagged: false,
      isHidden: false,
      deletedAt: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    await expect(
      Rating.collection.insertOne({
        rater: raterId,
        ratee: rateeId,
        game: gameOid,
        reliabilityScore: 1,
        behaviorScore: 1,
        compositeScore: 1,
        isAnonymous: false,
        isFlagged: false,
        isHidden: false,
        deletedAt: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    ).rejects.toThrow(/E11000|duplicate/i);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Pending + Dismiss
// ─────────────────────────────────────────────────────────────────────────────

describe('GET /ratings/pending + POST /ratings/dismiss', () => {
  it('lists un-rated opponents for each completed game the viewer played in', async () => {
    const { gameId, org, p2, p3 } = await seedCompletedGame();

    const res = await request(app)
      .get(`${RATINGS}/pending`)
      .set('Authorization', `Bearer ${p2.token}`);

    expect(res.status).toBe(200);
    const { pending } = res.body.data;
    expect(pending).toHaveLength(1);
    expect(pending[0].game.id).toBe(gameId);

    const ids = pending[0].pendingPlayers.map((p) => p._id);
    expect(ids).toEqual(expect.arrayContaining([org.userId, p3.userId]));
    expect(ids).not.toContain(p2.userId);
  });

  it('drops a game once the viewer has rated every opponent', async () => {
    const { gameId, org, p2, p3 } = await seedCompletedGame();

    for (const ratee of [org.userId, p3.userId]) {
      // eslint-disable-next-line no-await-in-loop
      const r = await request(app)
        .post(RATINGS)
        .set('Authorization', `Bearer ${p2.token}`)
        .send({ rateeId: ratee, gameId, reliabilityScore: 5, behaviorScore: 5 });
      expect(r.status).toBe(201);
    }

    const res = await request(app)
      .get(`${RATINGS}/pending`)
      .set('Authorization', `Bearer ${p2.token}`);

    expect(res.status).toBe(200);
    expect(res.body.data.pending).toEqual([]);
  });

  it('dismiss persists a RatingDismissal row and is idempotent on a second call', async () => {
    const { gameId, p2 } = await seedCompletedGame();

    const before = await request(app)
      .get(`${RATINGS}/pending`)
      .set('Authorization', `Bearer ${p2.token}`);
    expect(before.body.data.pending).toHaveLength(1);

    const first = await request(app)
      .post(`${RATINGS}/dismiss`)
      .set('Authorization', `Bearer ${p2.token}`)
      .send({ gameId });
    const second = await request(app)
      .post(`${RATINGS}/dismiss`)
      .set('Authorization', `Bearer ${p2.token}`)
      .send({ gameId });

    expect(first.status).toBe(200);
    expect(second.status).toBe(200);

    const rows = await RatingDismissal.find({ rater: p2.userId, game: gameId });
    expect(rows).toHaveLength(1);

    const after = await request(app)
      .get(`${RATINGS}/pending`)
      .set('Authorization', `Bearer ${p2.token}`);
    expect(after.body.data.pending).toEqual([]);
  });
});
