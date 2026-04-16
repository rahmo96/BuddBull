const path = require('path');
const fs = require('fs');
const mongoose = require('mongoose');
const User = require('../models/User.model');
const AppError = require('../utils/AppError');
const logger = require('../utils/logger');
const { upload: uploadConfig } = require('../config/environment');

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
  return user;
};

/**
 * Returns the PUBLIC profile of a user by their username.
 * Excludes private fields: email, location.postalCode, pushTokens, etc.
 */
const getPublicProfile = async (username) => {
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

  const user = await User.findByIdAndUpdate(
    userId,
    { $set: updates },
    { new: true, runValidators: true },
  ).active();

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
  const user = await User.findById(userId).select('+password').active();
  if (!user) throw new AppError('User not found.', 404);

  const isCorrect = await user.comparePassword(password);
  if (!isCorrect) throw new AppError('Password is incorrect. Account deletion cancelled.', 401);

  user.softDelete();
  await user.save({ validateBeforeSave: false });

  logger.info(`Account soft-deleted: ${userId}`);
};

// ─────────────────────────────────────────────
//  Follow / Unfollow
// ─────────────────────────────────────────────

/**
 * Follows a target user. Idempotent — safe to call multiple times.
 * @returns {{ followerCount, followingCount }}
 */
const followUser = async (actorId, targetId) => {
  if (actorId.toString() === targetId.toString()) {
    throw new AppError('You cannot follow yourself.', 400);
  }

  const [actor, target] = await Promise.all([
    User.findById(actorId).active(),
    User.findById(targetId).active().notBanned(),
  ]);

  if (!actor) throw new AppError('Actor user not found.', 404);
  if (!target) throw new AppError('Target user not found.', 404);

  const alreadyFollowing = actor.following.some((id) => id.toString() === targetId.toString());
  if (alreadyFollowing) throw new AppError('You are already following this user.', 409);

  await Promise.all([
    User.findByIdAndUpdate(actorId, { $addToSet: { following: targetId } }),
    User.findByIdAndUpdate(targetId, { $addToSet: { followers: actorId } }),
  ]);

  return {
    followerCount: target.followers.length + 1,
    followingCount: actor.following.length + 1,
  };
};

/**
 * Unfollows a target user.
 */
const unfollowUser = async (actorId, targetId) => {
  if (actorId.toString() === targetId.toString()) {
    throw new AppError('You cannot unfollow yourself.', 400);
  }

  await Promise.all([
    User.findByIdAndUpdate(actorId, { $pull: { following: targetId } }),
    User.findByIdAndUpdate(targetId, { $pull: { followers: actorId } }),
  ]);
};

/**
 * Returns the list of users following the given user.
 */
const getFollowers = async (userId, { page = 1, limit = 20 } = {}) => {
  const user = await User.findById(userId)
    .populate({
      path: 'followers',
      select: 'username firstName lastName profilePicture stats.averageRating location.city',
      options: {
        skip: (page - 1) * limit,
        limit: Number(limit),
      },
    })
    .active();

  if (!user) throw new AppError('User not found.', 404);
  return user.followers;
};

/**
 * Returns the list of users this user is following.
 */
const getFollowing = async (userId, { page = 1, limit = 20 } = {}) => {
  const user = await User.findById(userId)
    .populate({
      path: 'following',
      select: 'username firstName lastName profilePicture stats.averageRating location.city',
      options: {
        skip: (page - 1) * limit,
        limit: Number(limit),
      },
    })
    .active();

  if (!user) throw new AppError('User not found.', 404);
  return user.following;
};

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
      .select('username firstName lastName profilePicture stats location.city location.neighborhood sportsInterests role')
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
  else if (status === 'active') { query.isActive = true; query.isBanned = false; }
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

  return { users, pagination: { total, page: Number(page), limit: Number(limit), pages: Math.ceil(total / Number(limit)) } };
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

module.exports = {
  getMe,
  getPublicProfile,
  getUserById,
  updateMe,
  updateUsername,
  updateProfilePicture,
  deleteMe,
  followUser,
  unfollowUser,
  getFollowers,
  getFollowing,
  searchUsers,
  addPushToken,
  removePushToken,
  adminListUsers,
  setBanStatus,
};
