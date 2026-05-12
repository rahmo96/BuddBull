const Rating = require('../models/Rating.model');
const RatingDismissal = require('../models/RatingDismissal.model');
const Game = require('../models/Game.model');
const User = require('../models/User.model');
const AppError = require('../utils/AppError');
const logger = require('../utils/logger');

// ── Rate a player ─────────────────────────────────────────────────────────────
const ratePlayer = async ({ raterId, rateeId, gameId, reliabilityScore, behaviorScore, comment, isAnonymous }) => {
  if (raterId.toString() === rateeId.toString()) {
    throw new AppError('You cannot rate yourself', 400);
  }

  // Verify both players were in the game
  const game = await Game.findOne({
    _id: gameId,
    status: 'completed',
    'players.user': { $all: [raterId, rateeId] },
    deletedAt: null,
  });
  if (!game) throw new AppError('Game not found or not completed', 404);

  const raterPlayer = game.players.find((p) => p.user.toString() === raterId.toString());
  if (!raterPlayer || !['approved'].includes(raterPlayer.status)) {
    throw new AppError('You were not an approved player in this game', 403);
  }
  const rateePlayer = game.players.find((p) => p.user.toString() === rateeId.toString());
  if (!rateePlayer || !['approved'].includes(rateePlayer.status)) {
    throw new AppError('The player you are rating was not in this game', 400);
  }

  // The Rating schema's `pre('save')` hook computes `compositeScore`, but
  // `findOneAndUpdate` does NOT trigger document middleware. We compute it
  // here so every upserted document has a correct value on disk.
  const compositeScore = parseFloat(((reliabilityScore + behaviorScore) / 2).toFixed(2));

  // Upsert rating (one per rater/ratee/game triplet)
  // Re-rating after a soft-delete clears the deletedAt flag.
  const rating = await Rating.findOneAndUpdate(
    { rater: raterId, ratee: rateeId, game: gameId },
    {
      rater: raterId,
      ratee: rateeId,
      game: gameId,
      reliabilityScore,
      behaviorScore,
      compositeScore,
      comment: comment || undefined,
      isAnonymous,
      deletedAt: null,
    },
    {
      upsert: true,
      new: true,
      setDefaultsOnInsert: true,
      runValidators: true,
    },
  );

  // Roll up into the ratee's denormalised User.stats. Document middleware
  // does not fire on findOneAndUpdate, so this MUST be called explicitly.
  // Failures here are non-critical (the response shape doesn't depend on
  // the rollup completing) but must be logged so we can reconcile later.
  try {
    await Rating.recalculateUserStats(rateeId);
  } catch (err) {
    logger.error(
      `[rating] Failed to recalculate User.stats for ratee ${rateeId} after rating ${rating._id}: ${err.message}`,
    );
  }

  return rating;
};

// ── Recalculate all user rating stats (admin reconciliation) ──────────────────
/**
 * Triggers a full reconciliation of `User.stats.averageRating` and
 * `User.stats.totalRatings` across every user with at least one rating,
 * and resets users whose stats are stale. Also backfills missing
 * `compositeScore` values on legacy rating documents.
 *
 * This exists because `findOneAndUpdate` bypasses Mongoose document
 * middleware — historic ratings written through the service have
 * `compositeScore = null` and never triggered a stats rollup. One-shot
 * call to fix the corpus; safe to re-run.
 */
const recalculateAllStats = async () => {
  const start = Date.now();
  const result = await Rating.recalculateAllUserStats();
  logger.info(
    `[rating] Recalculation finished in ${Date.now() - start}ms — ` +
      `compositeBackfilled=${result.compositeBackfilled}, usersUpdated=${result.usersUpdated}, ` +
      `usersReset=${result.usersReset}, rateesProcessed=${result.rateesProcessed}`,
  );
  return result;
};

// ── Get summary (aggregate) for a user's public profile ──────────────────────
const getProfileSummary = async (userId) => {
  const result = await Rating.getProfileSummary(userId);
  return result;
};

