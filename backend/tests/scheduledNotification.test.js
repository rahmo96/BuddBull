/**
 * Scheduled notification service — pre-game reminders + retention sweep.
 */

const testDb = require('./helpers/testDb');
const Game = require('../src/models/Game.model');
const User = require('../src/models/User.model');
const Notification = require('../src/models/Notification.model');
const scheduledNotificationService = require('../src/services/scheduledNotification.service');
const notificationInboxService = require('../src/services/notificationInbox.service');

beforeAll(testDb.connect);
afterEach(testDb.clearAll);
afterAll(testDb.disconnect);

const mkOrganizer = async (overrides = {}) => {
  const user = await User.create({
    firstName: 'Org',
    lastName: 'Test',
    username: `org_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`,
    email: `org_${Date.now()}@test.com`,
    firebaseUid: `fb_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
    role: 'organizer',
    ...overrides,
  });
  return user;
};

const mkPlayer = async (overrides = {}) => {
  const user = await User.create({
    firstName: 'Player',
    lastName: 'Test',
    username: `pl_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`,
    email: `pl_${Date.now()}@test.com`,
    firebaseUid: `fb_pl_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
    ...overrides,
  });
  return user;
};

const mkGame = async (organizer, overrides = {}) => {
  const scheduledAt = overrides.scheduledAt || new Date(Date.now() + 3 * 60 * 60 * 1000);
  return Game.create({
    title: 'Test Game',
    sport: 'football',
    organizer: organizer._id,
    scheduledAt,
    durationMinutes: 90,
    location: {
      neighborhood: 'Downtown',
      city: 'London',
      country: 'GB',
      coordinates: { type: 'Point', coordinates: [-0.1955, 51.5099] },
    },
    maxPlayers: 10,
    players: [{ user: organizer._id, status: 'approved', role: 'co-organizer' }],
    status: 'open',
    ...overrides,
  });
};

describe('scheduledNotificationService.computeReminderRunAt', () => {
  it('returns scheduledAt minus 1 hour by default', () => {
    const scheduledAt = new Date('2026-06-14T15:00:00.000Z');
    const runAt = scheduledNotificationService.computeReminderRunAt(scheduledAt);
    expect(runAt.toISOString()).toBe('2026-06-14T14:00:00.000Z');
  });
});

describe('scheduledNotificationService.sendPreGameReminder', () => {
  it('sends gameReminder inbox rows to approved players', async () => {
    const org = await mkOrganizer();
    const player = await mkPlayer();
    const game = await mkGame(org, {
      players: [
        { user: org._id, status: 'approved', role: 'co-organizer' },
        { user: player._id, status: 'approved' },
      ],
    });

    await scheduledNotificationService.sendPreGameReminder(String(game._id));

    const rows = await Notification.find({ type: 'gameReminder' }).lean();
    expect(rows).toHaveLength(2);
    expect(rows.map((r) => String(r.recipient)).sort()).toEqual(
      [String(org._id), String(player._id)].sort(),
    );

    const updated = await Game.findById(game._id).lean();
    expect(updated.preGameReminderSentAt).toBeTruthy();
  });

  it('is idempotent — skips when preGameReminderSentAt is already set', async () => {
    const org = await mkOrganizer();
    const game = await mkGame(org, { preGameReminderSentAt: new Date() });

    await scheduledNotificationService.sendPreGameReminder(String(game._id));

    const rows = await Notification.find({ type: 'gameReminder' }).lean();
    expect(rows).toHaveLength(0);
  });

  it('skips terminal game statuses', async () => {
    const org = await mkOrganizer();
    const game = await mkGame(org, { status: 'cancelled' });

    await scheduledNotificationService.sendPreGameReminder(String(game._id));

    const rows = await Notification.find({ type: 'gameReminder' }).lean();
    expect(rows).toHaveLength(0);
  });
});

