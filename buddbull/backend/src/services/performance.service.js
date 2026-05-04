const mongoose = require('mongoose');
const PerformanceLog = require('../models/PerformanceLog.model');
const Game = require('../models/Game.model');
const User = require('../models/User.model');
const AppError = require('../utils/AppError');
const logger = require('../utils/logger');

// ─────────────────────────────────────────────
//  createLog
// ─────────────────────────────────────────────

/**
 * Creates a new performance log entry for the authenticated user.
 *
 * If gameId is provided:
 *  - Verifies the user was an approved participant
 *  - Pulls the sport from the game if not specified
 *
 * After saving, checks for new personal bests in any numeric stats.
 *
 * @param {string} userId
 * @param {object} dto  Validated createLogSchema fields
 */
const createLog = async (userId, dto) => {
  if (dto.gameId) {
    const game = await Game.findById(dto.gameId).lean();
    if (!game) throw new AppError('Referenced game not found.', 404);

    const isParticipant = game.players.some(
      (p) => p.user.toString() === userId.toString() && p.status === 'approved',
    );
    if (!isParticipant) {
      throw new AppError('You can only log a performance for games you participated in.', 403);
    }
  }

  const log = new PerformanceLog({
    user: userId,
    game: dto.gameId || null,
    type: dto.type,
    sport: dto.sport,
    loggedAt: dto.loggedAt,
    matchOutcome: dto.matchOutcome,
    opponentDescription: dto.opponentDescription,
    durationMinutes: dto.durationMinutes,
    stats: dto.stats || [],
    physicalMetrics: dto.physicalMetrics || {},
    mood: dto.mood,
    selfRating: dto.selfRating,
    notes: dto.notes,
    isPublic: dto.isPublic || false,
  });

  // ── Personal Best detection ───────────────────────────────
  const pbs = await detectPersonalBests(userId, dto.sport, dto.stats || []);
  log.newPersonalBests = pbs;

  // ── Streak snapshot ───────────────────────────────────────
  const user = await User.findById(userId);
  if (user) {
    user.updateStreak();
    log.streakAtLog = {
      current: user.stats.currentStreak,
      isStreakDay: true,
    };
    await user.save({ validateBeforeSave: false });
  }

  await log.save();
  logger.info(`Performance log created: ${log._id} for user ${userId}`);
  return log;
};

// ─────────────────────────────────────────────
//  detectPersonalBests
// ─────────────────────────────────────────────

/**
 * Compares numeric stats in the new log against the user's historical
 * maximums for the same sport. Returns an array of new PB records.
 *
 * @private
 */
const detectPersonalBests = async (userId, sport, stats) => {
  if (!stats || stats.length === 0) return [];

  const numericStats = stats.filter((s) => typeof s.value === 'number');
  if (numericStats.length === 0) return [];

  // For each numeric stat key, find the previous maximum value
  const pipeline = [
    { $match: { user: new mongoose.Types.ObjectId(userId), sport, deletedAt: null } },
    { $unwind: '$stats' },
    { $match: { 'stats.key': { $in: numericStats.map((s) => s.key) } } },
    {
      $group: {
        _id: '$stats.key',
        maxValue: { $max: '$stats.value' },
        unit: { $first: '$stats.unit' },
      },
    },
  ];

  const previousMaxes = await PerformanceLog.aggregate(pipeline);
  const maxMap = {};
  previousMaxes.forEach((p) => { maxMap[p._id] = { maxValue: p.maxValue, unit: p.unit }; });

  const newPBs = [];
  for (const stat of numericStats) {
    const prev = maxMap[stat.key];
    // New PB if no previous record OR new value is strictly greater
    if (!prev || stat.value > prev.maxValue) {
      newPBs.push({
        metric: stat.key,
        value: stat.value,
        unit: stat.unit || prev?.unit,
        achievedAt: new Date(),
      });
    }
  }

  return newPBs;
};

// ─────────────────────────────────────────────
//  getLog
// ─────────────────────────────────────────────

