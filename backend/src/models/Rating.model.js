const mongoose = require('mongoose');

// ─────────────────────────────────────────────
//  Rating Schema
// ─────────────────────────────────────────────
/**
 * Post-game peer-to-peer rating.
 *
 * After a Game transitions to 'completed', each approved player
 * can leave one rating per fellow participant.
 *
 * Two dimensions are scored (1–5):
 *   reliability  — showed up on time, didn't cancel last-minute
 *   behavior     — fair play, positive attitude, sportsmanship
 *
 * A composite communityScore is derived from both dimensions and
 * rolled up into User.stats.averageRating via a post-save hook.
 *
 * Design decisions:
 *  - One rating per rater–ratee–game triple (unique compound index).
 *  - Ratings are immutable after a grace period (enforced in service layer).
 *  - Anonymous flag: when true, the rater field is hidden from public
 *    API responses but retained for admin moderation.
 */

const ratingSchema = new mongoose.Schema(
  {
    // ── Parties ───────────────────────────────────────────────
    rater: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Rater is required'],
      index: true,
    },
    ratee: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Ratee is required'],
      index: true,
    },

    // ── Context ───────────────────────────────────────────────
    game: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Game',
      required: [true, 'Game reference is required'],
      // index declared via schema.index() below — do not add inline index: true
    },

    // ── Scores ────────────────────────────────────────────────
    /**
     * reliability: Did the rated player show up on time?
     *              Did they avoid last-minute cancellations?
     */
    reliabilityScore: {
      type: Number,
      required: [true, 'Reliability score is required'],
      min: [1, 'Score must be between 1 and 5'],
      max: [5, 'Score must be between 1 and 5'],
    },
    /**
     * behaviorScore: Fair play, positive attitude, communication.
     */
    behaviorScore: {
      type: Number,
      required: [true, 'Behavior score is required'],
      min: [1, 'Score must be between 1 and 5'],
      max: [5, 'Score must be between 1 and 5'],
    },
    /**
     * Derived composite score stored for fast leaderboard queries.
     * Formula: (reliabilityScore + behaviorScore) / 2
     * Computed pre-save.
     */
    compositeScore: {
      type: Number,
      min: 1,
      max: 5,
    },

    // ── Qualitative feedback ──────────────────────────────────
    comment: {
      type: String,
      trim: true,
      maxlength: [300, 'Comment cannot exceed 300 characters'],
    },

    // ── Flags ─────────────────────────────────────────────────
    // When true, rater identity is hidden in public API responses
    isAnonymous: { type: Boolean, default: false },

    // Admin moderation
    isFlagged: { type: Boolean, default: false },
    flagReason: { type: String, trim: true },
    flaggedAt: { type: Date },
    flaggedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    isHidden: { type: Boolean, default: false }, // Admin-removed from public view

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

// Prevent duplicate ratings (one per rater–ratee–game triple)
ratingSchema.index({ rater: 1, ratee: 1, game: 1 }, { unique: true });

// Fetch all ratings received by a user (profile screen)
ratingSchema.index({ ratee: 1, createdAt: -1 });

// Fetch all ratings given by a user
ratingSchema.index({ rater: 1, createdAt: -1 });

// Admin: all ratings for a specific game
ratingSchema.index({ game: 1 });

// Leaderboard: highest composite scores
ratingSchema.index({ compositeScore: -1, isHidden: 1 });

// ─────────────────────────────────────────────
//  Pre-save Hook — compute compositeScore
// ─────────────────────────────────────────────

ratingSchema.pre('save', function (next) {
  if (this.isModified('reliabilityScore') || this.isModified('behaviorScore')) {
    this.compositeScore = parseFloat(((this.reliabilityScore + this.behaviorScore) / 2).toFixed(2));
  }
  return next();
});

