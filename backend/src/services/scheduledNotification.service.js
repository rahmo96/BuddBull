/**
 * BuddBull — Scheduled Notification Service
 *
 * Handles:
 *  - Pre-game reminders (Agenda one-off jobs at scheduledAt - 1h)
 *  - Daily retention "We miss you" sweep (called from node-cron)
 */

const Game = require('../models/Game.model');
const User = require('../models/User.model');
const logger = require('../utils/logger');
const { JOB_SEND_PRE_GAME_REMINDER } = require('../config/agenda');
const notificationInboxService = require('./notificationInbox.service');

/** Default: 1 hour before kick-off. Override via PRE_GAME_REMINDER_MS env. */
const PRE_GAME_REMINDER_MS = Number(process.env.PRE_GAME_REMINDER_MS) || 60 * 60 * 1000;

const ACTIVE_GAME_STATUSES = ['open', 'full', 'in_progress'];

const _jobNameForGame = (gameId) => `pre-game-reminder:${gameId}`;

let _agenda = null;

/**
 * Registers the Agenda job handler. Call once after initAgenda().
 *
 * @param {import('agenda').Agenda} agenda
 */
const initScheduledNotifications = async (agenda) => {
  _agenda = agenda;

  agenda.define(JOB_SEND_PRE_GAME_REMINDER, async (job) => {
    const gameId = job.attrs.data?.gameId;
    if (!gameId) {
      logger.warn('[scheduledNotification] pre-game job missing gameId');
      return;
    }
    await sendPreGameReminder(gameId);
  });

  logger.info('[scheduledNotification] Agenda job handlers registered ✓');
};

/**
 * Computes the reminder fire time (1h before scheduledAt).
 *
 * @param {Date} scheduledAt
 * @returns {Date}
 */
const computeReminderRunAt = (scheduledAt) => {
  const start = scheduledAt instanceof Date ? scheduledAt : new Date(scheduledAt);
  return new Date(start.getTime() - PRE_GAME_REMINDER_MS);
};

/**
 * Schedules (or reschedules) the pre-game reminder for a game.
 *
 * @param {import('../models/Game.model') | object} game — must include _id + scheduledAt
 */
const schedulePreGameReminder = async (game) => {
  if (!_agenda || !game?._id || !game.scheduledAt) return;

  const gameId = String(game._id);
  const runAt = computeReminderRunAt(game.scheduledAt);
  const now = Date.now();

  // Game already started or reminder window passed — nothing to schedule.
  if (runAt.getTime() <= now) {
    // If game hasn't started yet but we missed the window, send immediately.
    const scheduledAtMs = new Date(game.scheduledAt).getTime();
    if (scheduledAtMs > now && !game.preGameReminderSentAt) {
      await sendPreGameReminder(gameId);
    }
    return;
  }

  await cancelPreGameReminder(gameId);

  const job = _agenda.create(JOB_SEND_PRE_GAME_REMINDER, { gameId });
  job.unique({ 'data.gameId': gameId });
  job.schedule(runAt);
  await job.save();

  await Game.findByIdAndUpdate(gameId, {
    $set: { preGameReminderJobName: _jobNameForGame(gameId) },
  });

  logger.info(`[scheduledNotification] Pre-game reminder scheduled for game ${gameId} at ${runAt.toISOString()}`);
};

/**
 * Cancels a pending pre-game reminder Agenda job.
 *
 * @param {string} gameId
 */
const cancelPreGameReminder = async (gameId) => {
  if (!_agenda || !gameId) return;

  const cancelled = await _agenda.cancel({
    name: JOB_SEND_PRE_GAME_REMINDER,
    'data.gameId': String(gameId),
  });

  if (cancelled > 0) {
    logger.info(`[scheduledNotification] Cancelled ${cancelled} pre-game job(s) for game ${gameId}`);
  }

  await Game.findByIdAndUpdate(gameId, {
    $set: { preGameReminderJobName: null },
  });
};

/**
 * Sends the pre-game reminder to all approved participants.
 * Idempotent — skips if already sent or game is terminal.
 *
 * @param {string} gameId
 */
