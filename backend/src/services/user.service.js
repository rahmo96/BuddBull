const path = require('path');
const fs = require('fs');
const mongoose = require('mongoose');
const User = require('../models/User.model');
const Rating = require('../models/Rating.model');
const Game = require('../models/Game.model');
const PerformanceLog = require('../models/PerformanceLog.model');
const AppError = require('../utils/AppError');
const logger = require('../utils/logger');
const { upload: uploadConfig } = require('../config/environment');
const friendService = require('./friend.service');

// ─────────────────────────────────────────────
//  Profile retrieval
// ─────────────────────────────────────────────

/**
 * Returns the full profile of the currently authenticated user.
 * This is the /me endpoint — includes private fields like email.
 */
const getMe = async (userId) => {
  const user = await User.findById(userId).active();
  if (!user) throw new AppError('User not found.', 404);

  // Debounced last-login touch for retention notifications (max once per 5 min).
  const now = Date.now();
  const lastLoginMs = user.lastLoginAt ? user.lastLoginAt.getTime() : 0;
  const LOGIN_TOUCH_DEBOUNCE_MS = 5 * 60 * 1000;
  if (!lastLoginMs || now - lastLoginMs >= LOGIN_TOUCH_DEBOUNCE_MS) {
    User.findByIdAndUpdate(userId, { $set: { lastLoginAt: new Date() } }).catch(() => {});
    user.lastLoginAt = new Date();
  }

  return user;
};

/**
 * Returns the PUBLIC profile of a user by their username.
 * Excludes private fields: email, location.postalCode, pushTokens, etc.
 */
const getPublicProfile = async (username) => {
  // Defensive fallback: if a 24-char ObjectId reaches this username handler
  // (e.g., route ordering/regex edge-cases), resolve by ID instead.
  if (mongoose.Types.ObjectId.isValid(username)) {
    const byId = await User.findById(username)
      .active()
      .notBanned()
      .select('-email -pushTokens -notificationPreferences -refreshTokenHash -verificationToken -resetPasswordToken');
    if (byId) return byId;
  }

  const user = await User.findOne({ username })
    .active()
    .notBanned()
    .select('-email -pushTokens -notificationPreferences -refreshTokenHash -verificationToken -resetPasswordToken');

  if (!user) throw new AppError('User not found.', 404);
  return user;
};

/**
 * Returns any user by ID (admin use only or internal).
 */
const getUserById = async (id) => {
  if (!mongoose.Types.ObjectId.isValid(id)) throw new AppError('Invalid user ID.', 400);
  const user = await User.findById(id).active();
  if (!user) throw new AppError('User not found.', 404);
  return user;
};

/**
 * Returns a public profile by Mongo ID with rating/game/activity summary.
 */
const getPublicProfileById = async (id, viewerId = null) => {
  if (!mongoose.Types.ObjectId.isValid(id)) throw new AppError('Invalid user ID.', 400);

  const user = await User.findById(id)
    .active()
    .notBanned()
    .select('-email -pushTokens -notificationPreferences -refreshTokenHash -verificationToken -resetPasswordToken');

  if (!user) throw new AppError('User not found.', 404);

  const relationship =
    viewerId && viewerId.toString() !== id.toString()
      ? await friendService.getRelationship(viewerId, id)
      : { isFriend: false, friendRequestStatus: 'none', friendRequestId: null };

  const [ratingSummary, recentLogs, upcomingGames] = await Promise.all([
    Rating.getProfileSummary(id),
    PerformanceLog.find({ user: id, deletedAt: null })
      .sort({ loggedAt: -1 })
      .limit(5)
      .select('sport type loggedAt matchOutcome durationMinutes')
      .lean(),
    Game.find({
      status: { $in: ['open', 'full', 'draft'] },
      deletedAt: null,
      $or: [
        { organizer: id },
        { players: { $elemMatch: { user: id, status: { $in: ['approved', 'pending', 'invited'] } } } },
      ],
      scheduledAt: { $gte: new Date() },
    })
      .sort({ scheduledAt: 1 })
      .limit(5)
      .select('title sport scheduledAt status location.city location.neighborhood')
      .lean(),
  ]);

  const obj = user.toObject();
  return {
    ...obj,
    friendsCount: obj.friendsCount ?? friendService._friendsCount(user),
    isFriend: relationship.isFriend,
    friendRequestStatus: relationship.friendRequestStatus,
    friendRequestId: relationship.friendRequestId,
    performanceSummary: {
      ratings: ratingSummary,
      recentActivity: recentLogs,
      upcomingGames,
    },
  };
};

