const express = require('express');

const PerformanceController = require('../controllers/performance.controller');
const { protect } = require('../middleware/auth.middleware');
const { validateMongoId } = require('../validators/user.validator');
const { validate, createLogSchema, updateLogSchema, getLogsSchema, statsQuerySchema } =
  require('../validators/performance.validator');

const router = express.Router();

// All performance routes require authentication
router.use(protect);

// ─────────────────────────────────────────────
//  Collection endpoints  (must be before /:id)
// ─────────────────────────────────────────────

/**
 * @route  GET /api/v1/performance/stats
 * @desc   Aggregated performance stats for the authenticated user
 *         (sport breakdown, win/loss, total time, PBs)
 * @access Private
 */
router.get('/stats', validate(statsQuerySchema, 'query'), PerformanceController.getStats);

/**
 * @route  GET /api/v1/performance/streak
 * @desc   Daily streak history for the progress graph (default: 30 days)
 * @access Private
 */
router.get('/streak', PerformanceController.getStreakHistory);

/**
 * @route  GET /api/v1/performance/leaderboard?sport=football
 * @desc   Top players leaderboard for a given sport
 * @access Private
 */
router.get('/leaderboard', PerformanceController.getLeaderboard);

/**
 * @route  GET /api/v1/performance/user/:userId
 * @desc   View another user's public performance logs
 * @access Private
 */
router.get('/user/:userId', validateMongoId('userId'), validate(getLogsSchema, 'query'), PerformanceController.getUserLogs);

// ─────────────────────────────────────────────
//  Root resource
// ─────────────────────────────────────────────

/**
 * @route  POST /api/v1/performance
 * @desc   Create a new performance log (match, training, fitness)
 * @access Private
 */
router.post('/', validate(createLogSchema), PerformanceController.createLog);

/**
 * @route  GET /api/v1/performance
 * @desc   Get authenticated user's own performance logs (paginated)
 * @access Private
 */
router.get('/', validate(getLogsSchema, 'query'), PerformanceController.getLogs);

// ─────────────────────────────────────────────
//  Single log  (by :id — must be LAST)
// ─────────────────────────────────────────────

/**
 * @route  GET    /api/v1/performance/:id
 * @route  PATCH  /api/v1/performance/:id
 * @route  DELETE /api/v1/performance/:id
 */
router
  .route('/:id')
  .get(validateMongoId('id'), PerformanceController.getLog)
  .patch(validateMongoId('id'), validate(updateLogSchema), PerformanceController.updateLog)
  .delete(validateMongoId('id'), PerformanceController.deleteLog);

module.exports = router;
