/**
 * Auto-complete stale games — PRD hourly sweep.
 */

const request = require('supertest');
const testDb = require('./helpers/testDb');
const createApp = require('../src/app');
const Game = require('../src/models/Game.model');
const User = require('../src/models/User.model');
const Notification = require('../src/models/Notification.model');
const GameService = require('../src/services/game.service');
const { syncFirebaseUser } = require('./helpers/authTestFactory');

const app = createApp();

beforeAll(testDb.connect);
afterEach(testDb.clearAll);
afterAll(testDb.disconnect);

const GAMES = '/api/v1/games';

const mkGame = (overrides = {}) => ({
  title: 'Stale Sweep Test',
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

describe('GameService.autoCompleteStaleGames', () => {
  it('completes games scheduled more than 4 hours ago and increments gamesPlayed', async () => {
    const { token: orgToken, userId: orgId } = await registerAndLogin(1, 'organizer');
    const { token: p2Token, userId: p2Id } = await registerAndLogin(2);

    const created = await request(app)
      .post(GAMES)
      .set('Authorization', `Bearer ${orgToken}`)
      .send(mkGame());
    expect(created.status).toBe(201);
    const gameId = created.body.data.game._id;

    await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p2Token}`);

    const fiveHoursAgo = new Date(Date.now() - 5 * 60 * 60 * 1000);
    await Game.findByIdAndUpdate(gameId, {
      scheduledAt: fiveHoursAgo,
      status: 'full',
    });

    const summary = await GameService.autoCompleteStaleGames();

    expect(summary.scanned).toBe(1);
    expect(summary.completed).toContain(gameId);
    expect(summary.errors).toHaveLength(0);

    const game = await Game.findById(gameId).lean();
    expect(game.status).toBe('completed');
    expect(game.result?.winnerDescription).toBe('Auto-completed');

    const organizer = await User.findById(orgId);
    const participant = await User.findById(p2Id);
    expect(organizer.stats.gamesPlayed).toBe(1);
    expect(participant.stats.gamesPlayed).toBe(1);

    const orgInbox = await Notification.find({ recipient: orgId, type: 'gameCompleted' }).lean();
    const p2Inbox = await Notification.find({ recipient: p2Id, type: 'gameCompleted' }).lean();
    expect(orgInbox.length).toBeGreaterThanOrEqual(1);
    expect(p2Inbox.length).toBeGreaterThanOrEqual(1);
  });

  it('does not complete games still within the 4-hour window', async () => {
    const { token: orgToken } = await registerAndLogin(3, 'organizer');

    const created = await request(app)
      .post(GAMES)
      .set('Authorization', `Bearer ${orgToken}`)
      .send(mkGame());
    expect(created.status).toBe(201);
    const gameId = created.body.data.game._id;

    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);
    await Game.findByIdAndUpdate(gameId, { scheduledAt: twoHoursAgo, status: 'open' });

    const summary = await GameService.autoCompleteStaleGames();

    expect(summary.completed).not.toContain(gameId);

    const game = await Game.findById(gameId).lean();
    expect(game.status).toBe('open');
  });
});