// ─────────────────────────────────────────────
//  Stats Rollup — Static Methods
// ─────────────────────────────────────────────
//
// IMPORTANT: We intentionally do NOT use a `post('save')` hook to roll up
// stats into `User.stats`, because the rating service writes via
// `findOneAndUpdate({ upsert: true })`, which does not trigger document
// middleware. Callers must invoke `Rating.recalculateUserStats(rateeId)`
// explicitly after every write (see `rating.service.js`).
//
// The aggregations below compute the composite score from raw scores
// (`reliabilityScore + behaviorScore`) rather than from the stored
// `compositeScore` field. This makes them robust against historical rows
// where the `pre('save')` hook never fired and `compositeScore` is null.

/**
 * Recomputes and persists `User.stats.averageRating` and
 * `User.stats.totalRatings` for a single user, from the live Rating
 * collection. Returns the fresh aggregates. Safe to call concurrently —
 * each call is a single aggregation + single update, with no read/modify/
 * write window in JavaScript land.
 *
 * If the user has no live ratings, their stats are reset to zero.
 */
ratingSchema.statics.recalculateUserStats = async function (rateeId) {
  const User = mongoose.model('User');
  const rateeObjectId = new mongoose.Types.ObjectId(rateeId);

  const [agg] = await this.aggregate([
    { $match: { ratee: rateeObjectId, deletedAt: null, isHidden: false } },
    {
      $group: {
        _id: '$ratee',
        averageRating: {
          $avg: { $divide: [{ $add: ['$reliabilityScore', '$behaviorScore'] }, 2] },
        },
        totalRatings: { $sum: 1 },
      },
    },
  ]);

  const averageRating = agg ? parseFloat(agg.averageRating.toFixed(2)) : 0;
  const totalRatings = agg ? agg.totalRatings : 0;

  await User.findByIdAndUpdate(rateeId, {
    $set: {
      'stats.averageRating': averageRating,
      'stats.totalRatings': totalRatings,
    },
  });

  return { averageRating, totalRatings };
};

/**
 * Backfills the `compositeScore` field on every Rating document that is
 * missing it (legacy rows written via `findOneAndUpdate` before the
 * service started computing the field explicitly). Idempotent.
 *
 * Returns the number of documents touched.
 */
ratingSchema.statics.backfillCompositeScore = async function () {
  const result = await this.updateMany(
    {
      $or: [{ compositeScore: null }, { compositeScore: { $exists: false } }],
    },
    [
      {
        $set: {
          compositeScore: {
            $round: [
              { $divide: [{ $add: ['$reliabilityScore', '$behaviorScore'] }, 2] },
              2,
            ],
          },
        },
      },
    ],
  );
  return result.modifiedCount || 0;
};

/**
 * Full reconciliation pass over the Rating collection.
 *
 *   1. Backfills `compositeScore` on any legacy rows.
 *   2. Aggregates `averageRating` + `totalRatings` for every distinct
 *      ratee that has live ratings, and bulk-updates `User.stats`.
 *   3. Resets stats to 0 for users whose only ratings were soft-deleted
 *      or hidden.
 *
 * Designed for one-shot admin invocation. Safe to re-run.
 *
 * Returns counters describing what changed.
 */
