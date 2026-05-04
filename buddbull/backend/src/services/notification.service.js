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
const sendEmail = require('../utils/email');

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
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
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
        data: payload.data
          ? Object.fromEntries(Object.entries(payload.data).map(([k, v]) => [k, String(v)]))
          : {},
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
    } catch (err) {
      logger.warn(`[Notifications] sendPushToMany chunk failed: ${err.message}`);
    }
  }
};

// ── Email wrapper (re-exports with fallback) ──────────────────────────────────
const sendEmailNotification = async (to, { title, body, firstName = 'there' }) => {
  try {
    await sendEmail({
      to,
      subject: title,
      text: `Hi ${firstName},\n\n${body}\n\nThe BuddBull Team`,
      html: `
        <div style="font-family:sans-serif;max-width:560px;margin:auto">
          <h2 style="color:#3B82F6">${title}</h2>
          <p>Hi ${firstName},</p>
          <p>${body.replace(/\n/g, '<br>')}</p>
          <hr>
          <p style="color:#888;font-size:12px">BuddBull — Connect, Play, Track</p>
        </div>`,
    });
  } catch (err) {
    logger.warn(`[Notifications] Email to ${to} failed: ${err.message}`);
  }
};

// ── Domain-specific trigger helpers ──────────────────────────────────────────
/**
 * Notify a user that they've been invited to a game.
 */
const notifyGameInvite = async (user, game) => {
  const title = 'Game Invitation 🏆';
  const body = `You've been invited to play "${game.title}" (${game.sport}) on ${new Date(game.scheduledAt).toDateString()}.`;

  await Promise.allSettled([
    sendPush(user.fcmToken, { title, body, data: { type: 'game_invite', gameId: String(game._id) } }),
    sendEmailNotification(user.email, { title, body, firstName: user.firstName }),
  ]);
};

/**
 * Notify a user that their join request was approved.
 */
const notifyJoinApproved = async (user, game) => {
  const title = 'Request Approved ✅';
  const body = `Your request to join "${game.title}" has been approved! Get ready for ${new Date(game.scheduledAt).toDateString()}.`;

  await sendPush(user.fcmToken, { title, body, data: { type: 'join_approved', gameId: String(game._id) } });
};

/**
 * Notify a user that their game has been merged with another group.
 */
const notifyGroupMerge = async (users, sourceGame, targetGame) => {
  const title = 'Groups Merged 🤝';
  const body = `Your game "${sourceGame.title}" has been merged into "${targetGame.title}". See you on the field!`;

  const tokens = users.map((u) => u.fcmToken).filter(Boolean);
  await Promise.allSettled([
    sendPushToMany(tokens, { title, body, data: { type: 'group_merge', gameId: String(targetGame._id) } }),
    ...users.map((u) => sendEmailNotification(u.email, { title, body, firstName: u.firstName })),
  ]);
};

/**
 * Notify a user when they break a personal best.
 */
const notifyPersonalBest = async (user, { sport, metric, value }) => {
  const title = 'New Personal Best 🎉';
  const body = `You broke your ${sport} personal best for "${metric}"! New record: ${value}.`;

  await sendPush(user.fcmToken, {
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

  await sendPush(user.fcmToken, {
    title,
    body,
    data: { type: 'game_reminder', gameId: String(game._id) },
  });
};

module.exports = {
  sendPush,
  sendPushToMany,
  sendEmail: sendEmailNotification,
  notifyGameInvite,
  notifyJoinApproved,
  notifyGroupMerge,
  notifyPersonalBest,
  notifyGameReminder,
};