describe('scheduledNotificationService.schedulePreGameReminder', () => {
  it('skips scheduling when reminder window already passed and game not started', async () => {
    const org = await mkOrganizer();
    const game = await mkGame(org, {
      scheduledAt: new Date(Date.now() + 30 * 60 * 1000), // 30 min from now
    });

    const mockAgenda = {
      cancel: jest.fn().mockResolvedValue(0),
      create: jest.fn(),
      define: jest.fn(),
    };
    await scheduledNotificationService.initScheduledNotifications(mockAgenda);
    await scheduledNotificationService.schedulePreGameReminder(game);

    expect(mockAgenda.create).not.toHaveBeenCalled();
  });

  it('schedules Agenda job when game starts more than 1 hour away', async () => {
    const org = await mkOrganizer();
    const scheduledAt = new Date(Date.now() + 3 * 60 * 60 * 1000);
    const game = await mkGame(org, { scheduledAt });

    const save = jest.fn().mockResolvedValue(undefined);
    const schedule = jest.fn().mockReturnThis();
    const unique = jest.fn().mockReturnThis();
    const mockJob = { unique, schedule, save };
    const mockAgenda = {
      cancel: jest.fn().mockResolvedValue(0),
      create: jest.fn().mockReturnValue(mockJob),
      define: jest.fn(),
    };

    await scheduledNotificationService.initScheduledNotifications(mockAgenda);
    await scheduledNotificationService.schedulePreGameReminder(game);

    expect(mockAgenda.cancel).toHaveBeenCalled();
    expect(mockAgenda.create).toHaveBeenCalledWith('send-pre-game-reminder', {
      gameId: String(game._id),
    });
    expect(schedule).toHaveBeenCalled();
    expect(save).toHaveBeenCalled();
  });
});

describe('scheduledNotificationService.runRetentionSweep', () => {
  it('notifies users who have not logged in today (UTC)', async () => {
    const yesterday = new Date();
    yesterday.setUTCDate(yesterday.getUTCDate() - 1);

    const inactive = await mkPlayer({
      username: 'inactive_user',
      email: 'inactive@test.com',
      firebaseUid: 'fb_inactive',
      lastLoginAt: yesterday,
      pushTokens: [{ token: 'tok_inactive', platform: 'android' }],
    });

    const activeToday = await mkPlayer({
      username: 'active_user',
      email: 'active@test.com',
      firebaseUid: 'fb_active',
      lastLoginAt: new Date(),
      pushTokens: [{ token: 'tok_active', platform: 'android' }],
    });

    const summary = await scheduledNotificationService.runRetentionSweep();

    expect(summary.sent).toBe(1);

    const inactiveRows = await Notification.find({
      recipient: inactive._id,
      type: 'retentionReminder',
    });
    expect(inactiveRows).toHaveLength(1);

    const activeRows = await Notification.find({
      recipient: activeToday._id,
      type: 'retentionReminder',
    });
    expect(activeRows).toHaveLength(0);

    const refreshed = await User.findById(inactive._id).lean();
    expect(refreshed.lastRetentionNotifiedAt).toBeTruthy();
  });

  it('respects retentionReminders: false preference', async () => {
    const yesterday = new Date();
    yesterday.setUTCDate(yesterday.getUTCDate() - 1);

    await mkPlayer({
      username: 'optout_user',
      email: 'optout@test.com',
      firebaseUid: 'fb_optout',
      lastLoginAt: yesterday,
      pushTokens: [{ token: 'tok_optout', platform: 'android' }],
      notificationPreferences: { retentionReminders: false },
    });

    const summary = await scheduledNotificationService.runRetentionSweep();
    expect(summary.skipped).toBeGreaterThanOrEqual(1);

    const rows = await Notification.find({ type: 'retentionReminder' }).lean();
    expect(rows).toHaveLength(0);
  });
});

describe('notificationInboxService preference gating', () => {
  it('blocks gameReminder when gameReminders is false', async () => {
    const user = await mkPlayer({
      username: 'noreminder',
      email: 'noreminder@test.com',
      firebaseUid: 'fb_noreminder',
      notificationPreferences: { gameReminders: false },
    });

    const doc = await notificationInboxService.createForUser(user._id, {
      type: 'gameReminder',
      title: 'Test',
      body: 'Body',
      data: {},
    });

    expect(doc).toBeNull();
    const rows = await Notification.find({ recipient: user._id }).lean();
    expect(rows).toHaveLength(0);
  });
});
