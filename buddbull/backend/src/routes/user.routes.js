const express = require('express');

const UserController = require('../controllers/user.controller');
const { protect, restrictTo } = require('../middleware/auth.middleware');
const { handleProfilePicUpload } = require('../middleware/upload.middleware');
const { validate, updateProfileSchema, updateUsernameSchema, searchUsersSchema, addPushTokenSchema } =
  require('../validators/user.validator');
const { validateMongoId } = require('../validators/user.validator');

const router = express.Router();

// All user routes require authentication
router.use(protect);

// ─────────────────────────────────────────────
//  Current user (self)
// ─────────────────────────────────────────────

/**
 * @route  GET /api/v1/users/me
 * @desc   Get full profile of the authenticated user
 * @access Private
 */
router.get('/me', UserController.getMe);

/**
 * @route  PATCH /api/v1/users/me
 * @desc   Update profile fields (bio, sports, location, notification prefs)
 * @access Private
 */
router.patch('/me', validate(updateProfileSchema), UserController.updateMe);

/**
 * @route  PATCH /api/v1/users/me/username
 * @desc   Change username (uniqueness enforced)
 * @access Private
 */
router.patch('/me/username', validate(updateUsernameSchema), UserController.updateUsername);

/**
 * @route  POST /api/v1/users/me/profile-picture
 * @desc   Upload a new profile picture (multipart/form-data, field: profilePicture)
 * @access Private
 */
router.post('/me/profile-picture', handleProfilePicUpload, UserController.uploadProfilePicture);

/**
 * @route  DELETE /api/v1/users/me
 * @desc   Soft-delete own account (requires password confirmation in body)
 * @access Private
 */
router.delete('/me', UserController.deleteMe);

/**
 * @route  POST /api/v1/users/me/push-token
 * @desc   Register a FCM push token for this device
 * @access Private
 */
router.post('/me/push-token', validate(addPushTokenSchema), UserController.addPushToken);

/**
 * @route  DELETE /api/v1/users/me/push-token
 * @desc   Remove a FCM push token (on logout / uninstall)
 * @access Private
 */
router.delete('/me/push-token', UserController.removePushToken);

// ─────────────────────────────────────────────
//  Admin-only routes  (MUST be before /:username)
// ─────────────────────────────────────────────
// These literal-path routes must be registered before any parameterised
// routes (/:username, /:id) to prevent Express matching "admin" as a param.

/**
 * @route  GET   /api/v1/users/admin/list
 * @route  PATCH /api/v1/users/admin/:id/ban
 * @access Admin
 */
router.get('/admin/list', restrictTo('admin'), UserController.adminListUsers);
router.patch('/admin/:id/ban', restrictTo('admin'), validateMongoId('id'), UserController.adminBanUser);

// ─────────────────────────────────────────────
//  Discovery  (MUST be before /:username)
// ─────────────────────────────────────────────

/**
 * @route  GET /api/v1/users/search?q=...&sport=...&city=...&skillLevel=...
 * @desc   Full-text + filter search for users
 * @access Private
 */
router.get('/search', UserController.searchUsers);

// ─────────────────────────────────────────────
//  Social graph (by MongoDB ID)  (MUST be before /:username)
// ─────────────────────────────────────────────

/**
 * @route  POST   /api/v1/users/:id/follow
 * @route  DELETE /api/v1/users/:id/follow
 * @desc   Follow / unfollow a user
 * @access Private
 */
router.post('/:id/follow', validateMongoId('id'), UserController.followUser);
router.delete('/:id/follow', validateMongoId('id'), UserController.unfollowUser);

/**
 * @route  GET /api/v1/users/:id/followers
 * @route  GET /api/v1/users/:id/following
 * @desc   Paginated social graph lists
 * @access Private
 */
router.get('/:id/followers', validateMongoId('id'), UserController.getFollowers);
router.get('/:id/following', validateMongoId('id'), UserController.getFollowing);

// ─────────────────────────────────────────────
//  Public-facing user profiles  (parameterised — must be LAST)
// ─────────────────────────────────────────────

/**
 * @route  GET /api/v1/users/:username
 * @desc   Get public profile of any user by username
 * @access Private
 */
router.get('/:username', UserController.getUser);

module.exports = router;
