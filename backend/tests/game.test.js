/**
 * Game & matchmaking integration tests (Express + mongoose + firebase-auth stub).
 *
 * Auth: firebase-admin is mapped to tests/__mocks__/firebase-admin.js; users onboard via POST /auth/sync.
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
  return { token: r.token, userId: r.userId, user: r.user };
};

const createGameAs = async (token, overrides = {}) =>
  request(app).post(GAMES).set('Authorization', `Bearer ${token}`).send(mkGame(overrides));

describe('POST /games', () => {
  it('allows an organizer to create a game and returns 201', async () => {
    const { token } = await registerAndLogin(1, 'organizer');
    const res = await createGameAs(token);

    expect(res.status).toBe(201);
    expect(res.body.data.game.title).toBe('Sunday Football');
    expect(res.body.data.game.status).toBe('open');
  });

  it('allows a player role to create a game because restrictTo permits player organizer admin', async () => {
    const { token } = await registerAndLogin(1, 'player');
    const res = await createGameAs(token);
    expect(res.status).toBe(201);
  });

  it('requires a future scheduledAt (validator returns 422)', async () => {
    const { token } = await registerAndLogin(1, 'organizer');
    const res = await createGameAs(token, {
      scheduledAt: new Date(Date.now() - 60000).toISOString(),
    });

    expect(res.status).toBe(422);
    expect(Array.isArray(res.body.errors)).toBe(true);
  });

  it('auto-adds organizer as approved player', async () => {
    const { token, userId } = await registerAndLogin(1, 'organizer');
    const res = await createGameAs(token);

    const orgSlot = res.body.data.game.players.find((p) => p.user === `${userId}` || p.user?._id === `${userId}`);
    expect(orgSlot).toBeDefined();
    expect(orgSlot.status).toBe('approved');
  });

  it('accepts place metadata and coordinates in location payload', async () => {
    const { token } = await registerAndLogin(1, 'organizer');
    const res = await createGameAs(token);

    expect(res.status).toBe(201);
    expect(res.body.data.game.location.placeId).toBe('test-place-id');
    expect(res.body.data.game.location.coordinates.type).toBe('Point');
    expect(res.body.data.game.location.coordinates.coordinates).toEqual([-0.1955, 51.5099]);
  });

  it('rejects unauthenticated game creation', async () => {
    const res = await request(app).post(GAMES).send(mkGame());
    expect(res.status).toBe(401);
  });
});

describe('GET /games/:id', () => {
  it('returns a game by ID', async () => {
    const { token } = await registerAndLogin(1, 'organizer');
    const created = await createGameAs(token);
    const gameId = created.body.data.game._id;

    const res = await request(app).get(`${GAMES}/${gameId}`);

    expect(res.status).toBe(200);
    expect(res.body.data.game._id).toBe(gameId);
  });

  it('returns 404 for a non-existent game ID', async () => {
    const res = await request(app).get(`${GAMES}/507f1f77bcf86cd799439011`);
    expect(res.status).toBe(404);
  });
});

describe('GET /games (search)', () => {
  it('returns open games filtered by sport', async () => {
    const { token } = await registerAndLogin(1, 'organizer');
    await createGameAs(token, { sport: 'football' });
    await createGameAs(token, { sport: 'basketball', title: 'Basketball Game' });

    const res = await request(app).get(`${GAMES}?sport=football&status=open`);

    expect(res.status).toBe(200);
    expect(res.body.games.every((g) => g.sport === 'football')).toBe(true);
    expect(res.body.pagination).toBeDefined();
  });

  it('filters by city (case-insensitive)', async () => {
    const { token } = await registerAndLogin(1, 'organizer');
    await createGameAs(token, { location: { neighborhood: 'Chelsea', city: 'London', country: 'GB' } });
    await createGameAs(token, {
      title: 'Other Game',
      location: { neighborhood: 'Brooklyn', city: 'New York', country: 'US' },
    });

    const res = await request(app).get(`${GAMES}?city=london`);

    expect(res.status).toBe(200);
    expect(res.body.games.every((g) => g.location.city.toLowerCase().includes('london'))).toBe(true);
  });
});

describe('POST /games/:id/join', () => {
  it('allows a player to join an open game', async () => {
    const { token: orgToken } = await registerAndLogin(1, 'organizer');
    const { token: playerToken } = await registerAndLogin(2, 'player');

    const game = await createGameAs(orgToken);
    const gameId = game.body.data.game._id;

    const res = await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${playerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe('approved');
  });

  it('prevents joining the same game twice', async () => {
    const { token: orgToken } = await registerAndLogin(1, 'organizer');
    const { token: playerToken } = await registerAndLogin(2);

    const game = await createGameAs(orgToken);
    const gameId = game.body.data.game._id;

    await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${playerToken}`);
    const res = await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${playerToken}`);

    expect(res.status).toBe(409);
  });

  it('rejects joining a full game', async () => {
    const { token: orgToken } = await registerAndLogin(1, 'organizer');
    const { token: p2 } = await registerAndLogin(2);
    const { token: p3 } = await registerAndLogin(3);

    const game = await createGameAs(orgToken, { maxPlayers: 2 });
    const gameId = game.body.data.game._id;

    await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p2}`);

    const res = await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p3}`);

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/full/i);
  });

  it('detects a schedule conflict across overlapping fixtures', async () => {
    const { token: orgToken } = await registerAndLogin(1, 'organizer');
    const { token: playerToken } = await registerAndLogin(2);

    const sharedTime = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString();

    const gameA = await createGameAs(orgToken, { scheduledAt: sharedTime, durationMinutes: 90 });
    const gameB = await createGameAs(orgToken, { title: 'Game B', scheduledAt: sharedTime, durationMinutes: 90 });

    await request(app).post(`${GAMES}/${gameA.body.data.game._id}/join`).set('Authorization', `Bearer ${playerToken}`);

    const res = await request(app)
      .post(`${GAMES}/${gameB.body.data.game._id}/join`)
      .set('Authorization', `Bearer ${playerToken}`);

    expect(res.status).toBe(409);
    expect(res.body.message).toMatch(/conflict/i);
  });

  it('rejects joining with unknown Firebase token mapping', async () => {
    const { token: orgToken } = await registerAndLogin(1, 'organizer');
    const game = await createGameAs(orgToken);
    const gameId = game.body.data.game._id;

    const res = await request(app)
      .post(`${GAMES}/${gameId}/join`)
      .set('Authorization', 'Bearer totally-unregistered-test-token');

    expect(res.status).toBe(401);
  });
});

describe('DELETE /games/:id/leave', () => {
  it('allows a joined player to leave', async () => {
    const { token: orgToken } = await registerAndLogin(1, 'organizer');
    const { token: playerToken } = await registerAndLogin(2);

    const game = await createGameAs(orgToken);
    const gameId = game.body.data.game._id;

    await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${playerToken}`);
    const res = await request(app).delete(`${GAMES}/${gameId}/leave`).set('Authorization', `Bearer ${playerToken}`);

    expect(res.status).toBe(200);
  });

  it('blocks the organizer from leaving their own game', async () => {
    const { token } = await registerAndLogin(1, 'organizer');
    const game = await createGameAs(token);

    const res = await request(app)
      .delete(`${GAMES}/${game.body.data.game._id}/leave`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/cancel/i);
  });
});

describe('Invite & Approve flow', () => {
  it('organizer invites a user and then approves them after join', async () => {
    const { token: orgToken } = await registerAndLogin(1, 'organizer');
    const { token: p2Token, userId: p2Id } = await registerAndLogin(2, 'player');

    const game = await createGameAs(orgToken, { requiresApproval: true });
    const gameId = game.body.data.game._id;

    const invRes = await request(app)
      .post(`${GAMES}/${gameId}/invite/${p2Id}`)
      .set('Authorization', `Bearer ${orgToken}`);
    expect(invRes.status).toBe(200);

    await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p2Token}`);

    const appRes = await request(app)
      .patch(`${GAMES}/${gameId}/players/${p2Id}/approve`)
      .set('Authorization', `Bearer ${orgToken}`);

    expect(appRes.status).toBe(200);
    const slot = appRes.body.data.game.players.find((p) => `${p.user}` === `${p2Id}` || p.user?._id === `${p2Id}`);
    expect(slot?.status).toBe('approved');
  });

  it('returns 403 when a non-organizer attempts to approve a participant', async () => {
    const { token: orgToken } = await registerAndLogin(1, 'organizer');
    const { token: p2Token, userId: p2Id } = await registerAndLogin(2, 'player');
    const { token: p3Token } = await registerAndLogin(3, 'player');

    const game = await createGameAs(orgToken, { requiresApproval: true });
    const gameId = game.body.data.game._id;

    await request(app).post(`${GAMES}/${gameId}/invite/${p2Id}`).set('Authorization', `Bearer ${orgToken}`);
    await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p2Token}`);

    const res = await request(app)
      .patch(`${GAMES}/${gameId}/players/${p2Id}/approve`)
      .set('Authorization', `Bearer ${p3Token}`);

    expect(res.status).toBe(403);
  });
});

describe('DELETE /games/:id/players/:userId (kick)', () => {
  it('organizer can kick an approved player', async () => {
    const { token: orgToken } = await registerAndLogin(1, 'organizer');
    const { token: p2Token, userId: p2Id } = await registerAndLogin(2);

    const game = await createGameAs(orgToken);
    const gameId = game.body.data.game._id;

    await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p2Token}`);

    const res = await request(app)
      .delete(`${GAMES}/${gameId}/players/${p2Id}`)
      .set('Authorization', `Bearer ${orgToken}`)
      .send({ reason: 'No-show at last event' });

    expect(res.status).toBe(200);
    const slot = res.body.data.game.players.find((p) => `${p.user}` === `${p2Id}` || p.user?._id === `${p2Id}`);
    expect(slot?.status).toBe('kicked');
  });

  it('non-organizer cannot kick players', async () => {
    const { token: orgToken } = await registerAndLogin(1, 'organizer');
    const { token: p2Token, userId: p2Id } = await registerAndLogin(2);
    const { token: p3Token } = await registerAndLogin(3);

    const game = await createGameAs(orgToken);
    const gameId = game.body.data.game._id;

    await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p2Token}`);

    const res = await request(app)
      .delete(`${GAMES}/${gameId}/players/${p2Id}`)
      .set('Authorization', `Bearer ${p3Token}`)
      .send({ reason: 'Rogue kick attempt' });

    expect(res.status).toBe(403);
  });
});

describe('DELETE /games/:id (cancel)', () => {
  it('organizer can cancel their own game', async () => {
    const { token } = await registerAndLogin(1, 'organizer');
    const game = await createGameAs(token);
    const gameId = game.body.data.game._id;

    const res = await request(app).delete(`${GAMES}/${gameId}`).set('Authorization', `Bearer ${token}`).send({
      reason: 'Venue unavailable',
    });

    expect(res.status).toBe(200);
    expect(res.body.data.game.status).toBe('cancelled');
  });

  it('requires a cancellation reason payload', async () => {
    const { token } = await registerAndLogin(1, 'organizer');
    const game = await createGameAs(token);
    const gameId = game.body.data.game._id;

    const res = await request(app).delete(`${GAMES}/${gameId}`).set('Authorization', `Bearer ${token}`).send({});

    expect(res.status).toBe(422);
  });

  it('non-organiser cannot cancel another organiser fixture', async () => {
    const { token: org1 } = await registerAndLogin(1, 'organizer');
    const { token: org2 } = await registerAndLogin(2, 'organizer');
    const game = await createGameAs(org1);

    const res = await request(app)
      .delete(`${GAMES}/${game.body.data.game._id}`)
      .set('Authorization', `Bearer ${org2}`)
      .send({ reason: 'Trolling cancellation' });

    expect(res.status).toBe(403);
  });
});

describe('PATCH /games/:id/complete', () => {
  it('marks game completed and increments player stats for organiser', async () => {
    const { token: orgToken, userId: orgId } = await registerAndLogin(1, 'organizer');
    const { token: p2Token, userId: p2Id } = await registerAndLogin(2);

    const game = await createGameAs(orgToken);
    const gameId = game.body.data.game._id;

    await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p2Token}`);

    const res = await request(app)
      .patch(`${GAMES}/${gameId}/complete`)
      .set('Authorization', `Bearer ${orgToken}`)
      .send({
        score: '3-1',
        winnerDescription: 'Team A',
      });

    expect(res.status).toBe(200);
    expect(res.body.data.game.status).toBe('completed');

    const organizer = await User.findById(orgId);
    expect(organizer.stats.gamesPlayed).toBe(1);

    const participant = await User.findById(p2Id);
    expect(participant.stats.gamesPlayed).toBe(1);
  });
});

describe('POST /games/:id/merge/:targetId', () => {
  it('merges two under-capacity games', async () => {
    const { token: org1Token } = await registerAndLogin(1, 'organizer');
    const { token: org2Token } = await registerAndLogin(2, 'organizer');

    const source = await createGameAs(org1Token, { maxPlayers: 5 });
    const target = await createGameAs(org2Token, { maxPlayers: 5, title: 'Target Game' });

    const res = await request(app)
      .post(`${GAMES}/${source.body.data.game._id}/merge/${target.body.data.game._id}`)
      .set('Authorization', `Bearer ${org1Token}`)
      .send({ expandCapacity: false });

    expect(res.status).toBe(200);
    expect(res.body.data.game._id).toBe(target.body.data.game._id);
    expect(res.body.data.game.isMerged).toBe(true);
  });

  it('rejects merge when merged roster would burst target.maxPlayers without expandCapacity', async () => {
    const { token: orgSrc } = await registerAndLogin(1, 'organizer');
    const { token: orgTgt } = await registerAndLogin(2, 'organizer');
    const { token: p3 } = await registerAndLogin(3);
    const { token: p4 } = await registerAndLogin(4);
    const { token: p5 } = await registerAndLogin(5);

    const capacity = 4;
    const source = await createGameAs(orgSrc, { maxPlayers: capacity, title: 'Source overcrowd' });
    const target = await createGameAs(orgTgt, { maxPlayers: capacity, title: 'Target tight' });

    await request(app).post(`${GAMES}/${source.body.data.game._id}/join`).set('Authorization', `Bearer ${p3}`);
    await request(app).post(`${GAMES}/${source.body.data.game._id}/join`).set('Authorization', `Bearer ${p4}`);
    await request(app).post(`${GAMES}/${target.body.data.game._id}/join`).set('Authorization', `Bearer ${p5}`);

    const res = await request(app)
      .post(`${GAMES}/${source.body.data.game._id}/merge/${target.body.data.game._id}`)
      .set('Authorization', `Bearer ${orgSrc}`)
      .send({ expandCapacity: false });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/capacity|exceeding/i);
  });

  it('expands capacity and merges disjoint rosters into a single survivor game', async () => {
    const { token: orgSrc } = await registerAndLogin(1, 'organizer');
    const { token: orgTgt } = await registerAndLogin(2, 'organizer');
    const { token: p3 } = await registerAndLogin(3);
    const { token: p4 } = await registerAndLogin(4);
    const { token: p5 } = await registerAndLogin(5);

    const tightCap = 4;
    const source = await createGameAs(orgSrc, { maxPlayers: tightCap });
    const target = await createGameAs(orgTgt, { maxPlayers: tightCap, title: 'Target expand' });

    await request(app).post(`${GAMES}/${source.body.data.game._id}/join`).set('Authorization', `Bearer ${p3}`);
    await request(app).post(`${GAMES}/${source.body.data.game._id}/join`).set('Authorization', `Bearer ${p4}`);
    await request(app).post(`${GAMES}/${target.body.data.game._id}/join`).set('Authorization', `Bearer ${p5}`);

    const res = await request(app)
      .post(`${GAMES}/${source.body.data.game._id}/merge/${target.body.data.game._id}`)
      .set('Authorization', `Bearer ${orgSrc}`)
      .send({ expandCapacity: true });

    expect(res.status).toBe(200);
    expect(res.body.data.game.maxPlayers).toBeGreaterThan(tightCap);
  });
});