// ─────────────────────────────────────────────
//  Profile update
// ─────────────────────────────────────────────

/**
 * Updates allowed profile fields for the authenticated user.
 * Password and email changes are intentionally excluded here
 * (handled by dedicated auth endpoints).
 *
 * @param {string} userId
 * @param {object} updates  Validated fields from updateProfileSchema
 */
const updateMe = async (userId, updates) => {
  // Prevent accidental password or role escalation through this endpoint
  const forbidden = ['password', 'role', 'email', 'isVerified', 'isBanned', 'isActive'];
  forbidden.forEach((field) => delete updates[field]);

  const user = await User.findByIdAndUpdate(userId, { $set: updates }, { new: true, runValidators: true }).active();

  if (!user) throw new AppError('User not found.', 404);

  logger.info(`Profile updated: ${userId}`);
  return user;
};

/**
 * Updates the user's username after confirming it isn't taken.
 */
const updateUsername = async (userId, newUsername) => {
  const taken = await User.findOne({ username: newUsername, _id: { $ne: userId } }).lean();
  if (taken) throw new AppError('That username is already taken.', 409);

  const user = await User.findByIdAndUpdate(userId, { username: newUsername }, { new: true }).active();
  if (!user) throw new AppError('User not found.', 404);

  logger.info(`Username updated: ${userId} → ${newUsername}`);
  return user;
};

// ─────────────────────────────────────────────
//  Profile picture
// ─────────────────────────────────────────────

/**
 * Saves a profile picture URL (after upload) and removes the old file.
 *
 * @param {string} userId
 * @param {string} newFilePath  Relative path to the uploaded file
 */
const updateProfilePicture = async (userId, newFilePath) => {
  const user = await User.findById(userId).active();
  if (!user) throw new AppError('User not found.', 404);

  // Delete old local picture if it exists (skip for S3/external URLs)
  if (user.profilePicture && !user.profilePicture.startsWith('http')) {
    const oldAbsPath = path.join(process.cwd(), uploadConfig.dir, user.profilePicture);
    try {
      if (fs.existsSync(oldAbsPath)) fs.unlinkSync(oldAbsPath);
    } catch (fsErr) {
      logger.warn(`Failed to delete old profile picture: ${fsErr.message}`);
    }
  }

  user.profilePicture = newFilePath;
  await user.save({ validateBeforeSave: false });

  logger.info(`Profile picture updated: ${userId}`);
  return user;
};

// ─────────────────────────────────────────────
//  Account deletion (soft delete)
// ─────────────────────────────────────────────

/**
 * Soft-deletes the user account. The record is retained for 30 days
 * before a scheduled admin job performs hard deletion (GDPR).
 *
 * @param {string} userId
 * @param {string} password  Must match current password before deletion
 */
const deleteMe = async (userId, password) => {
  const user = await User.findById(userId).active();
  if (!user) throw new AppError('User not found.', 404);

  if (!User.schema.paths.password) {
    throw new AppError('Account deletion is not available via this API endpoint for SSO-managed profiles.', 501);
  }

  const withSecret = await User.findById(userId).select('+password').active();
  const isCorrect = await withSecret.comparePassword(password);
  if (!isCorrect) throw new AppError('Password is incorrect. Account deletion cancelled.', 401);

  withSecret.softDelete();
  await withSecret.save({ validateBeforeSave: false });

  logger.info(`Account soft-deleted: ${userId}`);
};

// ─────────────────────────────────────────────
//  Follow / Unfollow
// ─────────────────────────────────────────────

/**
 * Follows a target user. Idempotent — safe to call multiple times.
 * @returns {{ requestId, status }}
 */
/** Sends a pending friend request (replaces instant follow). */
const followUser = async (actorId, targetId) => friendService.sendFriendRequest(actorId, targetId);

/** Removes mutual friendship. */
const unfollowUser = async (actorId, targetId) => friendService.unfriend(actorId, targetId);

/** @deprecated Use getFriends — kept for route compatibility. */
const getFollowers = (userId, opts) => friendService.getFriends(userId, opts);

/** @deprecated Use getFriends — kept for route compatibility. */
const getFollowing = (userId, opts) => friendService.getFriends(userId, opts);

// ─────────────────────────────────────────────
//  Search / Discovery
// ─────────────────────────────────────────────

/**
 * Full-text + filter search across users.
 * Returns a paginated list of public user cards.
 *
 * @param {object} filters  { q, sport, city, skillLevel, role, page, limit }
 */
