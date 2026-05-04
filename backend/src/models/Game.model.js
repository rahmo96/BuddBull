const mongoose = require('mongoose');

// ─────────────────────────────────────────────
//  Sub-schemas
// ─────────────────────────────────────────────

/**
 * Represents a single player slot within a game.
 * Status transitions: invited → pending → approved | kicked | left
 */
const playerSlotSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    status: {
      type: String,
      enum: ['invited', 'pending', 'approved', 'kicked', 'left'],
      default: 'pending',
    },
    role: {
      type: String,
      enum: ['player', 'co-organizer'],
      default: 'player',
    },
    joinedAt: { type: Date, default: Date.now },
    // Timestamp for when the organizer approved/kicked the player
    resolvedAt: { type: Date },
  },
  { _id: false },
);

/**
 * Area-level location — never precise GPS coordinates.
 * postalCode is selected: false to prevent accidental exposure.
 */
const gamLocationSchema = new mongoose.Schema(
  {
    venueName: { type: String, trim: true, maxlength: 100 },
    address: { type: String, trim: true, maxlength: 200 },
    neighborhood: {
      type: String,
      trim: true,
      required: [true, 'Neighborhood is required for matchmaking'],
    },
    city: {
      type: String,
      trim: true,
      required: [true, 'City is required'],
    },
    state: { type: String, trim: true },
    country: { type: String, trim: true, default: 'US' },
    postalCode: { type: String, trim: true, select: false },
  },
  { _id: false },
);

const gameResultSchema = new mongoose.Schema(
  {
    winnerDescription: { type: String, trim: true },
    score: { type: String, trim: true },
    mvpUser: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    notes: { type: String, trim: true, maxlength: 500 },
    recordedAt: { type: Date, default: Date.now },
    recordedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  },
  { _id: false },
);

// ─────────────────────────────────────────────
//  Main Game Schema
// ─────────────────────────────────────────────

const gameSchema = new mongoose.Schema(
  {
    // ── Core info ─────────────────────────────────────────────
    title: {
      type: String,
      required: [true, 'Game title is required'],
      trim: true,
      maxlength: [100, 'Title cannot exceed 100 characters'],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [1000, 'Description cannot exceed 1000 characters'],
    },
    sport: {
      type: String,
      required: [true, 'Sport type is required'],
      trim: true,
      lowercase: true,
    },
    tags: [{ type: String, trim: true, lowercase: true }],

    // ── Organizer ─────────────────────────────────────────────
    organizer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Organizer is required'],
      index: true,
    },

    // ── Schedule ──────────────────────────────────────────────
    scheduledAt: {
      type: Date,
      required: [true, 'Scheduled date/time is required'],
      validate: {
        validator(date) {
          return date > new Date();
        },
        message: 'Game must be scheduled in the future',
      },
    },
    /**
     * Duration in minutes.
     * Used for double-booking prevention:
     *   occupiedUntil = scheduledAt + durationMinutes
     */
    durationMinutes: {
      type: Number,
      required: [true, 'Duration is required'],
      min: [15, 'Game must last at least 15 minutes'],
      max: [480, 'Game cannot exceed 8 hours'],
    },

    // ── Location ──────────────────────────────────────────────
    location: {
      type: gamLocationSchema,
      required: true,
    },

    // ── Capacity ──────────────────────────────────────────────
    maxPlayers: {
      type: Number,
      required: [true, 'Maximum players is required'],
      min: [2, 'A game must allow at least 2 players'],
      max: [100, 'A game cannot exceed 100 players'],
    },
    minPlayersToStart: {
      type: Number,
      default: 2,
      min: 2,
    },

    // ── Players ───────────────────────────────────────────────
    players: {
      type: [playerSlotSchema],
      default: [],
    },

    // ── Skill filter ──────────────────────────────────────────
    requiredSkillLevel: {
      type: String,
      enum: ['any', 'beginner', 'intermediate', 'advanced', 'professional'],
      default: 'any',
    },

    // ── Game status ───────────────────────────────────────────
    /**
     * Lifecycle:  draft → open ─┬─ full ──┬─ in_progress → completed
     *                            │         └─ (capacity freed) → open
     *                            └─ cancelled
     */
    status: {
      type: String,
      enum: {
        values: ['draft', 'open', 'full', 'in_progress', 'completed', 'cancelled'],
        message: 'Invalid game status',
      },
      default: 'open',
      index: true,
    },
    cancelledReason: { type: String, trim: true },
    cancelledAt: { type: Date },
    cancelledBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

    // ── Visibility & join settings ────────────────────────────
    isPrivate: { type: Boolean, default: false },
    requiresApproval: { type: Boolean, default: false },
    allowSpectators: { type: Boolean, default: true },

    // ── Group merge support ───────────────────────────────────
    /**
     * When two under-capacity games are merged:
     *  - The surviving game sets mergedWith = [id of absorbed game]
     *  - The absorbed game sets mergedInto = id of surviving game
     *    and status = 'cancelled'
     */
    isMerged: { type: Boolean, default: false },
    mergedWith: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Game' }],
    mergedInto: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Game',
      default: null,
    },
    mergedAt: { type: Date },

    // ── Chat room ─────────────────────────────────────────────
    groupChat: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Chat',
      default: null,
    },

    // ── Post-game result ──────────────────────────────────────
    result: { type: gameResultSchema, default: null },

    // ── Soft delete ───────────────────────────────────────────
    deletedAt: { type: Date, default: null },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  },
);

