const mongoose = require('mongoose');

// ─────────────────────────────────────────────
//  Sub-schemas
// ─────────────────────────────────────────────

/**
 * Tracks each participant's read position in the chat.
 * Used to calculate unread message counts without loading all messages.
 */
const participantSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    // Pointer to the last Message _id this user has read
    lastReadMessage: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Message',
      default: null,
    },
    // Timestamp is stored independently to support "mute since" queries
    lastReadAt: { type: Date },
    // Organizers and co-organizers can pin messages and remove members
    isAdmin: { type: Boolean, default: false },
    // Muted until: if set and in future, suppress push notifications
    mutedUntil: { type: Date, default: null },
    joinedAt: { type: Date, default: Date.now },
    leftAt: { type: Date, default: null },
  },
  { _id: false },
);

// ─────────────────────────────────────────────
//  Main Chat Schema
// ─────────────────────────────────────────────

const chatSchema = new mongoose.Schema(
  {
    // ── Chat type ─────────────────────────────────────────────
    /**
     * group — tied to a specific Game document
     * dm    — direct message between exactly 2 users
     */
    type: {
      type: String,
      enum: {
        values: ['group', 'dm'],
        message: "Chat type must be 'group' or 'dm'",
      },
      required: true,
      index: true,
    },

    // ── Group chat metadata (populated only when type === 'group') ─
    name: {
      type: String,
      trim: true,
      maxlength: [100, 'Chat name cannot exceed 100 characters'],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [300, 'Chat description cannot exceed 300 characters'],
    },
    // Thumbnail/avatar for the group chat
    avatarUrl: { type: String, default: null },

    // ── Game reference ────────────────────────────────────────
    // Only set when type === 'group'
    game: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Game',
      default: null,
      index: true,
    },

    // ── Participants ──────────────────────────────────────────
    participants: {
      type: [participantSchema],
      validate: {
        validator(arr) {
          if (this.type === 'dm') return arr.length === 2;
          return arr.length >= 1;
        },
        message: 'DM chats must have exactly 2 participants',
      },
    },

    // ── Pinned messages ───────────────────────────────────────
    // Organizers can pin up to 5 messages
    pinnedMessages: {
      type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Message' }],
      validate: {
        validator: (arr) => arr.length <= 5,
        message: 'Cannot pin more than 5 messages',
      },
    },

    // ── Last message snapshot ─────────────────────────────────
    // Denormalised to power chat list previews without an extra query
    lastMessage: {
      messageId: { type: mongoose.Schema.Types.ObjectId, ref: 'Message' },
      senderUsername: { type: String },
      preview: { type: String, maxlength: 100 }, // truncated content
      sentAt: { type: Date },
      type: { type: String }, // 'text' | 'image' | 'system'
    },

    // ── Total message counter ─────────────────────────────────
    messageCount: { type: Number, default: 0 },

    // ── Soft delete ───────────────────────────────────────────
    isActive: { type: Boolean, default: true },
    deletedAt: { type: Date, default: null },
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

// Fetch all chats for a user (chat list screen)
chatSchema.index({ 'participants.user': 1, isActive: 1 });

// Lookup a DM between two specific users (ensure uniqueness)
chatSchema.index({ type: 1, 'participants.user': 1 });

// Soft-delete filter
chatSchema.index({ deletedAt: 1 });

// ─────────────────────────────────────────────
//  Static Methods
// ─────────────────────────────────────────────

/**
 * Finds an existing DM channel between two users,
 * or creates one if it does not exist.
 *
 * @param {ObjectId} userAId
 * @param {ObjectId} userBId
 * @returns {Document} Chat document
 */
chatSchema.statics.findOrCreateDM = async function (userAId, userBId) {
  const existing = await this.findOne({
    type: 'dm',
    'participants.user': { $all: [userAId, userBId] },
    deletedAt: null,
  });

  if (existing) return existing;

  return this.create({
    type: 'dm',
    participants: [
      { user: userAId, isAdmin: false },
      { user: userBId, isAdmin: false },
    ],
  });
};

// ─────────────────────────────────────────────
//  Instance Methods
// ─────────────────────────────────────────────

/**
 * Returns the participant entry for a given userId, or null.
 */
chatSchema.methods.getParticipant = function (userId) {
  return this.participants.find((p) => p.user.toString() === userId.toString()) || null;
};

/**
 * Checks whether a user is an active participant in the chat.
 */
chatSchema.methods.hasActiveParticipant = function (userId) {
  const p = this.getParticipant(userId);
  return p !== null && p.leftAt === null;
};

// ─────────────────────────────────────────────
//  Model Export
// ─────────────────────────────────────────────

const Chat = mongoose.model('Chat', chatSchema);

module.exports = Chat;
