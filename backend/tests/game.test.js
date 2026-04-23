/**
 * Game & Matchmaking Integration Tests
 *
 * Coverage:
 *  - Create game (organiser only, player blocked)
 *  - Get game by ID
 *  - Search games (sport, city, status filters)
 *  - Join game (success, already joined, schedule conflict)
 *  - Leave game
 *  - Invite → Approve flow
 *  - Kick player
 *  - Cancel game
 *  - Complete game (stat increment check)
 *  - Group merge (capacity check, expandCapacity flag)
 *  - Double-booking prevention
 */

const request = require('supertest');
const testDb = require('./helpers/testDb');
const createApp = require('../src/app');

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

const AUTH = '/api/v1/auth';
const GAMES = '/api/v1/games';

const mkUser = (n, role = 'player') => ({
  firstName: `User${n}`,
  lastName: 'Test',
  username: `user${n}t`,
  email: `user${n}@game.test`,
  password: 'Password1',
  role,
});

const mkGame = (overrides = {}) => ({
  title: 'Sunday Football',
  sport: 'football',
  scheduledAt: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(), // 3 days from now
  durationMinutes: 90,
  location: { neighborhood: 'Notting Hill', city: 'London', country: 'GB' },
  maxPlayers: 10,
  requiredSkillLevel: 'any',
  ...overrides,
});

const registerAndLogin = async (n, role = 'player') => {
  const dto = mkUser(n, role);
  await request(app).post(`${AUTH}/register`).send(dto);
  const res = await request(app).post(`${AUTH}/login`).send({ email: dto.email, password: dto.password });
  return { token: res.body.accessToken, userId: res.body.data.user._id };
};

const createGameAs = async (token, overrides = {}) =>
  request(app).post(GAMES).set('Authorization', `Bearer ${token}`).send(mkGame(overrides));

// ─────────────────────────────────────────────
//  POST /games  — Create
// ─────────────────────────────────────────────

describe('POST /games', () => {
  it('allows an organizer to create a game and returns 201', async () => {
    const { token } = await registerAndLogin(1, 'organizer');
    const res = await createGameAs(token);

    expect(res.status).toBe(201);
    expect(res.body.data.game.title).toBe('Sunday Football');
    expect(res.body.data.game.status).toBe('open');
  });

  it('rejects a player trying to create a game with 403', async () => {
    const { token } = await registerAndLogin(1, 'player');
    const res = await createGameAs(token);

    expect(res.status).toBe(403);
  });

  it('requires a future scheduledAt', async () => {
    const { token } = await registerAndLogin(1, 'organizer');
    const res = await createGameAs(token, {
      scheduledAt: new Date(Date.now() - 60000).toISOString(),
    });

    expect(res.status).toBe(422);
  });

  it('auto-adds organizer as approved player', async () => {
    const { token, userId } = await registerAndLogin(1, 'organizer');
    const res = await createGameAs(token);

    const orgSlot = res.body.data.game.players.find((p) => p.user === userId || p.user?._id === userId);
    expect(orgSlot).toBeDefined();
    expect(orgSlot.status).toBe('approved');
  });
});

// ─────────────────────────────────────────────
//  GET /games/:id
// ─────────────────────────────────────────────

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

// ─────────────────────────────────────────────
//  GET /games  — Search
// ─────────────────────────────────────────────

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
    await createGameAs(token, { title: 'Other Game', location: { neighborhood: 'Brooklyn', city: 'New York', country: 'US' } });

    const res = await request(app).get(`${GAMES}?city=london`);

    expect(res.status).toBe(200);
    expect(res.body.games.every((g) => g.location.city.toLowerCase().includes('london'))).toBe(true);
  });
});

// ─────────────────────────────────────────────
//  POST /games/:id/join
// ─────────────────────────────────────────────

