const mongoose = require('mongoose');

// ─────────────────────────────────────────────
//  Sub-schemas
// ─────────────────────────────────────────────

/**
 * Flexible key-value pairs for sport-specific metrics.
 * Examples:
 *   football:  { goals: 2, assists: 1, yellowCards: 0 }
 *   basketball: { points: 18, rebounds: 5, assists: 3 }
 *   running:   { distanceKm: 10, avgPaceMinPerKm: 5.4 }
 */
const sportStatSchema = new mongoose.Schema(
  {
    key: { type: String, required: true, trim: true },
    value: { type: mongoose.Schema.Types.Mixed, required: true },
    unit: { type: String, trim: true }, // 'km', 'min', 'goals', etc.
  },
  { _id: false },
);

/**
 * A personal best record captured at time of logging.
 * We persist the snapshot so historical PBs are never mutated
 * when future entries arrive.
 */
const personalBestSchema = new mongoose.Schema(
  {
    metric: { type: String, required: true, trim: true },
    value: { type: mongoose.Schema.Types.Mixed, required: true },
    unit: { type: String, trim: true },
    achievedAt: { type: Date, default: Date.now },
  },
  { _id: false },
);

// ─────────────────────────────────────────────
//  Main PerformanceLog Schema
// ─────────────────────────────────────────────

const performanceLogSchema = new mongoose.Schema(
  {
    // ── Ownership ─────────────────────────────────────────────
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User reference is required'],
      index: true,
    },

    // ── Optional game reference ───────────────────────────────
    // Null for standalone training sessions
    game: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Game',
      default: null,
      // index declared via schema.index() below — do not add inline index: true
    },

    // ── Log type ──────────────────────────────────────────────
    /**
     * match  — a competitive/social game result
     * training — solo or group training session
     * fitness  — gym, run, cycle, etc.
     */
    type: {
      type: String,
      enum: {
        values: ['match', 'training', 'fitness'],
        message: 'Log type must be match, training, or fitness',
      },
      required: [true, 'Log type is required'],
      index: true,
    },

    // ── Sport ─────────────────────────────────────────────────
    sport: {
      type: String,
      required: [true, 'Sport is required'],
      trim: true,
      lowercase: true,
    },

    // ── Date ─────────────────────────────────────────────────
    loggedAt: {
      type: Date,
      required: [true, 'Date of activity is required'],
      index: true,
    },

    // ── Match-specific outcome ────────────────────────────────
    matchOutcome: {
      type: String,
      enum: ['win', 'loss', 'draw', 'no_result'],
    },
    opponentDescription: { type: String, trim: true, maxlength: 100 },

    // ── Duration ─────────────────────────────────────────────
    durationMinutes: {
      type: Number,
      min: [1, 'Duration must be at least 1 minute'],
      max: [600, 'Duration cannot exceed 10 hours'],
    },

    // ── Sport-specific stats (flexible KV) ───────────────────
    stats: {
      type: [sportStatSchema],
      default: [],
    },

    // ── Physical metrics (universal) ─────────────────────────
    physicalMetrics: {
      caloriesBurned: { type: Number, min: 0 },
      averageHeartRate: { type: Number, min: 0, max: 250 },
      maxHeartRate: { type: Number, min: 0, max: 250 },
      distanceKm: { type: Number, min: 0 },
      stepsCount: { type: Number, min: 0 },
      perceivedExertion: { type: Number, min: 1, max: 10 }, // RPE scale
    },

    // ── Mood & subjective rating ──────────────────────────────
    mood: {
      type: String,
      enum: ['terrible', 'bad', 'neutral', 'good', 'excellent'],
    },
    selfRating: {
      type: Number,
      min: [1, 'Self rating must be between 1 and 5'],
      max: [5, 'Self rating must be between 1 and 5'],
    },

    // ── Personal best flags ───────────────────────────────────
    // Populated when a new PB is detected at write time
    newPersonalBests: {
      type: [personalBestSchema],
      default: [],
    },

    // ── Streak snapshot ───────────────────────────────────────
    // Captured at log time so streak history is queryable
    streakAtLog: {
      current: { type: Number, default: 0 },
      isStreakDay: { type: Boolean, default: false },
    },

    // ── Notes ─────────────────────────────────────────────────
    notes: {
      type: String,
      trim: true,
      maxlength: [1000, 'Notes cannot exceed 1000 characters'],
    },

    // ── Media ─────────────────────────────────────────────────
    // URLs to uploaded images/videos for this session
    mediaUrls: [{ type: String }],

    // ── Visibility ────────────────────────────────────────────
    isPublic: { type: Boolean, default: false },

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
//  Indexes
// ─────────────────────────────────────────────

