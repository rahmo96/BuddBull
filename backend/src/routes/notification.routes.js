const express = require('express');

const { protect } = require('../middleware/auth.middleware');
const notificationController = require('../controllers/notification.controller');
const { validateMongoId } = require('../validators/user.validator');

const router = express.Router();

// All notification routes require an authenticated user.
router.use(protect);

/**
 * @route  GET /api/v1/notifications
 * @desc   Paginated inbox for the current user (newest first).
 *         Query params: ?page=1&limit=50  (limit capped at 100).
 * @access Private
 */
router.get('/', notificationController.list);

/**
 * @route  PATCH /api/v1/notifications/read-all
 * @desc   Mark every unread notification belonging to the current user
 *         as read. Must be declared before the parameterised :id route
 *         so Express does not try to match "read-all" as an ObjectId.
 * @access Private
 */
router.patch('/read-all', notificationController.markAllRead);

/**
 * @route  PATCH /api/v1/notifications/:id/read
 * @desc   Mark a single notification as read.
 * @access Private
 */
router.patch('/:id/read', validateMongoId('id'), notificationController.markRead);

module.exports = router;