describe('POST /games/:id/join', () => {
  it('allows a player to join an open game', async () => {
    const { token: orgToken } = await registerAndLogin(1, 'organizer');
    const { token: playerToken } = await registerAndLogin(2, 'player');

    const game = await createGameAs(orgToken);
    const gameId = game.body.data.game._id;

    const res = await request(app)
      .post(`${GAMES}/${gameId}/join`)
      .set('Authorization', `Bearer ${playerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe('approved'); // no requiresApproval
  });

  it('prevents joining the same game twice', async () => {
    const { token: orgToken } = await registerAndLogin(1, 'organizer');
    const { token: playerToken } = await registerAndLogin(2);

    const game = await createGameAs(orgToken);
    const gameId = game.body.data.game._id;

    await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${playerToken}`);
    const res = await request(app)
      .post(`${GAMES}/${gameId}/join`)
      .set('Authorization', `Bearer ${playerToken}`);

    expect(res.status).toBe(409);
  });

  it('rejects joining a full game', async () => {
    const { token: orgToken } = await registerAndLogin(1, 'organizer');
    const { token: p2 } = await registerAndLogin(2);
    const { token: p3 } = await registerAndLogin(3);

    // Create game with maxPlayers = 2 (organizer fills slot 1)
    const game = await createGameAs(orgToken, { maxPlayers: 2 });
    const gameId = game.body.data.game._id;

    await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p2}`);

    const res = await request(app)
      .post(`${GAMES}/${gameId}/join`)
      .set('Authorization', `Bearer ${p3}`);

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/full/i);
  });

  it('detects a schedule conflict', async () => {
    const { token: orgToken } = await registerAndLogin(1, 'organizer');
    const { token: playerToken } = await registerAndLogin(2);

    const sharedTime = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString();

    // Game A
    const gameA = await createGameAs(orgToken, { scheduledAt: sharedTime, durationMinutes: 90 });
    // Game B — same time slot
    const gameB = await createGameAs(orgToken, { title: 'Game B', scheduledAt: sharedTime, durationMinutes: 90 });

    await request(app).post(`${GAMES}/${gameA.body.data.game._id}/join`).set('Authorization', `Bearer ${playerToken}`);

    const res = await request(app)
      .post(`${GAMES}/${gameB.body.data.game._id}/join`)
      .set('Authorization', `Bearer ${playerToken}`);

    expect(res.status).toBe(409);
    expect(res.body.message).toMatch(/conflict/i);
  });
});

// ─────────────────────────────────────────────
//  DELETE /games/:id/leave
// ─────────────────────────────────────────────

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

// ─────────────────────────────────────────────
//  Invite → Approve flow
// ─────────────────────────────────────────────

describe('Invite & Approve flow', () => {
  it('organizer invites a user and then approves them', async () => {
    const { token: orgToken } = await registerAndLogin(1, 'organizer');
    const { userId: p2Id } = await registerAndLogin(2);

    const game = await createGameAs(orgToken, { requiresApproval: true });
    const gameId = game.body.data.game._id;

    // Invite
    const invRes = await request(app)
      .post(`${GAMES}/${gameId}/invite/${p2Id}`)
      .set('Authorization', `Bearer ${orgToken}`);
    expect(invRes.status).toBe(200);

    // Player accepts invite (joins)
    const { token: p2Token } = await registerAndLogin(2);
    await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p2Token}`);

    // Organizer approves
    const appRes = await request(app)
      .patch(`${GAMES}/${gameId}/players/${p2Id}/approve`)
      .set('Authorization', `Bearer ${orgToken}`);

    expect(appRes.status).toBe(200);
    const slot = appRes.body.data.game.players.find((p) => p.user === p2Id || p.user?._id === p2Id);
    expect(slot?.status).toBe('approved');
  });
});

// ─────────────────────────────────────────────
//  Kick player
// ─────────────────────────────────────────────

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
    const slot = res.body.data.game.players.find((p) => p.user === p2Id || p.user?._id === p2Id);
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

// ─────────────────────────────────────────────
//  Cancel game
// ─────────────────────────────────────────────

