const mongoose = require('mongoose');

// ─────────────────────────────────────────────
//  Sub-schemas
// ─────────────────────────────────────────────

/**
 * Tracks who has read this message.
 * Kept minimal (userId + timestamp) to limit document bloat
 * in large group chats.
 */
const readReceiptSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    readAt: { type: Date, default: Date.now },
  },
  { _id: false },
);

/**
 * Stores metadata for any media attachment.
 */
const attachmentSchema = new mongoose.Schema(
  {
    url: { type: String, required: true },
    mimeType: { type: String, required: true }, // 'image/jpeg', 'video/mp4', etc.
    sizeBytes: { type: Number },
    thumbnailUrl: { type: String },
    originalName: { type: String },
  },
  { _id: false },
);

// ─────────────────────────────────────────────
//  Main Message Schema
// ─────────────────────────────────────────────

const messageSchema = new mongoose.Schema(
  {
    // ── Parent chat room ──────────────────────────────────────
    chat: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Chat',
      required: [true, 'Chat reference is required'],
      index: true,
    },

    // ── Sender ────────────────────────────────────────────────
    // Null for 'system' type messages (e.g. "Alice joined the group")
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },

    // ── Message type ─────────────────────────────────────────
    /**
     * text    — plain text or markdown
     * image   — single image with optional caption
     * video   — video attachment
     * file    — generic file
     * system  — auto-generated event message (join, leave, game-start)
     * pinned  — notification that a message was pinned (system variant)
     */
    type: {
      type: String,
      enum: ['text', 'image', 'video', 'file', 'system', 'pinned'],
      default: 'text',
      index: true,
    },

    // ── Content ───────────────────────────────────────────────
    content: {
      type: String,
      trim: true,
      maxlength: [2000, 'Message content cannot exceed 2000 characters'],
    },

    // ── Attachment (for image/video/file types) ───────────────
    attachment: { type: attachmentSchema, default: null },

    // ── Thread / Reply ────────────────────────────────────────
    // Optional reference to the message being replied to
    replyTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Message',
      default: null,
    },

    // ── Reactions ─────────────────────────────────────────────
    reactions: {
      type: Map,
      of: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
      default: {},
    },

    // ── Read receipts ─────────────────────────────────────────
    readBy: {
      type: [readReceiptSchema],
      default: [],
    },

    // ── Pinned state ──────────────────────────────────────────
    isPinned: { type: Boolean, default: false },
    pinnedAt: { type: Date },
    pinnedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },

    // ── Soft delete / edit ────────────────────────────────────
    isDeleted: { type: Boolean, default: false },
    deletedAt: { type: Date, default: null },
    isEdited: { type: Boolean, default: false },
    editedAt: { type: Date, default: null },
    // Keep original content for moderation audit trail (hidden from clients)
    originalContent: { type: String, select: false },
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

// Paginated message feed for a chat room (most common query)
messageSchema.index({ chat: 1, createdAt: -1 });

// Fetch all pinned messages for a chat
messageSchema.index({ chat: 1, isPinned: 1 });

// Find all messages by a sender in a specific chat
messageSchema.index({ chat: 1, sender: 1 });

// Unread count: messages after a timestamp in a chat
messageSchema.index({ chat: 1, createdAt: 1, isDeleted: 1 });

// ─────────────────────────────────────────────
//  Pre-save Hooks
// ─────────────────────────────────────────────

/**
 * Before editing, preserve the original content
 * for moderation review (stored as select: false).
 */
messageSchema.pre('save', function (next) {
  if (this.isModified('content') && !this.isNew) {
    this.originalContent = this.originalContent || this.content;
    this.isEdited = true;
    this.editedAt = new Date();
  }
  return next();
});

// ─────────────────────────────────────────────
//  Instance Methods
// ─────────────────────────────────────────────

/**
 * Marks the message as deleted without removing it
 * (preserve thread integrity).
 */
messageSchema.methods.softDelete = function () {
  this.isDeleted = true;
  this.deletedAt = new Date();
  this.content = '[This message was deleted]';
  this.attachment = null;
};

/**
 * Returns true if the given userId has read this message.
 */
messageSchema.methods.isReadBy = function (userId) {
  return this.readBy.some((r) => r.user.toString() === userId.toString());
};

/**
 * Adds a read receipt for a user if not already present.
 */
messageSchema.methods.markAsRead = function (userId) {
  if (!this.isReadBy(userId)) {
    this.readBy.push({ user: userId });
  }
};

// ─────────────────────────────────────────────
//  Virtual
// ─────────────────────────────────────────────

messageSchema.virtual('reactionSummary').get(function () {
  const summary = {};
  if (this.reactions) {
    this.reactions.forEach((users, emoji) => {
      summary[emoji] = users.length;
    });
  }
  return summary;
});

// ─────────────────────────────────────────────
//  Model Export
// ─────────────────────────────────────────────

const Message = mongoose.model('Message', messageSchema);

module.exports = Message;