const getLog = async (logId, userId, userRole) => {
  if (!mongoose.Types.ObjectId.isValid(logId)) throw new AppError('Invalid log ID.', 400);

  const log = await PerformanceLog.findById(logId).notDeleted()
    .populate('game', 'title sport scheduledAt')
    .populate('user', 'username firstName lastName');

  if (!log) throw new AppError('Performance log not found.', 404);

  const isOwner = log.user._id.toString() === userId.toString();
  if (!isOwner && !log.isPublic && userRole !== 'admin') {
    throw new AppError('This log is private.', 403);
  }

  return log;
};

// ─────────────────────────────────────────────
//  getLogs  (paginated list for a user)
// ─────────────────────────────────────────────

const getLogs = async (userId, requesterId, requesterRole, filters = {}) => {
  const { sport, type, dateFrom, dateTo, matchOutcome, page = 1, limit = 20 } = filters;

  const isOwner = userId.toString() === requesterId.toString();
  const isAdmin = requesterRole === 'admin';

  const query = { user: userId, deletedAt: null };

  // Non-owners only see public logs (unless admin)
  if (!isOwner && !isAdmin) query.isPublic = true;

  if (sport) query.sport = sport;
  if (type) query.type = type;
  if (matchOutcome) query.matchOutcome = matchOutcome;

  if (dateFrom || dateTo) {
    query.loggedAt = {};
    if (dateFrom) query.loggedAt.$gte = new Date(dateFrom);
    if (dateTo) query.loggedAt.$lte = new Date(dateTo);
  }

  const skip = (Number(page) - 1) * Number(limit);

  const [logs, total] = await Promise.all([
    PerformanceLog.find(query)
      .populate('game', 'title sport scheduledAt')
      .sort({ loggedAt: -1 })
      .skip(skip)
      .limit(Number(limit))
      .lean(),
    PerformanceLog.countDocuments(query),
  ]);

  return { logs, pagination: { total, page: Number(page), limit: Number(limit), pages: Math.ceil(total / Number(limit)) } };
};

// ─────────────────────────────────────────────
//  updateLog
// ─────────────────────────────────────────────

const updateLog = async (logId, userId, updates) => {
  const log = await PerformanceLog.findById(logId).notDeleted();
  if (!log) throw new AppError('Performance log not found.', 404);

  if (log.user.toString() !== userId.toString()) {
    throw new AppError('You can only edit your own logs.', 403);
  }

  Object.assign(log, updates);
  await log.save();

  logger.info(`Performance log updated: ${logId}`);
  return log;
};

// ─────────────────────────────────────────────
//  deleteLog
// ─────────────────────────────────────────────

const deleteLog = async (logId, userId, userRole) => {
  const log = await PerformanceLog.findById(logId).notDeleted();
  if (!log) throw new AppError('Performance log not found.', 404);

  const isOwner = log.user.toString() === userId.toString();
  if (!isOwner && userRole !== 'admin') {
    throw new AppError('You can only delete your own logs.', 403);
  }

  log.deletedAt = new Date();
  await log.save({ validateBeforeSave: false });

  logger.info(`Performance log deleted: ${logId}`);
};

// ─────────────────────────────────────────────
//  getStats  (aggregated dashboard data)
// ─────────────────────────────────────────────

/**
 * Returns aggregated stats for a user's Performance Center dashboard.
 * Includes sport breakdown, win/loss record, and total activity time.
 *
 * @param {string} userId
 * @param {object} opts  { dateFrom, dateTo, sport }
 */
const getStats = async (userId, { dateFrom, dateTo, sport } = {}) => {
  const [summary, recentPBs, activityHeatmap] = await Promise.all([
    PerformanceLog.aggregateForUser(userId, dateFrom ? new Date(dateFrom) : null, dateTo ? new Date(dateTo) : null),
    getRecentPersonalBests(userId, sport),
    getActivityHeatmap(userId, 90),
  ]);

  return { summary, recentPBs, activityHeatmap };
};

// ─────────────────────────────────────────────
//  getStreakHistory
// ─────────────────────────────────────────────