ratingSchema.statics.recalculateAllUserStats = async function () {
  const User = mongoose.model('User');

  const compositeBackfilled = await this.backfillCompositeScore();

  const aggregations = await this.aggregate([
    { $match: { deletedAt: null, isHidden: false } },
    {
      $group: {
        _id: '$ratee',
        averageRating: {
          $avg: { $divide: [{ $add: ['$reliabilityScore', '$behaviorScore'] }, 2] },
        },
        totalRatings: { $sum: 1 },
      },
    },
  ]);

  let usersUpdated = 0;
  if (aggregations.length > 0) {
    const bulkOps = aggregations.map((a) => ({
      updateOne: {
        filter: { _id: a._id },
        update: {
          $set: {
            'stats.averageRating': parseFloat(a.averageRating.toFixed(2)),
            'stats.totalRatings': a.totalRatings,
          },
        },
      },
    }));
    const bulkResult = await User.bulkWrite(bulkOps, { ordered: false });
    usersUpdated = bulkResult.modifiedCount || 0;
  }

  // Reset users whose previously-rolled-up stats are now stale because
  // every rating they once had has been soft-deleted/hidden.
  const ratedUserIds = aggregations.map((a) => a._id);
  const resetResult = await User.updateMany(
    {
      _id: { $nin: ratedUserIds },
      $or: [
        { 'stats.totalRatings': { $gt: 0 } },
        { 'stats.averageRating': { $gt: 0 } },
      ],
    },
    {
      $set: {
        'stats.averageRating': 0,
        'stats.totalRatings': 0,
      },
    },
  );

  return {
    compositeBackfilled,
    usersUpdated,
    usersReset: resetResult.modifiedCount || 0,
    rateesProcessed: aggregations.length,
  };
};

// ─────────────────────────────────────────────
//  Profile Summary — Static Method
// ─────────────────────────────────────────────

/**
 * Returns a detailed breakdown of a user's received ratings
 * suitable for rendering the community score card on their profile.
 */
ratingSchema.statics.getProfileSummary = async function (userId) {
  const pipeline = [
    {
      $match: {
        ratee: new mongoose.Types.ObjectId(userId),
        deletedAt: null,
        isHidden: false,
      },
    },
    {
      $group: {
        _id: null,
        totalRatings: { $sum: 1 },
        avgReliability: { $avg: '$reliabilityScore' },
        avgBehavior: { $avg: '$behaviorScore' },
        avgComposite: { $avg: '$compositeScore' },
        // Distribution (1-5 star buckets)
        dist1: { $sum: { $cond: [{ $lte: ['$compositeScore', 1.5] }, 1, 0] } },
        dist2: {
          $sum: { $cond: [{ $and: [{ $gt: ['$compositeScore', 1.5] }, { $lte: ['$compositeScore', 2.5] }] }, 1, 0] },
        },
        dist3: {
          $sum: { $cond: [{ $and: [{ $gt: ['$compositeScore', 2.5] }, { $lte: ['$compositeScore', 3.5] }] }, 1, 0] },
        },
        dist4: {
          $sum: { $cond: [{ $and: [{ $gt: ['$compositeScore', 3.5] }, { $lte: ['$compositeScore', 4.5] }] }, 1, 0] },
        },
        dist5: { $sum: { $cond: [{ $gt: ['$compositeScore', 4.5] }, 1, 0] } },
      },
    },
    {
      $project: {
        _id: 0,
        totalRatings: 1,
        avgReliability: { $round: ['$avgReliability', 1] },
        avgBehavior: { $round: ['$avgBehavior', 1] },
        avgComposite: { $round: ['$avgComposite', 2] },
        distribution: {
          1: '$dist1',
          2: '$dist2',
          3: '$dist3',
          4: '$dist4',
          5: '$dist5',
        },
      },
    },
  ];

  const [result] = await this.aggregate(pipeline);
  return (
    result || {
      totalRatings: 0,
      avgReliability: 0,
      avgBehavior: 0,
      avgComposite: 0,
    }
  );
};

// ─────────────────────────────────────────────
//  Instance Methods
// ─────────────────────────────────────────────

/**
 * Returns a public-safe version of the rating,
 * masking the rater identity when isAnonymous is true.
 */
ratingSchema.methods.toPublicJSON = function () {
  const obj = this.toObject();
  if (obj.isAnonymous) {
    obj.rater = null;
  }
  delete obj.flagReason;
  delete obj.flaggedBy;
  delete obj.__v;
  return obj;
};

// ─────────────────────────────────────────────
//  Model Export
// ─────────────────────────────────────────────

const Rating = mongoose.model('Rating', ratingSchema);

module.exports = Rating;
