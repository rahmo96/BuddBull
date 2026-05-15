/**
 * BuddBull — Notification Service
 *
 * FCM push (via User.pushTokens[]) + transactional email stubs.
 * All Android payloads use channel `buddbull_default` (Importance.max on client).
 */

const User = require('../models/User.model');
const logger = require('../utils/logger');

/** Must match Flutter `kBuddbullAndroidNotificationChannelId`. */
const ANDROID_FCM_CHANNEL_ID = 'buddbull_default';

const STALE_FCM_ERROR_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

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

const _stringifyData = (data = {}) =>
  Object.fromEntries(
    Object.entries(data)
      .filter(([, v]) => v !== undefined && v !== null && v !== '')
      .map(([k, v]) => [k, String(v)]),
  );

/** Shared Android heads-up config for every outbound FCM message. */
const _androidFcmConfig = () => ({
  priority: 'high',
  notification: {
    channelId: ANDROID_FCM_CHANNEL_ID,
    priority: 'max',
  },
});

const _apnsFcmConfig = () => ({
  payload: { aps: { sound: 'default' } },
});

const _buildFcmMessage = (token, { title, body, data = {} }) => ({
  token,
  notification: { title, body },
  data: _stringifyData(data),
  android: _androidFcmConfig(),
  apns: _apnsFcmConfig(),
});

const _buildMulticastMessage = ({ title, body, data = {} }) => ({
  notification: { title, body },
  data: _stringifyData(data),
  android: _androidFcmConfig(),
  apns: _apnsFcmConfig(),
});

const _resolveUserId = (userOrId) => {
  if (!userOrId) return null;
  if (typeof userOrId === 'string') return userOrId;
  if (userOrId._id) return String(userOrId._id);
  if (userOrId.id) return String(userOrId.id);
  return String(userOrId);
};

const _collectPushTokensForUser = async (userId) => {
  const user = await User.findById(userId).select('+pushTokens').lean();
  if (!user?.pushTokens?.length) return [];

  const seen = new Set();
  const tokens = [];
  for (const entry of user.pushTokens) {
    const t = entry?.token;
    if (t && !seen.has(t)) {
      seen.add(t);
      tokens.push(t);
    }
  }
  return tokens;
};

const _pruneStaleToken = async (userId, token) => {
  try {
    await User.updateOne({ _id: userId }, { $pull: { pushTokens: { token } } });
  } catch (err) {
    logger.warn(`[Notifications] prune token failed for ${userId}: ${err.message}`);
  }
};

const _handleSendEachResults = async (userId, tokens, response) => {
  if (!response?.responses?.length) return { sent: 0, failed: 0 };

  let sent = 0;
  let failed = 0;

  for (let i = 0; i < response.responses.length; i += 1) {
    const r = response.responses[i];
    if (r.success) {
      sent += 1;
    } else {
      failed += 1;
      const code = r.error?.code;
      if (code && STALE_FCM_ERROR_CODES.has(code) && tokens[i]) {
        await _pruneStaleToken(userId, tokens[i]);
      }
      logger.warn(`[Notifications] FCM send failed (${code}): ${r.error?.message}`);
    }
  }

  return { sent, failed };
};

// ── Push notification primitives ──────────────────────────────────────────────

/**
 * Send a push notification to a single FCM device token.
 */
