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
//  Post-save Hook — roll up into User.stats
// ─────────────────────────────────────────────

/**
 * After a rating is saved, recompute the ratee's averageRating
 * using an aggregation to avoid race conditions from concurrent saves.
 */
ratingSchema.post('save', async function () {
  try {
    const User = mongoose.model('User');

    const [agg] = await mongoose.model('Rating').aggregate([
      { $match: { ratee: this.ratee, deletedAt: null, isHidden: false } },
      {
        $group: {
          _id: '$ratee',
          averageRating: { $avg: '$compositeScore' },
          totalRatings: { $sum: 1 },
        },
      },
    ]);

    if (agg) {
      await User.findByIdAndUpdate(this.ratee, {
        'stats.averageRating': parseFloat(agg.averageRating.toFixed(2)),
        'stats.totalRatings': agg.totalRatings,
      });
    }
  } catch (_err) {
    // Non-critical: log but do not block the response
    // The service layer should schedule a reconciliation job for failures
  }
});

// ─────────────────────────────────────────────
//  Static Methods
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
        dist2: { $sum: { $cond: [{ $and: [{ $gt: ['$compositeScore', 1.5] }, { $lte: ['$compositeScore', 2.5] }] }, 1, 0] } },
        dist3: { $sum: { $cond: [{ $and: [{ $gt: ['$compositeScore', 2.5] }, { $lte: ['$compositeScore', 3.5] }] }, 1, 0] } },
        dist4: { $sum: { $cond: [{ $and: [{ $gt: ['$compositeScore', 3.5] }, { $lte: ['$compositeScore', 4.5] }] }, 1, 0] } },
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
  return result || { totalRatings: 0, avgReliability: 0, avgBehavior: 0, avgComposite: 0 };
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
