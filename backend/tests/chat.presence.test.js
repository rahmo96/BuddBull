/**
 * Chat presence — kick / leave side effects
 *
 * Verifies the contract our frontend chat security depends on:
 *
 *   1. When a player leaves their game, the chat participant slot is
 *      marked inactive (`leftAt` set) and a `chat:left` event is sent
 *      to that user's private socket room.
 *   2. When the organiser kicks a player, the slot is closed and a
 *      `chat:kicked` event is fired with any provided reason.
 *   3. Re-joining after leaving re-activates the same chat slot
 *      (`leftAt` cleared) instead of pushing a duplicate participant.
 *
 * We swap in a tiny io-spy via `chatPresenceService.setIo(...)` so we
 * don't need a real Socket.io server for the unit.
 */

const request = require('supertest');
const testDb = require('./helpers/testDb');
const createApp = require('../src/app');
const Chat = require('../src/models/Chat.model');
const chatPresenceService = require('../src/services/chatPresence.service');
const { syncFirebaseUser } = require('./helpers/authTestFactory');

const app = createApp();

beforeAll(testDb.connect);
afterEach(async () => {
  await testDb.clearAll();
  chatPresenceService.setIo(null);
});
afterAll(testDb.disconnect);

const GAMES = '/api/v1/games';

const registerAndLogin = async (slot, role = 'player') => {
  const r = await syncFirebaseUser(app, {
    role,
    firstName: `User${slot}`,
    lastName: 'Test',
  });
  expect(r.status).toBe(200);
  return { token: r.token, userId: r.userId };
};

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

const createGameAs = async (token, overrides = {}) =>
  request(app).post(GAMES).set('Authorization', `Bearer ${token}`).send(mkGame(overrides));

/**
 * Builds a fake io: captures every `.to(room).emit(event, payload)`
 * and lets a test "wire up" a socket with `connectSocket(id, [rooms])`
 * so the force-leave path has something to grab.
 */
const buildIoSpy = () => {
  const emits = [];
  const leaves = [];
  const sockets = new Map();
  const rooms = new Map();

  const ensureSocket = (socketId) => {
    if (!sockets.has(socketId)) {
      sockets.set(socketId, {
        id: socketId,
        leave(room) {
          leaves.push({ socketId, room });
          const set = rooms.get(room);
          if (set) set.delete(socketId);
        },
      });
    }
    return sockets.get(socketId);
  };

  const io = {
    sockets: {
      adapter: { rooms },
      sockets,
    },
    to(room) {
      return {
        emit(event, payload) {
          emits.push({ room: String(room), event, payload });
        },
      };
    },
  };

  const connectSocket = (socketId, joinedRooms) => {
    ensureSocket(socketId);
    for (const room of joinedRooms) {
      if (!rooms.has(room)) rooms.set(room, new Set());
      rooms.get(room).add(socketId);
    }
  };

  return { io, emits, leaves, connectSocket };
};

describe('chat presence — leave/kick side effects', () => {
  it('leaveGame closes the chat slot, emits chat:left, and force-leaves the room',
    async () => {
      const spy = buildIoSpy();
      chatPresenceService.setIo(spy.io);

      const { token: orgToken } = await registerAndLogin(1, 'organizer');
      const { token: p2Token, userId: p2Id } = await registerAndLogin(2);

      const game = await createGameAs(orgToken);
      const gameId = game.body.data.game._id;

      await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p2Token}`);

      const chat = await Chat.findOne({ game: gameId });
      expect(chat).toBeTruthy();
      const chatId = String(chat._id);

      spy.connectSocket('sock-p2', [String(p2Id), chatId]);

      const leaveRes = await request(app)
        .delete(`${GAMES}/${gameId}/leave`)
        .set('Authorization', `Bearer ${p2Token}`);
      expect(leaveRes.status).toBe(200);

      const updated = await Chat.findById(chatId).lean();
      const slot = updated.participants.find((p) => String(p.user) === String(p2Id));
      expect(slot).toBeTruthy();
      expect(slot.leftAt).toBeTruthy();

      const emitted = spy.emits.find((e) => e.event === 'chat:left' && e.room === String(p2Id));
      expect(emitted).toBeTruthy();
      expect(emitted.payload.chatId).toBe(chatId);
      expect(emitted.payload.gameId).toBe(String(gameId));

      expect(spy.leaves).toContainEqual({ socketId: 'sock-p2', room: chatId });
    });

  it('kickPlayer closes the chat slot and emits chat:kicked with the reason',
    async () => {
      const spy = buildIoSpy();
      chatPresenceService.setIo(spy.io);

      const { token: orgToken } = await registerAndLogin(1, 'organizer');
      const { token: p2Token, userId: p2Id } = await registerAndLogin(2);

      const game = await createGameAs(orgToken);
      const gameId = game.body.data.game._id;

      await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p2Token}`);

      const chat = await Chat.findOne({ game: gameId });
      const chatId = String(chat._id);
      spy.connectSocket('sock-p2', [String(p2Id), chatId]);

      const kickRes = await request(app)
        .delete(`${GAMES}/${gameId}/players/${p2Id}`)
        .set('Authorization', `Bearer ${orgToken}`)
        .send({ reason: 'no-show' });
      expect(kickRes.status).toBe(200);

      const updated = await Chat.findById(chatId).lean();
      const slot = updated.participants.find((p) => String(p.user) === String(p2Id));
      expect(slot.leftAt).toBeTruthy();

      const emitted = spy.emits.find((e) => e.event === 'chat:kicked' && e.room === String(p2Id));
      expect(emitted).toBeTruthy();
      expect(emitted.payload.chatId).toBe(chatId);
      expect(emitted.payload.detail).toBe('no-show');

      expect(spy.leaves).toContainEqual({ socketId: 'sock-p2', room: chatId });
    });

  it('re-joining after leave re-opens the chat slot (leftAt cleared, no duplicate)',
    async () => {
      const spy = buildIoSpy();
      chatPresenceService.setIo(spy.io);

      const { token: orgToken } = await registerAndLogin(1, 'organizer');
      const { token: p2Token, userId: p2Id } = await registerAndLogin(2);

      const game = await createGameAs(orgToken);
      const gameId = game.body.data.game._id;

      await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p2Token}`);
      await request(app).delete(`${GAMES}/${gameId}/leave`).set('Authorization', `Bearer ${p2Token}`);
      await request(app).post(`${GAMES}/${gameId}/join`).set('Authorization', `Bearer ${p2Token}`);

      const chat = await Chat.findOne({ game: gameId }).lean();
      const slots = chat.participants.filter((p) => String(p.user) === String(p2Id));
      expect(slots).toHaveLength(1);
      expect(slots[0].leftAt).toBeNull();
    });
});