const sendPush = async (fcmToken, { title, body, data = {} }) => {
  const messaging = getFCMApp();
  if (!messaging || !fcmToken) return;

  try {
    await messaging.send(_buildFcmMessage(fcmToken, { title, body, data }));
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

  const valid = [...new Set(fcmTokens.filter(Boolean))];
  const CHUNK = 500;
  const message = _buildMulticastMessage(payload);

  for (let i = 0; i < valid.length; i += CHUNK) {
    const chunk = valid.slice(i, i + CHUNK);
    try {
      await messaging.sendEachForMulticast({
        ...message,
        tokens: chunk,
      });
    } catch (err) {
      logger.warn(`[Notifications] sendPushToMany chunk failed: ${err.message}`);
    }
  }
};

/**
 * Sends a push to every device token registered on the user (`pushTokens[]`).
 */
const sendPushToUser = async (userOrId, { title, body, data = {} }) => {
  const userId = _resolveUserId(userOrId);
  if (!userId || !title) return { sent: 0, failed: 0 };

  const tokens = await _collectPushTokensForUser(userId);
  if (!tokens.length) return { sent: 0, failed: 0 };

  const messaging = getFCMApp();
  if (!messaging) return { sent: 0, failed: 0 };

  try {
    const response = await messaging.sendEach(
      tokens.map((token) => _buildFcmMessage(token, { title, body, data })),
    );
    return _handleSendEachResults(userId, tokens, response);
  } catch (err) {
    logger.warn(`[Notifications] sendPushToUser failed for ${userId}: ${err.message}`);
    return { sent: 0, failed: tokens.length };
  }
};

/**
 * FCM push for new chat messages (socket + HTTP send paths).
 */
const notifyChatMessage = async ({
  chatId,
  senderId,
  senderName,
  preview,
  recipientIds = [],
  gameId,
}) => {
  if (!chatId || !senderId) return;

  const title = (senderName || 'New message').trim() || 'New message';
  const body = String(preview || 'You have a new message').slice(0, 120);
  const data = {
    type: 'new_message',
    chatId: String(chatId),
    senderId: String(senderId),
    ...(gameId ? { gameId: String(gameId) } : {}),
  };

  const recipients = [...new Set(recipientIds.map(String))].filter(
    (id) => id && id !== String(senderId),
  );

  await Promise.allSettled(
    recipients.map((recipientId) => sendPushToUser(recipientId, { title, body, data })),
  );
};

// ── Email wrapper (re-exports with fallback) ──────────────────────────────────
const sendEmailNotification = async (to, { title, body, firstName = 'there' }) => {
  logger.warn('[Notifications] Email channel disabled (email utility removed).');
};

// ── Domain-specific trigger helpers (legacy — use sendPushToUser + pushTokens) ─
const notifyGameInvite = async (user, game) => {
  const userId = _resolveUserId(user);
  const title = 'Game Invitation 🏆';
  const body = `You've been invited to play "${game.title}" (${game.sport}) on ${new Date(game.scheduledAt).toDateString()}.`;

  await Promise.allSettled([
    sendPushToUser(userId, {
      title,
      body,
      data: { type: 'game_invite', gameId: String(game._id) },
    }),
    sendEmailNotification(user?.email, { title, body, firstName: user?.firstName }),
  ]);
};

const notifyJoinApproved = async (user, game) => {
  const userId = _resolveUserId(user);
  const title = 'Request Approved ✅';
  const body = `Your request to join "${game.title}" has been approved! Get ready for ${new Date(game.scheduledAt).toDateString()}.`;

  await sendPushToUser(userId, {
    title,
    body,
    data: { type: 'join_approved', gameId: String(game._id) },
  });
};

const notifyGroupMerge = async (users, sourceGame, targetGame) => {
  const title = 'Groups Merged 🤝';
  const body = `Your game "${sourceGame.title}" has been merged into "${targetGame.title}". See you on the field!`;
  const data = { type: 'group_merge', gameId: String(targetGame._id) };

  await Promise.allSettled([
    ...users.map((u) => sendPushToUser(_resolveUserId(u), { title, body, data })),
    ...users.map((u) => sendEmailNotification(u.email, { title, body, firstName: u.firstName })),
  ]);
};

const notifyPersonalBest = async (user, { sport, metric, value }) => {
  const userId = _resolveUserId(user);
  const title = 'New Personal Best 🎉';
  const body = `You broke your ${sport} personal best for "${metric}"! New record: ${value}.`;

  await sendPushToUser(userId, {
    title,
    body,
    data: { type: 'personal_best', sport },
  });
};

const notifyGameReminder = async (user, game) => {
  const userId = _resolveUserId(user);
  const title = 'Game Starting Soon ⏰';
  const body = `"${game.title}" starts in about 1 hour. Head to ${game.location?.neighbourhood || game.location?.city}.`;

  await sendPushToUser(userId, {
    title,
    body,
    data: { type: 'game_reminder', gameId: String(game._id) },
  });
};

module.exports = {
  ANDROID_FCM_CHANNEL_ID,
  sendPush,
  sendPushToMany,
  sendPushToUser,
  notifyChatMessage,
  sendEmail: sendEmailNotification,
  notifyGameInvite,
  notifyJoinApproved,
  notifyGroupMerge,
  notifyPersonalBest,
  notifyGameReminder,
};
