const express = require('express');

const GameController = require('../controllers/game.controller');
const { protect, restrictTo, optionalAuth } = require('../middleware/auth.middleware');
const { validateMongoId } = require('../validators/user.validator');
const {
  validate,
  createGameSchema,
  updateGameSchema,
  searchGamesSchema,
  calendarSchema,
  completeGameSchema,
  kickPlayerSchema,
  mergeSchema,
  cancelSchema,
} = require('../validators/game.validator');

const router = express.Router();

// ─────────────────────────────────────────────
//  Admin routes  (must be before parameterised)
// ─────────────────────────────────────────────

/**
 * @route  GET /api/v1/games/admin/list
 * @access Admin
 */
router.get('/admin/list', protect, restrictTo('admin'), GameController.adminListGames);

// ─────────────────────────────────────────────
//  Auth-required, self-scoped routes
// ─────────────────────────────────────────────

/**
 * @route  GET /api/v1/games/me
 * @desc   All games the authenticated user has organised or joined
 * @access Private
 */
router.get('/me', protect, GameController.getMyGames);

/**
 * @route  GET /api/v1/games/calendar
 * @desc   Date-range schedule view for the authenticated user
 * @access Private
 */
router.get('/calendar', protect, validate(calendarSchema, 'query'), GameController.getCalendar);

// ─────────────────────────────────────────────
//  Create & Search  (root resource)
// ─────────────────────────────────────────────

/**
 * @route  POST /api/v1/games
 * @desc   Create a new game (organisers & admins)
 * @access Private — organizer or admin
 */
router.post('/', protect, restrictTo('organizer', 'admin'), validate(createGameSchema), GameController.createGame);

/**
 * @route  GET /api/v1/games
 * @desc   Search / filter games (city, sport, skill, date range, status)
 * @access Public (unauthenticated users see non-private games only)
 */
router.get('/', optionalAuth, validate(searchGamesSchema, 'query'), GameController.searchGames);

// ─────────────────────────────────────────────
//  Single game CRUD  (by :id)
// ─────────────────────────────────────────────

/**
 * @route  GET    /api/v1/games/:id
 * @route  PATCH  /api/v1/games/:id
 * @route  DELETE /api/v1/games/:id  (cancel)
 */
router
  .route('/:id')
  .get(optionalAuth, validateMongoId('id'), GameController.getGame)
  .patch(protect, validateMongoId('id'), validate(updateGameSchema), GameController.updateGame)
  .delete(protect, validateMongoId('id'), validate(cancelSchema), GameController.cancelGame);

// ─────────────────────────────────────────────
//  Player management  (under /:id)
// ─────────────────────────────────────────────

/**
 * @route  POST   /api/v1/games/:id/join
 * @desc   Join a game (conflict check performed here)
 * @access Private
 */
router.post('/:id/join', protect, validateMongoId('id'), GameController.joinGame);

/**
 * @route  DELETE /api/v1/games/:id/leave
 * @desc   Leave a game
 * @access Private
 */
router.delete('/:id/leave', protect, validateMongoId('id'), GameController.leaveGame);

/**
 * @route  GET /api/v1/games/:id/players/pending
 * @desc   List all pending join requests (organiser view)
 * @access Private — organiser or admin
 */
router.get('/:id/players/pending', protect, validateMongoId('id'), GameController.getPendingRequests);

/**
 * @route  POST   /api/v1/games/:id/invite/:userId
 * @desc   Organiser invites a specific user
 * @access Private — organiser or admin
 */
router.post(
  '/:id/invite/:userId',
  protect,
  validateMongoId('id'),
  validateMongoId('userId'),
  GameController.invitePlayer,
);

/**
 * @route  PATCH  /api/v1/games/:id/players/:userId/approve
 * @desc   Organiser approves a pending player
 * @access Private — organiser or admin
 */
router.patch(
  '/:id/players/:userId/approve',
  protect,
  validateMongoId('id'),
  validateMongoId('userId'),
  GameController.approvePlayer,
);

/**
 * @route  DELETE /api/v1/games/:id/players/:userId
 * @desc   Organiser kicks a player
 * @access Private — organiser or admin
 */
router.delete(
  '/:id/players/:userId',
  protect,
  validateMongoId('id'),
  validateMongoId('userId'),
  validate(kickPlayerSchema),
  GameController.kickPlayer,
);

// ─────────────────────────────────────────────
//  Group merge
// ─────────────────────────────────────────────

/**
 * @route  POST /api/v1/games/:id/merge/:targetId
 * @desc   Merge under-capacity source game (:id) into target (:targetId)
 * @access Private — organiser of source game
 */
router.post(
  '/:id/merge/:targetId',
  protect,
  validateMongoId('id'),
  validateMongoId('targetId'),
  validate(mergeSchema),
  GameController.mergeGroups,
);

// ─────────────────────────────────────────────
//  Game lifecycle
// ─────────────────────────────────────────────

/**
 * @route  PATCH /api/v1/games/:id/complete
 * @desc   Mark game completed + record result + update player stats
 * @access Private — organiser or admin
 */
router.patch(
  '/:id/complete',
  protect,
  validateMongoId('id'),
  validate(completeGameSchema),
  GameController.completeGame,
);

module.exports = router;
