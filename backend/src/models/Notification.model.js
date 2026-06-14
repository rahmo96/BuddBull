const mongoose = require('mongoose');

// ─────────────────────────────────────────────
//  Notification Schema
// ─────────────────────────────────────────────
/**
 * Persistent per-user notification inbox.
 *
 * Phase 1 of the notification system: a durable record that survives
 * across sessions and powers the in-app inbox + unread badge. Push
 * delivery (FCM) and real-time fan-out (socket) are intentionally
 * out of scope here — they'll be layered on top in later phases.
 *
 * Design notes
 * ────────────
 *  - `type` is a free-form enum so new event categories can be added
 *    without a migration. Unknown values are accepted to keep the
 *    write path forgiving (the producer is trusted; the client renders
 *    'system' for anything it doesn't recognise).
 *  - `data` is a Mixed bag for navigation context (`gameId`, `chatId`,
 *    `userId`, etc.). Keep the keys flat — nested objects make the
 *    Flutter side noisier than it needs to be.
 *  - `read` is denormalised on the doc so the unread badge query is a
 *    cheap `countDocuments({ recipient, read: false })` against the
 *    `{ recipient, createdAt }` index without touching any auxiliary
 *    collection.
 */

const NOTIFICATION_TYPES = [
  'gameInvite',
  'gameApproved',
  'gameJoinRequest',
  'gameJoinRequestDenied',
  'gamePlayerJoined',
  'gamePlayerLeft',
  'gameKicked',
  'gameMerged',
  'gameReminder',
  'gameCancelled',
  'gameCompleted',
  'ratingPending',
  'ratingReceived',
  'newFollower',
  'friendRequest',
  'friendRequestAccepted',
  'broadcast',
  'retentionReminder',
  'system',
];

const notificationSchema = new mongoose.Schema(
  {
    recipient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Notification must belong to a recipient'],
      // Compound index declared below — do not duplicate inline.
    },
    type: {
      type: String,
      required: [true, 'Notification type is required'],
      enum: {
        values: NOTIFICATION_TYPES,
        message: '`{VALUE}` is not a supported notification type',
      },
      default: 'system',
    },
    title: {
      type: String,
      required: [true, 'Notification title is required'],
      trim: true,
      maxlength: [120, 'Title cannot exceed 120 characters'],
    },
    body: {
      type: String,
      trim: true,
      maxlength: [500, 'Body cannot exceed 500 characters'],
      default: '',
    },
    // Navigation / deep-link payload. Keep keys flat and JSON-safe.
    // Examples: { gameId, chatId, userId, ratingId }.
    data: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    read: {
      type: Boolean,
      default: false,
      index: true,
    },
    // Timestamp the user actually saw the notification. Null until then.
    readAt: { type: Date, default: null },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  },
);

// ─────────────────────────────────────────────
//  Indexes
// ─────────────────────────────────────────────

// Primary access pattern: "list this user's notifications, newest first".
// Also covers the unread-count query because `read` is filterable below
// the compound prefix.
notificationSchema.index({ recipient: 1, createdAt: -1 });

// Hot path for the badge counter: count unread by recipient.
notificationSchema.index({ recipient: 1, read: 1 });

// ─────────────────────────────────────────────
//  Statics
// ─────────────────────────────────────────────

/**
 * Number of unread notifications for a user. Powers the bell badge.
 */
notificationSchema.statics.unreadCountFor = function (recipientId) {
  return this.countDocuments({ recipient: recipientId, read: false });
};

notificationSchema.statics.TYPES = NOTIFICATION_TYPES;

module.exports =
  mongoose.models.Notification ||
  mongoose.model('Notification', notificationSchema);
