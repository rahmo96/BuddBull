/**
 * BuddBull — Notification Service
 *
 * Handles two channels:
 *   1. FCM Push Notifications  (requires FIREBASE_PROJECT_ID / FIREBASE_CLIENT_EMAIL / FIREBASE_PRIVATE_KEY)
 *   2. Transactional Emails    (uses the existing email utility)
 *
 * All methods fail silently with a logged warning when credentials are not
 * configured, so the app runs fine without Firebase in development.
 */

const logger = require('../utils/logger');
const User = require('../models/User.model');

// ── Firebase initialisation (lazy, guarded) ───────────────────────────────────
let _fcmApp = null;

const getFCMApp = () => {
  if (_fcmApp) return _fcmApp;

  const { FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY } = process.env;
  if (!FIREBASE_PROJECT_ID || !FIREBASE_CLIENT_EMAIL || !FIREBASE_PRIVATE_KEY) {
    return null;
  }

  try {
    const admin = require('firebase-admin');
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: FIREBASE_PROJECT_ID,
          clientEmail: FIREBASE_CLIENT_EMAIL,
          // Newlines are escaped in env vars
          privateKey: FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
    }
    _fcmApp = admin.messaging();
    logger.info('[Notifications] Firebase Admin initialised ✓');
    return _fcmApp;
  } catch (err) {
    logger.warn(`[Notifications] Firebase init failed: ${err.message}`);
    return null;
  }
};

const stringifyData = (data = {}) =>
  Object.fromEntries(
    Object.entries(data).map(([k, v]) => [k, v === null || v === undefined ? '' : String(v)]),
  );

// ── Push notification primitives ──────────────────────────────────────────────
/**
 * Send a push notification to a single FCM device token.
 */
const sendPush = async (fcmToken, { title, body, data = {} }) => {
  const messaging = getFCMApp();
  if (!messaging || !fcmToken) return;

  try {
    await messaging.send({
      token: fcmToken,
      notification: { title, body },
      data: stringifyData(data),
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
  } catch (err) {
    logger.warn(`[Notifications] sendPush failed: ${err.message}`);
  }
};

/**
 * Send to a list of FCM tokens (batch, chunked to 500).
 */
const sendPushToMany = async (fcmTokens, payload) => {
  const messaging = getFCMApp();
  if (!messaging || !fcmTokens?.length) return;

  const valid = fcmTokens.filter(Boolean);
  const CHUNK = 500;

  for (let i = 0; i < valid.length; i += CHUNK) {
    const chunk = valid.slice(i, i + CHUNK);
    try {
      await messaging.sendEachForMulticast({
        tokens: chunk,
        notification: { title: payload.title, body: payload.body },
        data: payload.data ? stringifyData(payload.data) : {},
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
    } catch (err) {
      logger.warn(`[Notifications] sendPushToMany chunk failed: ${err.message}`);
    }
  }
};

/**
 * Loads the user's registered device tokens and sends one FCM multicast per
 * chunk (FCM max 500 tokens per call).
 */
const sendPushToUser = async (userId, { title, body, data = {} }) => {
  const messaging = getFCMApp();
  if (!messaging || !userId) return;

  const user = await User.findById(userId).select('+pushTokens').lean();
  if (!user?.pushTokens?.length) return;

  const tokens = [...new Set(user.pushTokens.map((p) => p.token).filter(Boolean))];
  if (!tokens.length) return;

  const strData = stringifyData(data);
  const CHUNK = 500;

  for (let i = 0; i < tokens.length; i += CHUNK) {
    const chunk = tokens.slice(i, i + CHUNK);
    try {
      await messaging.sendEachForMulticast({
        tokens: chunk,
        notification: { title, body },
        data: strData,
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
    } catch (err) {
      logger.warn(`[Notifications] sendPushToUser chunk failed: ${err.message}`);
    }
  }
};

const userIdOf = (user) => (user && user._id ? user._id : user);

// ── Email wrapper (re-exports with fallback) ──────────────────────────────────
const sendEmailNotification = async (to, { title, body, firstName = 'there' }) => {
  logger.warn('[Notifications] Email channel disabled (email utility removed).');
};

// ── Domain-specific trigger helpers ──────────────────────────────────────────
/**
 * Notify a user that they've been invited to a game.
 */
const notifyGameInvite = async (user, game) => {
  const title = 'Game Invitation 🏆';
  const body = `You've been invited to play "${game.title}" (${game.sport}) on ${new Date(game.scheduledAt).toDateString()}.`;

  await Promise.allSettled([
    sendPushToUser(userIdOf(user), { title, body, data: { type: 'game_invite', gameId: String(game._id) } }),
    sendEmailNotification(user.email, { title, body, firstName: user.firstName }),
  ]);
};

/**
 * Notify a user that their join request was approved.
 */
const notifyJoinApproved = async (user, game) => {
  const title = 'Request Approved ✅';
  const body = `Your request to join "${game.title}" has been approved! Get ready for ${new Date(game.scheduledAt).toDateString()}.`;

  await sendPushToUser(userIdOf(user), { title, body, data: { type: 'join_approved', gameId: String(game._id) } });
};

/**
 * Notify a user that their game has been merged with another group.
 */
const notifyGroupMerge = async (users, sourceGame, targetGame) => {
  const title = 'Groups Merged 🤝';
  const body = `Your game "${sourceGame.title}" has been merged into "${targetGame.title}". See you on the field!`;

  const payload = { title, body, data: { type: 'group_merge', gameId: String(targetGame._id) } };

  await Promise.allSettled([
    ...users.map((u) => sendPushToUser(userIdOf(u), payload)),
    ...users.map((u) => sendEmailNotification(u.email, { title, body, firstName: u.firstName })),
  ]);
};

/**
 * Notify a user when they break a personal best.
 */
const notifyPersonalBest = async (user, { sport, metric, value }) => {
  const title = 'New Personal Best 🎉';
  const body = `You broke your ${sport} personal best for "${metric}"! New record: ${value}.`;

  await sendPushToUser(userIdOf(user), {
    title,
    body,
    data: { type: 'personal_best', sport },
  });
};

/**
 * Notify a user that an upcoming game starts within 1 hour.
 */
const notifyGameReminder = async (user, game) => {
  const title = 'Game Starting Soon ⏰';
  const body = `"${game.title}" starts in about 1 hour. Head to ${game.location?.neighbourhood || game.location?.city}.`;

  await sendPushToUser(userIdOf(user), {
    title,
    body,
    data: { type: 'game_reminder', gameId: String(game._id) },
  });
};

module.exports = {
  sendPush,
  sendPushToMany,
  sendPushToUser,
  sendEmail: sendEmailNotification,
  notifyGameInvite,
  notifyJoinApproved,
  notifyGroupMerge,
  notifyPersonalBest,
  notifyGameReminder,
};
