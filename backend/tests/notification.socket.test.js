/**
 * Phase 3 — Real-time emission contract.
 *
 * Pins that `notificationInbox.service` emits `notification:new` to the
 * recipient's private socket room whenever a row is persisted, and that
 * the emit is a no-op when no io is wired (which is the case for every
 * other Jest suite in this repo — so existing tests stay green without
 * mocking the service).
 *
 * We don't spin up a real Socket.io server here: that would couple the
 * unit to a network layer and slow the suite. Instead we inject a tiny
 * spy that captures every `.to(room).emit(event, payload)` call, which
 * is the contract the frontend depends on.
 */

const testDb = require('./helpers/testDb');
const notificationInboxService = require('../src/services/notificationInbox.service');

beforeAll(testDb.connect);
afterEach(async () => {
  await testDb.clearAll();
  // Always reset the injected io between tests so a leaking spy from
  // one test can't poison another.
  notificationInboxService.setIo(null);
});
afterAll(testDb.disconnect);

/**
 * Builds a fake io server with the only two methods the inbox service
 * exercises: `.to(room)` returning a chainable object with `.emit()`.
 */
const buildIoSpy = () => {
  const emits = [];
  const io = {
    to(room) {
      return {
        emit(event, payload) {
          emits.push({ room: String(room), event, payload });
        },
      };
    },
  };
  return { io, emits };
};

describe('notificationInbox.service — socket emission', () => {
  it('emits `notification:new` to the recipient room after createForUser',
    async () => {
      const { io, emits } = buildIoSpy();
      notificationInboxService.setIo(io);

      const recipient = '6504a4c70d2af9ac353ed2a1'; // arbitrary ObjectId-shaped string
      const doc = await notificationInboxService.createForUser(recipient, {
        type: 'gameInvite',
        title: 'New Game Invite',
        body: 'You have been invited to a game.',
        data: { gameId: '6504a4c70d2af9ac353ed2b2' },
      });

      expect(emits).toHaveLength(1);
      expect(emits[0]).toMatchObject({
        room: recipient,
        event: 'notification:new',
      });
      // The payload shape must match what `GET /notifications` would
      // return so the frontend parser is identical for socket-pushed
      // and HTTP-fetched rows.
      expect(emits[0].payload).toMatchObject({
        _id: String(doc._id),
        type: 'gameInvite',
        title: 'New Game Invite',
        body: 'You have been invited to a game.',
        read: false,
        data: { gameId: '6504a4c70d2af9ac353ed2b2' },
      });
      expect(emits[0].payload.createdAt).toBeDefined();
    });

  it('fans out one `notification:new` per recipient after createForManyUsers',
    async () => {
      const { io, emits } = buildIoSpy();
      notificationInboxService.setIo(io);

      const recipients = [
        '6504a4c70d2af9ac353ed2c1',
        '6504a4c70d2af9ac353ed2c2',
        '6504a4c70d2af9ac353ed2c3',
      ];

      await notificationInboxService.createForManyUsers(recipients, {
        type: 'gameCompleted',
        title: 'Game Completed',
        body: 'Tap to rate the players.',
        data: { gameId: '6504a4c70d2af9ac353ed2d1' },
      });

      expect(emits).toHaveLength(3);
      // Order isn't guaranteed by `insertMany({ ordered: false })`,
      // so assert on the set of rooms not the sequence.
      const rooms = new Set(emits.map((e) => e.room));
      expect(rooms).toEqual(new Set(recipients));
      for (const e of emits) {
        expect(e.event).toBe('notification:new');
        expect(e.payload).toMatchObject({
          type: 'gameCompleted',
          title: 'Game Completed',
        });
      }
    });

  it('silently no-ops when no io has been wired',
    async () => {
      // No setIo() call here — this mirrors how Jest boots without a
      // network server. The DB write must still succeed.
      notificationInboxService.setIo(null);

      const recipient = '6504a4c70d2af9ac353ed2e1';
      const doc = await notificationInboxService.createForUser(recipient, {
        type: 'system',
        title: 'Server reset',
      });

      expect(doc).toBeDefined();
      expect(doc.recipient.toString()).toBe(recipient);
    });

  it('does not let a faulty io throw out of createForUser',
    async () => {
      // Producer code (game.service) already wraps notify() in its
      // own try/catch — but we still want the inbox service itself
      // to be resilient so a misconfigured socket layer can never
      // roll back the game flow that triggered the write.
      const explosiveIo = {
        to() {
          throw new Error('socket layer dead');
        },
      };
      notificationInboxService.setIo(explosiveIo);

      const recipient = '6504a4c70d2af9ac353ed2f1';
      await expect(
        notificationInboxService.createForUser(recipient, {
          type: 'system',
          title: 'still persists',
        }),
      ).resolves.toBeDefined();
    });
});
