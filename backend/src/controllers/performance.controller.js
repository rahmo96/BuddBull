const catchAsync = require('../utils/catchAsync');
const PerformanceService = require('../services/performance.service');

// ─────────────────────────────────────────────
//  POST /api/v1/performance
// ─────────────────────────────────────────────

const createLog = catchAsync(async (req, res) => {
  const log = await PerformanceService.createLog(req.user._id, req.body);

  const message = log.newPersonalBests.length > 0
    ? `Log saved! You set ${log.newPersonalBests.length} new personal best(s)!`
    : 'Performance log saved.';

  res.status(201).json({ success: true, message, data: { log } });
});

// ─────────────────────────────────────────────
//  GET /api/v1/performance
// ─────────────────────────────────────────────

const getLogs = catchAsync(async (req, res) => {
  const result = await PerformanceService.getLogs(
    req.user._id,
    req.user._id,
    req.user.role,
    req.query,
  );

  res.status(200).json({ success: true, ...result });
});

// ─────────────────────────────────────────────
//  GET /api/v1/performance/stats
// ─────────────────────────────────────────────

const getStats = catchAsync(async (req, res) => {
  const stats = await PerformanceService.getStats(req.user._id, req.query);

  res.status(200).json({ success: true, data: stats });
});

// ─────────────────────────────────────────────
//  GET /api/v1/performance/streak
// ─────────────────────────────────────────────

const getStreakHistory = catchAsync(async (req, res) => {
  const days = parseInt(req.query.days, 10) || 30;
  const history = await PerformanceService.getStreakHistory(req.user._id, days);

  res.status(200).json({ success: true, data: { history } });
});

// ─────────────────────────────────────────────
//  GET /api/v1/performance/leaderboard
// ─────────────────────────────────────────────

const getLeaderboard = catchAsync(async (req, res) => {
  const { sport, limit } = req.query;
  if (!sport) {
    return res.status(400).json({ success: false, message: 'sport query param is required.' });
  }

  const leaderboard = await PerformanceService.getLeaderboard(sport, limit);
  return res.status(200).json({ success: true, data: { leaderboard } });
});

// ─────────────────────────────────────────────
//  GET /api/v1/performance/user/:userId
// ─────────────────────────────────────────────

const getUserLogs = catchAsync(async (req, res) => {
  const result = await PerformanceService.getLogs(
    req.params.userId,
    req.user._id,
    req.user.role,
    req.query,
  );

  res.status(200).json({ success: true, ...result });
});

// ─────────────────────────────────────────────
//  GET /api/v1/performance/:id
// ─────────────────────────────────────────────

const getLog = catchAsync(async (req, res) => {
  const log = await PerformanceService.getLog(req.params.id, req.user._id, req.user.role);

  res.status(200).json({ success: true, data: { log } });
});

// ─────────────────────────────────────────────
//  PATCH /api/v1/performance/:id
// ─────────────────────────────────────────────

const updateLog = catchAsync(async (req, res) => {
  const log = await PerformanceService.updateLog(req.params.id, req.user._id, req.body);

  res.status(200).json({ success: true, data: { log } });
});

// ─────────────────────────────────────────────
//  DELETE /api/v1/performance/:id
// ─────────────────────────────────────────────

const deleteLog = catchAsync(async (req, res) => {
  await PerformanceService.deleteLog(req.params.id, req.user._id, req.user.role);

  res.status(200).json({ success: true, message: 'Log deleted.' });
});

module.exports = {
  createLog,
  getLogs,
  getStats,
  getStreakHistory,
  getLeaderboard,
  getUserLogs,
  getLog,
  updateLog,
  deleteLog,
};