describe('DELETE /games/:id (cancel)', () => {
  it('organizer can cancel their own game', async () => {
    const { token } = await registerAndLogin(1, 'organizer');
    const game = await createGameAs(token);
    const gameId = game.body.data.game._id;

    const res = await request(app)
      .delete(`${GAMES}/${gameId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ reason: 'Venue unavailable' });

    expect(res.status).toBe(200);
    expect(res.body.data.game.status).toBe('cancelled');
  });
});

// ─────────────────────────────────────────────
//  Complete game
// ─────────────────────────────────────────────

describe('PATCH /games/:id/complete', () => {
  it('marks game completed and increments player stats', async () => {
    const { token: orgToken, userId: orgId } = await registerAndLogin(1, 'organizer');
    const { token: p2Token } = await registerAndLogin(2);
    const User = require('../src/models/User.model');

    const game = await createGameAs(orgToken);
    const gameId = game.body.data.game._id;

    await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p2Token}`);

    const res = await request(app)
      .patch(`${GAMES}/${gameId}/complete`)
      .set('Authorization', `Bearer ${orgToken}`)
      .send({ score: '3-1', winnerDescription: 'Team A' });

    expect(res.status).toBe(200);
    expect(res.body.data.game.status).toBe('completed');

    const organizer = await User.findById(orgId);
    expect(organizer.stats.gamesPlayed).toBe(1);
  });
});

// ─────────────────────────────────────────────
//  Group merge
// ─────────────────────────────────────────────

describe('POST /games/:id/merge/:targetId', () => {
  it('merges two under-capacity games', async () => {
    const { token: org1Token } = await registerAndLogin(1, 'organizer');
    const { token: org2Token } = await registerAndLogin(2, 'organizer');

    // Source game (org1)
    const source = await createGameAs(org1Token, { maxPlayers: 5 });
    // Target game (org2)
    const target = await createGameAs(org2Token, { maxPlayers: 5, title: 'Target Game' });

    const res = await request(app)
      .post(`${GAMES}/${source.body.data.game._id}/merge/${target.body.data.game._id}`)
      .set('Authorization', `Bearer ${org1Token}`)
      .send({ expandCapacity: false });

    expect(res.status).toBe(200);
    expect(res.body.data.game._id).toBe(target.body.data.game._id);
    expect(res.body.data.game.isMerged).toBe(true);
  });

  it('rejects merge when combined players would exceed capacity', async () => {
    const { token: org1Token } = await registerAndLogin(1, 'organizer');
    const { token: org2Token } = await registerAndLogin(2, 'organizer');
    const { token: p3 } = await registerAndLogin(3);
    const { token: p4 } = await registerAndLogin(4);

    // Both games have maxPlayers=2, organizer already takes 1 slot each
    const source = await createGameAs(org1Token, { maxPlayers: 2 });
    const target = await createGameAs(org2Token, { maxPlayers: 2, title: 'Target' });

    // Fill source game
    await request(app).post(`${GAMES}/${source.body.data.game._id}/join`).set('Authorization', `Bearer ${p3}`);
    // Fill target game
    await request(app).post(`${GAMES}/${target.body.data.game._id}/join`).set('Authorization', `Bearer ${p4}`);

    const res = await request(app)
      .post(`${GAMES}/${source.body.data.game._id}/merge/${target.body.data.game._id}`)
      .set('Authorization', `Bearer ${org1Token}`)
      .send({ expandCapacity: false });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/capacity/i);
  });

  it('expands capacity and merges when expandCapacity is true', async () => {
    const { token: org1Token } = await registerAndLogin(1, 'organizer');
    const { token: org2Token } = await registerAndLogin(2, 'organizer');
    const { token: p3 } = await registerAndLogin(3);
    const { token: p4 } = await registerAndLogin(4);

    const source = await createGameAs(org1Token, { maxPlayers: 2 });
    const target = await createGameAs(org2Token, { maxPlayers: 2, title: 'Target' });

    await request(app).post(`${GAMES}/${source.body.data.game._id}/join`).set('Authorization', `Bearer ${p3}`);
    await request(app).post(`${GAMES}/${target.body.data.game._id}/join`).set('Authorization', `Bearer ${p4}`);

    const res = await request(app)
      .post(`${GAMES}/${source.body.data.game._id}/merge/${target.body.data.game._id}`)
      .set('Authorization', `Bearer ${org1Token}`)
      .send({ expandCapacity: true });

    expect(res.status).toBe(200);
    expect(res.body.data.game.maxPlayers).toBeGreaterThan(2);
  });
});