// User's timeline — most queries page through this
performanceLogSchema.index({ user: 1, loggedAt: -1 });

// Filter by sport within a user's log
performanceLogSchema.index({ user: 1, sport: 1, loggedAt: -1 });

// Filter by type (match vs. training)
performanceLogSchema.index({ user: 1, type: 1, loggedAt: -1 });

// Aggregation pipeline: compute totals per sport per user
performanceLogSchema.index({ user: 1, sport: 1, type: 1 });

// Admin: inspect all logs for a specific game
performanceLogSchema.index({ game: 1 });

// Soft-delete filter
performanceLogSchema.index({ deletedAt: 1 });

// ─────────────────────────────────────────────
//  Static Methods
// ─────────────────────────────────────────────

/**
 * Returns aggregated stats for a user's performance dashboard.
 * Produces totals and averages per sport.
 *
 * @param {ObjectId} userId
 * @param {Date}     fromDate  - start of date range (optional)
 * @param {Date}     toDate    - end of date range (optional)
 */
performanceLogSchema.statics.aggregateForUser = async function (userId, fromDate, toDate) {
  const matchStage = {
    user: new mongoose.Types.ObjectId(userId),
    deletedAt: null,
  };

  if (fromDate || toDate) {
    matchStage.loggedAt = {};
    if (fromDate) matchStage.loggedAt.$gte = fromDate;
    if (toDate) matchStage.loggedAt.$lte = toDate;
  }

  const pipeline = [
    { $match: matchStage },
    {
      $group: {
        _id: { sport: '$sport', type: '$type' },
        totalSessions: { $sum: 1 },
        totalDurationMinutes: { $sum: '$durationMinutes' },
        wins: { $sum: { $cond: [{ $eq: ['$matchOutcome', 'win'] }, 1, 0] } },
        losses: { $sum: { $cond: [{ $eq: ['$matchOutcome', 'loss'] }, 1, 0] } },
        draws: { $sum: { $cond: [{ $eq: ['$matchOutcome', 'draw'] }, 1, 0] } },
        avgSelfRating: { $avg: '$selfRating' },
        avgCalories: { $avg: '$physicalMetrics.caloriesBurned' },
      },
    },
    {
      $group: {
        _id: '$_id.sport',
        breakdown: {
          $push: {
            type: '$_id.type',
            totalSessions: '$totalSessions',
            totalDurationMinutes: '$totalDurationMinutes',
            wins: '$wins',
            losses: '$losses',
            draws: '$draws',
            avgSelfRating: { $round: ['$avgSelfRating', 1] },
            avgCalories: { $round: ['$avgCalories', 0] },
          },
        },
        totalSessions: { $sum: '$totalSessions' },
      },
    },
    { $sort: { totalSessions: -1 } },
  ];

  return this.aggregate(pipeline);
};

/**
 * Returns the streak history (last 30 days) for the progress graph.
 */
performanceLogSchema.statics.getStreakHistory = async function (userId, days = 30) {
  const since = new Date();
  since.setDate(since.getDate() - days);

  return this.find(
    {
      user: userId,
      loggedAt: { $gte: since },
      deletedAt: null,
    },
    { loggedAt: 1, streakAtLog: 1, sport: 1, type: 1 },
  ).sort({ loggedAt: 1 });
};

// ─────────────────────────────────────────────
//  Query Helpers
// ─────────────────────────────────────────────

performanceLogSchema.query.notDeleted = function () {
  return this.where({ deletedAt: null });
};

performanceLogSchema.query.forSport = function (sport) {
  return this.where({ sport: sport.toLowerCase() });
};

// ─────────────────────────────────────────────
//  Model Export
// ─────────────────────────────────────────────

const PerformanceLog = mongoose.model('PerformanceLog', performanceLogSchema);

module.exports = PerformanceLog;
