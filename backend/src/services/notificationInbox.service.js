const Notification = require('../models/Notification.model');
const User = require('../models/User.model');
const AppError = require('../utils/AppError');
const logger = require('../utils/logger');
const notificationService = require('./notification.service');

// ─────────────────────────────────────────────
//  Notification Inbox Service
// ─────────────────────────────────────────────
//
// Persistence + live-broadcast layer for the in-app notification feed.
//
// We keep MongoDB writes as the source of truth and treat socket
// emission as a best-effort side channel: if the io server isn't
// wired in (e.g. inside Jest with no HTTP server) or the recipient
// has no live socket, the row is still safely persisted and will
// surface on the next pull-to-refresh.
//
// Socket access is injected from `server.js` via `setIo(io)` rather
// than `require`d here to avoid a circular dependency (server.js ─→
// socket.manager.js ─→ models ─→ notificationInbox.service.js).

const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 100;

/** Maps inbox notification types to User.notificationPreferences keys. */
const PREF_MAP = {
  gameInvite: 'gameInvites',
  gameReminder: 'gameReminders',
  gameCompleted: 'gameStarting',
  gameCancelled: 'gameCancelled',
  gameMerged: 'groupMerges',
  ratingReceived: 'ratingReceived',
  retentionReminder: 'retentionReminders',
  broadcast: 'broadcasts',
};

/**
 * Returns false when the user has opted out of this notification category.
 * Unknown types default to allowed (backward compatible).
 */
const _userAllowsNotification = async (userId, inboxType) => {
  const prefKey = PREF_MAP[inboxType];
  if (!prefKey) return true;

  const user = await User.findById(userId).select('notificationPreferences').lean();
  if (!user) return false;

  const prefs = user.notificationPreferences || {};
  return prefs[prefKey] !== false;
};

// ── Socket plumbing (DI) ─────────────────────────────────────────────────────

/** Socket.io server handle; null in test/process boots that skip wiring. */
let _io = null;

const setIo = (io) => {
  _io = io || null;
};

/**
 * Emits `notification:new` into a recipient's private socket room.
 * Each connected user joins a room named after their Mongo `_id` in
 * `socket.manager.js`, so a single `io.to(userId).emit(...)` reaches
 * every device they've opened the app on.
 */
const _emitNotificationNew = (recipientId, payload) => {
  if (!_io || !recipientId) return;
  try {
    _io.to(String(recipientId)).emit('notification:new', payload);
  } catch (err) {
    // Never let an emit failure roll back the DB write that succeeded.
    logger.warn(`[notification:socket] emit failed for ${recipientId}: ${err.message}`);
  }
};

/**
 * Maps persisted inbox `type` + `data` to a stable FCM `data.type` the Flutter
 * client uses for deep-link routing (see `PushNotificationService`).
 */
const _fcmNavTypeFromInbox = (type, data) => {
  if (data?.chatId) return 'new_message';
  switch (type) {
    case 'gameInvite':
      return 'game_invite';
    case 'gameJoinRequest':
      return 'join_request';
    case 'gameApproved':
      return 'join_approved';
    case 'friendRequest':
      return 'friend_request';
    case 'friendRequestAccepted':
      return 'friend_request_accepted';
    case 'gameReminder':
      return 'game_reminder';
    case 'gameCompleted':
      return 'game_completed';
    case 'retentionReminder':
      return 'retention_reminder';
    default:
      return 'inbox';
  }
};

const _plainInboxDoc = (doc) => (typeof doc.toObject === 'function' ? doc.toObject({ getters: false }) : doc);

const _fcmDataFromInboxDoc = (doc) => {
  const plain = _plainInboxDoc(doc);
  const { type, data = {} } = plain;
  const navType = _fcmNavTypeFromInbox(type, data);
  const out = {
    type: navType,
    inboxType: type,
    notificationId: String(plain._id),
  };
  for (const [k, v] of Object.entries(data)) {
    if (v !== undefined && v !== null && v !== '') out[k] = String(v);
  }
  return out;
};

const _sendFcmForInboxDoc = async (recipientId, doc) => {
  try {
    const plain = _plainInboxDoc(doc);
    await notificationService.sendPushToUser(recipientId, {
      title: plain.title,
      body: plain.body || '',
      data: _fcmDataFromInboxDoc(doc),
    });
  } catch (err) {
    logger.warn(`[notificationInbox:fcm] ${err.message}`);
  }
};

/**
 * Converts a Mongoose document to a plain JSON-safe shape that mirrors
 * what `GET /notifications` would return — the frontend parser is
 * identical for both code paths.
 */