const searchUsers = async (filters) => {
  const { q, sport, city, skillLevel, role, page = 1, limit = 20 } = filters;

  const query = { isActive: true, isBanned: false, deletedAt: null };

  if (q) {
    query.$text = { $search: q };
  }

  if (city) {
    query['location.city'] = new RegExp(city, 'i');
  }

  if (sport) {
    query['sportsInterests.sport'] = sport.toLowerCase();
  }

  if (skillLevel) {
    query['sportsInterests.skillLevel'] = skillLevel;
  }

  if (role) {
    query.role = role;
  }

  const skip = (Number(page) - 1) * Number(limit);

  const [users, total] = await Promise.all([
    User.find(query)
      .select(
        'username firstName lastName profilePicture stats location.city location.neighborhood sportsInterests role',
      )
      .sort(q ? { score: { $meta: 'textScore' } } : { 'stats.averageRating': -1 })
      .skip(skip)
      .limit(Number(limit))
      .lean(),
    User.countDocuments(query),
  ]);

  return {
    users,
    pagination: {
      total,
      page: Number(page),
      limit: Number(limit),
      pages: Math.ceil(total / Number(limit)),
    },
  };
};

// ─────────────────────────────────────────────
//  Push token management
// ─────────────────────────────────────────────

/**
 * Registers a device push token for the user.
 * Deduplicates by token value.
 */
const addPushToken = async (userId, { token, platform }) => {
  await User.findByIdAndUpdate(userId, {
    $addToSet: { pushTokens: { token, platform } },
  });
};

/**
 * Removes a device push token (e.g., on app uninstall / logout).
 */
const removePushToken = async (userId, token) => {
  await User.findByIdAndUpdate(userId, {
    $pull: { pushTokens: { token } },
  });
};

// ─────────────────────────────────────────────
//  Admin operations
// ─────────────────────────────────────────────

/**
 * Returns a paginated list of all users for the admin dashboard.
 */
const adminListUsers = async ({ page = 1, limit = 50, status, role } = {}) => {
  const query = { deletedAt: null };
  if (status === 'banned') query.isBanned = true;
  else if (status === 'inactive') query.isActive = false;
  else if (status === 'active') {
    query.isActive = true;
    query.isBanned = false;
  }
  if (role) query.role = role;

  const skip = (Number(page) - 1) * Number(limit);

  const [users, total] = await Promise.all([
    User.find(query)
      .select('username email firstName lastName role isActive isBanned isVerified stats createdAt lastLoginAt')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(Number(limit))
      .lean(),
    User.countDocuments(query),
  ]);

  return {
    users,
    pagination: {
      total,
      page: Number(page),
      limit: Number(limit),
      pages: Math.ceil(total / Number(limit)),
    },
  };
};

/**
 * Admin: ban or unban a user.
 */
const setBanStatus = async (targetId, isBanned, reason) => {
  const update = isBanned
    ? { isBanned: true, banReason: reason || 'Policy violation' }
    : { isBanned: false, $unset: { banReason: '' } };

  const user = await User.findByIdAndUpdate(targetId, update, { new: true });
  if (!user) throw new AppError('User not found.', 404);

  logger.info(`User ${isBanned ? 'banned' : 'unbanned'}: ${targetId}`);
  return user;
};

/**
 * Logs 48h rolling-streak inputs, then applies {@link User#updateStreak}.
 * Called when a training log is saved or a match is completed.
 */
const updateTrainingStreakWithDebugLog = (user, at = new Date()) => {
  const stats = user.stats || {};
  const last = stats.lastActivityDate;
  const now = at instanceof Date ? at : new Date(at);
  const hoursPassed = last
    ? ((now.getTime() - last.getTime()) / (1000 * 60 * 60)).toFixed(2)
    : 'n/a';
  logger.info(
    `Current Streak: ${stats.currentStreak ?? 0}, Last Activity: ${
      last ? last.toISOString() : 'none'
    }, Hours Passed: ${hoursPassed}`,
  );
  user.updateStreak(at);
};

module.exports = {
  getMe,
  getPublicProfile,
  getUserById,
  getPublicProfileById,
  updateMe,
  updateUsername,
  updateProfilePicture,
  deleteMe,
  followUser,
  unfollowUser,
  acceptFriendRequest: friendService.acceptFriendRequest,
  declineFriendRequest: friendService.declineFriendRequest,
  getFriends: friendService.getFriends,
  getFollowers,
  getFollowing,
  searchUsers,
  addPushToken,
  removePushToken,
  adminListUsers,
  setBanStatus,
  updateTrainingStreakWithDebugLog,
};
