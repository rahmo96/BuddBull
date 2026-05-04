const Rating = require('../models/Rating.model');
const Game = require('../models/Game.model');
const User = require('../models/User.model');
const AppError = require('../utils/AppError');

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
    isDeleted: false,
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

  // Upsert rating (one per rater/ratee/game triplet)
  const rating = await Rating.findOneAndUpdate(
    { rater: raterId, ratee: rateeId, game: gameId },
    {
      rater: raterId,
      ratee: rateeId,
      game: gameId,
      reliabilityScore,
      behaviorScore,
      comment: comment || undefined,
      isAnonymous,
      isDeleted: false,
    },
    { upsert: true, new: true, setDefaultsOnInsert: true, runValidators: true },
  );

  return rating;
};

// ── Get summary (aggregate) for a user's public profile ──────────────────────
const getProfileSummary = async (userId) => {
  const result = await Rating.getProfileSummary(userId);
  return result;
};

// ── Paginated ratings received by a user ─────────────────────────────────────
const getRatingsForUser = async (userId, { page = 1, limit = 20 } = {}) => {
  const RATER_FIELDS = 'firstName lastName username profilePicture';
  const filter = { ratee: userId, isDeleted: false };

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

  return { ratings: formatted, total, page, totalPages: Math.ceil(total / limit) };
};

// ── Ratings given by a user ───────────────────────────────────────────────────
const getRatingsGivenByUser = async (userId, { page = 1, limit = 20 } = {}) => {
  const [ratings, total] = await Promise.all([
    Rating.find({ rater: userId, isDeleted: false })
      .populate('ratee', 'firstName lastName username profilePicture')
      .populate('game', 'title sport scheduledAt')
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean(),
    Rating.countDocuments({ rater: userId, isDeleted: false }),
  ]);
  return { ratings, total, page, totalPages: Math.ceil(total / limit) };
};

// ── Games a user completed but has not yet rated all opponents ────────────────
const getPendingRatings = async (userId) => {
  // Find all completed games the user participated in
  const completedGames = await Game.find({
    status: 'completed',
    'players.user': userId,
    'players.status': 'approved',
    isDeleted: false,
  })
    .populate('players.user', 'firstName lastName username profilePicture')
    .lean();

  const result = [];

  for (const game of completedGames) {
    const approvedPlayers = game.players.filter(
      (p) => p.status === 'approved' && p.user?._id?.toString() !== userId.toString(),
    );

    // Find existing ratings for this game by this user
    // eslint-disable-next-line no-await-in-loop
    const existingRatings = await Rating.find({
      rater: userId,
      game: game._id,
      isDeleted: false,
    }).select('ratee').lean();

    const ratedIds = new Set(existingRatings.map((r) => r.ratee.toString()));
    const unratedPlayers = approvedPlayers.filter(
      (p) => !ratedIds.has(p.user?._id?.toString()),
    );

    if (unratedPlayers.length > 0) {
      result.push({
        game: { id: game._id, title: game.title, sport: game.sport, completedAt: game.updatedAt },
        pendingPlayers: unratedPlayers.map((p) => p.user),
      });
    }
  }

  return result;
};

module.exports = { ratePlayer, getProfileSummary, getRatingsForUser, getRatingsGivenByUser, getPendingRatings };