const _toPayload = (doc) => {
  if (!doc) return null;
  const obj = typeof doc.toObject === 'function' ? doc.toObject({ getters: false }) : doc;
  return {
    _id: String(obj._id),
    recipient: obj.recipient ? String(obj.recipient) : undefined,
    type: obj.type,
    title: obj.title,
    body: obj.body ?? '',
    data: obj.data ?? {},
    read: !!obj.read,
    readAt: obj.readAt ?? null,
    createdAt: obj.createdAt,
    updatedAt: obj.updatedAt,
  };
};

/**
 * Fetches a page of notifications for a user, newest first.
 *
 * The result intentionally exposes a fresh `unreadCount` so a single
 * round trip from the client populates both the list view and the
 * badge — avoiding a follow-up `/unread` call on every refresh.
 */
const listForUser = async (userId, { page = 1, limit = DEFAULT_LIMIT } = {}) => {
  const pageNum = Math.max(1, Number(page) || 1);
  const pageSize = Math.min(MAX_LIMIT, Math.max(1, Number(limit) || DEFAULT_LIMIT));
  const skip = (pageNum - 1) * pageSize;

  const [notifications, total, unreadCount] = await Promise.all([
    Notification.find({ recipient: userId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(pageSize)
      .lean(),
    Notification.countDocuments({ recipient: userId }),
    Notification.unreadCountFor(userId),
  ]);

  return {
    notifications,
    pagination: {
      total,
      page: pageNum,
      limit: pageSize,
      pages: Math.max(1, Math.ceil(total / pageSize)),
    },
    unreadCount,
  };
};

/**
 * Flips a single notification to read.
 *
 * Scoped by `recipient` so a user can never mark someone else's
 * notification read (defence-in-depth alongside the auth middleware).
 */
const markAsRead = async (userId, notificationId) => {
  const updated = await Notification.findOneAndUpdate(
    { _id: notificationId, recipient: userId },
    { $set: { read: true, readAt: new Date() } },
    { new: true },
  ).lean();

  if (!updated) throw new AppError('Notification not found', 404);
  return updated;
};

/**
 * Marks every unread notification for the current user as read.
 * Returns the count of rows actually touched (so the client can show
 * a friendly "X notifications cleared" toast if desired).
 */
const markAllAsRead = async (userId) => {
  const res = await Notification.updateMany(
    { recipient: userId, read: false },
    { $set: { read: true, readAt: new Date() } },
  );
  return { matched: res.matchedCount ?? 0, modified: res.modifiedCount ?? 0 };
};

/**
 * Internal helper for upcoming phases (game.service triggers, admin
 * broadcast, rating events). Validates the type against the schema's
 * enum implicitly via Mongoose validators and writes the row.
 */
const createForUser = async (recipientId, { type, title, body = '', data = {} } = {}) => {
  if (!recipientId) throw new AppError('recipientId is required', 400);
  if (!title) throw new AppError('title is required', 400);

  const allowed = await _userAllowsNotification(recipientId, type);
  if (!allowed) return null;

  const doc = await Notification.create({ recipient: recipientId, type, title, body, data });
  _emitNotificationNew(recipientId, _toPayload(doc));
  await _sendFcmForInboxDoc(recipientId, doc);
  return doc;
};

/**
 * Batch variant of [createForUser]. Used when a single domain event
 * (e.g. a game completion) fans out to many participants. Emits one
 * `notification:new` per recipient so each user's badge and inbox
 * update independently.
 */
const createForManyUsers = async (recipientIds = [], payload) => {
  if (!Array.isArray(recipientIds) || recipientIds.length === 0) return [];

  const inboxType = payload?.type ?? 'system';
  const allowedChecks = await Promise.all(
    recipientIds.map(async (id) => ({
      id,
      allowed: await _userAllowsNotification(id, inboxType),
    })),
  );
  const allowedIds = allowedChecks.filter((c) => c.allowed).map((c) => c.id);
  if (allowedIds.length === 0) return [];

  const docs = allowedIds.map((id) => ({
    recipient: id,
    type: inboxType,
    title: payload?.title ?? '',
    body: payload?.body ?? '',
    data: payload?.data ?? {},
  }));
  const created = await Notification.insertMany(docs, { ordered: false });
  for (const doc of created) {
    _emitNotificationNew(doc.recipient, _toPayload(doc));
  }
  for (const doc of created) {
    await _sendFcmForInboxDoc(doc.recipient, doc);
  }
  return created;
};

module.exports = {
  setIo,
  listForUser,
  markAsRead,
  markAllAsRead,
  createForUser,
  createForManyUsers,
  PREF_MAP,
  userAllowsNotification: _userAllowsNotification,
};