// ── Paginated ratings received by a user ─────────────────────────────────────
const getRatingsForUser = async (userId, { page = 1, limit = 20 } = {}) => {
  const RATER_FIELDS = 'firstName lastName username profilePicture';
  const filter = { ratee: userId, deletedAt: null };

  const [ratings, total] = await Promise.all([
    Rating.find(filter)
      .populate({
        path: 'rater',
        select: RATER_FIELDS,
        // Anonymous ratings: suppress rater info in response
      })
      .populate('game', 'title sport scheduledAt')
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean(),
    Rating.countDocuments(filter),
  ]);

  // Mask rater info for anonymous ratings
  const formatted = ratings.map((r) => ({
    ...r,
    rater: r.isAnonymous ? null : r.rater,
  }));

  return {
    ratings: formatted,
    total,
    page,
    totalPages: Math.ceil(total / limit),
  };
};

// ── Ratings given by a user ───────────────────────────────────────────────────
const getRatingsGivenByUser = async (userId, { page = 1, limit = 20 } = {}) => {
  const [ratings, total] = await Promise.all([
    Rating.find({ rater: userId, deletedAt: null })
      .populate('ratee', 'firstName lastName username profilePicture')
      .populate('game', 'title sport scheduledAt')
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean(),
    Rating.countDocuments({ rater: userId, deletedAt: null }),
  ]);
  return {
    ratings,
    total,
    page,
    totalPages: Math.ceil(total / limit),
  };
};

// ── Games a user completed but has not yet rated all opponents ────────────────
const getPendingRatings = async (userId) => {
  const dismissals = await RatingDismissal.find({ rater: userId }).select('game').lean();
  const dismissedGameIds = new Set(dismissals.map((d) => d.game.toString()));

  // Find all completed games the user participated in
  const completedGames = await Game.find({
    status: 'completed',
    'players.user': userId,
    'players.status': 'approved',
    deletedAt: null,
  })
    .populate('players.user', 'firstName lastName username profilePicture')
    .lean();

  const result = [];

  for (const game of completedGames) {
    if (dismissedGameIds.has(game._id.toString())) continue;
    const approvedPlayers = game.players.filter(
      (p) => p.status === 'approved' && p.user?._id?.toString() !== userId.toString(),
    );

    // Find existing ratings for this game by this user
    // eslint-disable-next-line no-await-in-loop
    const existingRatings = await Rating.find({
      rater: userId,
      game: game._id,
      deletedAt: null,
    })
      .select('ratee')
      .lean();

    const ratedIds = new Set(existingRatings.map((r) => r.ratee.toString()));
    const unratedPlayers = approvedPlayers.filter((p) => !ratedIds.has(p.user?._id?.toString()));

    if (unratedPlayers.length > 0) {
      result.push({
        game: {
          id: game._id,
          title: game.title,
          sport: game.sport,
          completedAt: game.updatedAt,
        },
        pendingPlayers: unratedPlayers.map((p) => p.user),
      });
    }
  }

  return result;
};

/**
 * Permanently hides a completed game from this user's pending-rating queue
 * (they chose not to rate anyone for that match).
 */
const dismissPendingRatingsForGame = async (raterId, gameId) => {
  const game = await Game.findOne({
    _id: gameId,
    deletedAt: null,
    status: 'completed',
  });
  if (!game) throw new AppError('Game not found or not completed.', 404);

  const isOrganizer = game.organizer.toString() === raterId.toString();
  const raterPlayer = game.players.find((p) => p.user.toString() === raterId.toString());
  const isApprovedParticipant = raterPlayer?.status === 'approved';

  if (!isOrganizer && !isApprovedParticipant) {
    throw new AppError('You were not a participant in this game.', 403);
  }

  await RatingDismissal.updateOne(
    { rater: raterId, game: gameId },
    { $setOnInsert: { rater: raterId, game: gameId } },
    { upsert: true },
  );

  return { dismissed: true };
};

module.exports = {
  ratePlayer,
  getProfileSummary,
  getRatingsForUser,
  getRatingsGivenByUser,
  getPendingRatings,
  dismissPendingRatingsForGame,
  recalculateAllStats,
};