/**
 * Returns the last N days of streak data for the progress graph.
 * Format: array of { date, isActive, streakCount, sport }
 */
const getStreakHistory = async (userId, days = 30) => {
  const logs = await PerformanceLog.getStreakHistory(userId, days);

  // Build a date-keyed map for easy frontend rendering
  const history = {};
  const sinceDate = new Date();
  sinceDate.setDate(sinceDate.getDate() - days);

  // Pre-fill all days with inactive
  for (let i = 0; i <= days; i++) {
    const d = new Date(sinceDate);
    d.setDate(d.getDate() + i);
    const key = d.toISOString().split('T')[0];
    history[key] = { date: key, isActive: false, streakCount: 0 };
  }

  // Overlay actual log days
  for (const log of logs) {
    const key = new Date(log.loggedAt).toISOString().split('T')[0];
    history[key] = {
      date: key,
      isActive: true,
      streakCount: log.streakAtLog?.current || 0,
      sport: log.sport,
      type: log.type,
    };
  }

  return Object.values(history).sort((a, b) => a.date.localeCompare(b.date));
};

// ─────────────────────────────────────────────
//  getRecentPersonalBests  (private helper)
// ─────────────────────────────────────────────

const getRecentPersonalBests = async (userId, sport) => {
  const query = {
    user: new mongoose.Types.ObjectId(userId),
    deletedAt: null,
    'newPersonalBests.0': { $exists: true },
  };
  if (sport) query.sport = sport;

  return PerformanceLog.find(query, { newPersonalBests: 1, sport: 1, loggedAt: 1 })
    .sort({ loggedAt: -1 })
    .limit(10)
    .lean();
};

// ─────────────────────────────────────────────
//  getActivityHeatmap  (private helper)
// ─────────────────────────────────────────────

/**
 * Counts activity sessions per day over the past N days.
 * Powers the GitHub-style activity heatmap in the Performance Center.
 */
const getActivityHeatmap = async (userId, days = 90) => {
  const since = new Date();
  since.setDate(since.getDate() - days);

  const pipeline = [
    { $match: { user: new mongoose.Types.ObjectId(userId), loggedAt: { $gte: since }, deletedAt: null } },
    {
      $group: {
        _id: {
          $dateToString: { format: '%Y-%m-%d', date: '$loggedAt' },
        },
        count: { $sum: 1 },
        sports: { $addToSet: '$sport' },
      },
    },
    { $sort: { _id: 1 } },
    { $project: { _id: 0, date: '$_id', count: 1, sports: 1 } },
  ];

  return PerformanceLog.aggregate(pipeline);
};

// ─────────────────────────────────────────────
//  getLeaderboard  (public ranking by sport)
// ─────────────────────────────────────────────

/**
 * Returns the top N players by total session count for a given sport.
 * Used for the gamification leaderboard screen.
 */
const getLeaderboard = async (sport, limit = 20) => {
  const pipeline = [
    { $match: { sport, deletedAt: null, isPublic: true } },
    { $group: { _id: '$user', totalSessions: { $sum: 1 }, wins: { $sum: { $cond: [{ $eq: ['$matchOutcome', 'win'] }, 1, 0] } } } },
    { $sort: { totalSessions: -1, wins: -1 } },
    { $limit: Number(limit) },
    {
      $lookup: {
        from: 'users',
        localField: '_id',
        foreignField: '_id',
        as: 'userInfo',
        pipeline: [{ $project: { username: 1, firstName: 1, lastName: 1, profilePicture: 1, 'stats.averageRating': 1, 'stats.currentStreak': 1 } }],
      },
    },
    { $unwind: '$userInfo' },
    { $project: { _id: 0, user: '$userInfo', totalSessions: 1, wins: 1 } },
  ];

  return PerformanceLog.aggregate(pipeline);
};

module.exports = {
  createLog,
  getLog,
  getLogs,
  updateLog,
  deleteLog,
  getStats,
  getStreakHistory,
  getLeaderboard,
};