const sendPreGameReminder = async (gameId) => {
  const game = await Game.findById(gameId).where({ deletedAt: null });
  if (!game) {
    logger.warn(`[scheduledNotification] Pre-game reminder: game ${gameId} not found`);
    return;
  }

  if (!ACTIVE_GAME_STATUSES.includes(game.status)) {
    logger.debug(`[scheduledNotification] Pre-game reminder skipped — game ${gameId} status=${game.status}`);
    return;
  }

  if (game.preGameReminderSentAt) {
    logger.debug(`[scheduledNotification] Pre-game reminder already sent for game ${gameId}`);
    return;
  }

  const approvedPlayerIds = game.players
    .filter((p) => p.status === 'approved')
    .map((p) => p.user);

  if (approvedPlayerIds.length === 0) {
    logger.debug(`[scheduledNotification] Pre-game reminder: no approved players for game ${gameId}`);
    return;
  }

  const locationLabel =
    game.location?.neighborhood || game.location?.city || 'the venue';

  const payload = {
    type: 'gameReminder',
    title: 'Game Starting Soon ⏰',
    body: `"${game.title}" starts in about 1 hour. Head to ${locationLabel}.`,
    data: { gameId: String(game._id) },
  };

  await notificationInboxService.createForManyUsers(approvedPlayerIds, payload);

  game.preGameReminderSentAt = new Date();
  await game.save({ validateBeforeSave: false });

  logger.info(`[scheduledNotification] Pre-game reminder sent for game ${gameId} to ${approvedPlayerIds.length} player(s)`);
};

/**
 * On startup, schedule reminders for upcoming games and catch up on missed ones.
 */
const bootstrapUpcomingReminders = async () => {
  const now = Date.now();
  const reminderCutoff = new Date(now + PRE_GAME_REMINDER_MS);

  const games = await Game.find({
    deletedAt: null,
    status: { $in: ACTIVE_GAME_STATUSES },
    scheduledAt: { $gt: new Date(now) },
    preGameReminderSentAt: null,
  }).select('_id scheduledAt status preGameReminderSentAt preGameReminderJobName');

  let scheduled = 0;
  let sentImmediately = 0;

  for (const game of games) {
    const runAt = computeReminderRunAt(game.scheduledAt);

    if (runAt.getTime() <= now) {
      // Missed window while server was down — send now if game hasn't started.
      await sendPreGameReminder(String(game._id));
      sentImmediately += 1;
    } else if (game.scheduledAt > reminderCutoff) {
      await schedulePreGameReminder(game);
      scheduled += 1;
    } else {
      // Within the 1h window but not yet sent — send immediately.
      await sendPreGameReminder(String(game._id));
      sentImmediately += 1;
    }
  }

  logger.info(
    `[scheduledNotification] Bootstrap complete: ${scheduled} scheduled, ${sentImmediately} sent immediately`,
  );
};

/**
 * Returns UTC midnight for "today" (used by retention sweep).
 *
 * @returns {Date}
 */
const startOfTodayUtc = () => {
  const d = new Date();
  d.setUTCHours(0, 0, 0, 0);
  return d;
};

/**
 * Daily retention sweep: notify users who haven't opened the app today (UTC).
 */
const runRetentionSweep = async () => {
  const todayStart = startOfTodayUtc();
  const now = new Date();

  const candidates = await User.find({
    deletedAt: null,
    isActive: true,
    isBanned: false,
    $or: [{ lastLoginAt: { $lt: todayStart } }, { lastLoginAt: null }],
    $and: [
      {
        $or: [
          { lastRetentionNotifiedAt: null },
          { lastRetentionNotifiedAt: { $lt: todayStart } },
        ],
      },
    ],
  })
    .select('+pushTokens _id firstName notificationPreferences')
    .lean();

  let sent = 0;
  let skipped = 0;

  for (const user of candidates) {
    const prefs = user.notificationPreferences || {};
    if (prefs.retentionReminders === false) {
      skipped += 1;
      continue;
    }

    const hasTokens = Array.isArray(user.pushTokens) && user.pushTokens.some((t) => t?.token);
    if (!hasTokens) {
      skipped += 1;
      continue;
    }

    const firstName = user.firstName || 'there';

    try {
      await notificationInboxService.createForUser(user._id, {
        type: 'retentionReminder',
        title: 'We miss you! 👋',
        body: `Hey ${firstName}, your sports community is waiting. Jump back in and find your next game!`,
        data: {},
      });

      await User.findByIdAndUpdate(user._id, { $set: { lastRetentionNotifiedAt: now } });
      sent += 1;
    } catch (err) {
      logger.warn(`[scheduledNotification] Retention notify failed for ${user._id}: ${err.message}`);
    }
  }

  logger.info(`[scheduledNotification] Retention sweep: ${sent} sent, ${skipped} skipped (${candidates.length} candidates)`);
  return { sent, skipped, candidates: candidates.length };
};

module.exports = {
  PRE_GAME_REMINDER_MS,
  computeReminderRunAt,
  initScheduledNotifications,
  schedulePreGameReminder,
  cancelPreGameReminder,
  sendPreGameReminder,
  bootstrapUpcomingReminders,
  runRetentionSweep,
  startOfTodayUtc,
};