// ─────────────────────────────────────────────
//  Virtuals
// ─────────────────────────────────────────────

gameSchema.virtual('approvedPlayerCount').get(function () {
  return this.players.filter((p) => p.status === 'approved').length;
});

gameSchema.virtual('availableSlots').get(function () {
  const taken = this.players.filter((p) => p.status === 'approved').length;
  return Math.max(0, this.maxPlayers - taken);
});

/**
 * Returns the Date when the game is expected to end.
 * Used for double-booking validation.
 */
gameSchema.virtual('occupiedUntil').get(function () {
  if (!this.scheduledAt || !this.durationMinutes) return null;
  return new Date(this.scheduledAt.getTime() + this.durationMinutes * 60 * 1000);
});

gameSchema.virtual('isUpcoming').get(function () {
  return this.scheduledAt > new Date() && ['open', 'full', 'draft'].includes(this.status);
});

// ─────────────────────────────────────────────
//  Indexes
// ─────────────────────────────────────────────

// Core matchmaking query: sport + city + status + date
gameSchema.index({ sport: 1, 'location.city': 1, status: 1, scheduledAt: 1 });

// Neighbourhood-level search
gameSchema.index({ 'location.neighborhood': 1, sport: 1, scheduledAt: 1 });

// Organizer's game list
gameSchema.index({ organizer: 1, status: 1 });

// Skill level filtering
gameSchema.index({ requiredSkillLevel: 1, status: 1 });

// Calendar queries (date range)
gameSchema.index({ scheduledAt: 1, status: 1 });

// Soft-delete filter
gameSchema.index({ deletedAt: 1 });

// Text search on title and description
gameSchema.index({ title: 'text', description: 'text', sport: 'text', tags: 'text' });

// ─────────────────────────────────────────────
//  Pre-save Hooks
// ─────────────────────────────────────────────

/**
 * Auto-update status to 'full' when approved player count hits maxPlayers,
 * and revert to 'open' if a player leaves and a slot opens up.
 */
gameSchema.pre('save', function (next) {
  if (!this.isModified('players') && !this.isModified('maxPlayers')) return next();

  const approvedCount = this.players.filter((p) => p.status === 'approved').length;

  if (this.status === 'open' && approvedCount >= this.maxPlayers) {
    this.status = 'full';
  } else if (this.status === 'full' && approvedCount < this.maxPlayers) {
    this.status = 'open';
  }

  return next();
});

// ─────────────────────────────────────────────
//  Instance Methods
// ─────────────────────────────────────────────

/**
 * Checks whether a user already has an approved slot in this game.
 */
gameSchema.methods.hasPlayer = function (userId) {
  return this.players.some((p) => p.user.toString() === userId.toString() && p.status === 'approved');
};

/**
 * Detects a schedule conflict for a given user across all their games.
 * Call this as a static before adding a player to a new game.
 */
gameSchema.statics.hasConflict = async function (userId, proposedStart, proposedDurationMinutes) {
  const proposedEnd = new Date(proposedStart.getTime() + proposedDurationMinutes * 60 * 1000);

  const conflicting = await this.findOne({
    'players.user': userId,
    'players.status': 'approved',
    status: { $in: ['open', 'full', 'in_progress'] },
    deletedAt: null,
    // Overlap condition: existing.start < proposed.end AND existing.end > proposed.start
    scheduledAt: { $lt: proposedEnd },
    $expr: {
      $gt: [
        { $add: ['$scheduledAt', { $multiply: ['$durationMinutes', 60000] }] },
        proposedStart.getTime(),
      ],
    },
  });

  return !!conflicting;
};

/**
 * Returns a lean summary object safe for public API responses.
 * Excludes sensitive or internal fields.
 */
gameSchema.methods.toPublicJSON = function () {
  const obj = this.toObject();
  delete obj.deletedAt;
  delete obj.__v;
  return obj;
};

// ─────────────────────────────────────────────
//  Query Helpers
// ─────────────────────────────────────────────

gameSchema.query.upcoming = function () {
  return this.where({ scheduledAt: { $gt: new Date() }, deletedAt: null });
};

gameSchema.query.active = function () {
  return this.where({ status: { $in: ['open', 'full', 'in_progress'] }, deletedAt: null });
};

// ─────────────────────────────────────────────
//  Model Export
// ─────────────────────────────────────────────

const Game = mongoose.model('Game', gameSchema);

module.exports = Game;
