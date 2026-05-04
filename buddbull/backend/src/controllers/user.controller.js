const path = require('path');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/AppError');
const UserService = require('../services/user.service');
const { upload: uploadConfig } = require('../config/environment');

// ─────────────────────────────────────────────
//  GET /api/v1/users/me
// ─────────────────────────────────────────────

const getMe = catchAsync(async (req, res) => {
  const user = await UserService.getMe(req.user._id);

  res.status(200).json({ success: true, data: { user } });
});

// ─────────────────────────────────────────────
//  GET /api/v1/users/:username
// ─────────────────────────────────────────────

const getUser = catchAsync(async (req, res) => {
  const user = await UserService.getPublicProfile(req.params.username);

  res.status(200).json({ success: true, data: { user } });
});

// ─────────────────────────────────────────────
//  PATCH /api/v1/users/me
// ─────────────────────────────────────────────

const updateMe = catchAsync(async (req, res) => {
  const user = await UserService.updateMe(req.user._id, req.body);

  res.status(200).json({ success: true, data: { user } });
});

// ─────────────────────────────────────────────
//  PATCH /api/v1/users/me/username
// ─────────────────────────────────────────────

const updateUsername = catchAsync(async (req, res) => {
  const user = await UserService.updateUsername(req.user._id, req.body.username);

  res.status(200).json({ success: true, data: { user } });
});

// ─────────────────────────────────────────────
//  POST /api/v1/users/me/profile-picture
// ─────────────────────────────────────────────

const uploadProfilePicture = catchAsync(async (req, res) => {
  if (!req.file) {
    throw new AppError('No image file provided. Please attach an image.', 400);
  }

  // Build a relative URL path suitable for the response and for storage
  let filePath;
  if (uploadConfig.driver === 's3') {
    // For S3: req.file.buffer would be uploaded here; for now return placeholder
    filePath = `https://your-bucket.s3.amazonaws.com/profiles/${req.file.originalname}`;
  } else {
    // Local disk: serve via /uploads/profiles/<filename>
    filePath = path.join('profiles', req.file.filename).replace(/\\/g, '/');
  }

  const user = await UserService.updateProfilePicture(req.user._id, filePath);

  res.status(200).json({
    success: true,
    message: 'Profile picture updated.',
    data: { profilePicture: user.profilePicture },
  });
});

// ─────────────────────────────────────────────
//  DELETE /api/v1/users/me
// ─────────────────────────────────────────────

const deleteMe = catchAsync(async (req, res) => {
  const { password } = req.body;
  if (!password) throw new AppError('Please provide your password to confirm account deletion.', 400);

  await UserService.deleteMe(req.user._id, password);

  res.status(200).json({
    success: true,
    message: 'Your account has been scheduled for deletion. You have 30 days to reactivate it.',
  });
});

// ─────────────────────────────────────────────
//  POST /api/v1/users/:id/follow
// ─────────────────────────────────────────────

const followUser = catchAsync(async (req, res) => {
  const result = await UserService.followUser(req.user._id, req.params.id);

  res.status(200).json({ success: true, data: result });
});

// ─────────────────────────────────────────────
//  DELETE /api/v1/users/:id/follow
// ─────────────────────────────────────────────

const unfollowUser = catchAsync(async (req, res) => {
  await UserService.unfollowUser(req.user._id, req.params.id);

  res.status(200).json({ success: true, message: 'Unfollowed successfully.' });
});

// ─────────────────────────────────────────────
//  GET /api/v1/users/:id/followers
// ─────────────────────────────────────────────

const getFollowers = catchAsync(async (req, res) => {
  const { page, limit } = req.query;
  const followers = await UserService.getFollowers(req.params.id, { page, limit });

  res.status(200).json({ success: true, results: followers.length, data: { followers } });
});

// ─────────────────────────────────────────────
//  GET /api/v1/users/:id/following
// ─────────────────────────────────────────────

const getFollowing = catchAsync(async (req, res) => {
  const { page, limit } = req.query;
  const following = await UserService.getFollowing(req.params.id, { page, limit });

  res.status(200).json({ success: true, results: following.length, data: { following } });
});

// ─────────────────────────────────────────────
//  GET /api/v1/users/search
// ─────────────────────────────────────────────

const searchUsers = catchAsync(async (req, res) => {
  const result = await UserService.searchUsers(req.query);

  res.status(200).json({ success: true, ...result });
});

// ─────────────────────────────────────────────
//  POST /api/v1/users/me/push-token
// ─────────────────────────────────────────────

const addPushToken = catchAsync(async (req, res) => {
  await UserService.addPushToken(req.user._id, req.body);

  res.status(200).json({ success: true, message: 'Push token registered.' });
});

// ─────────────────────────────────────────────
//  DELETE /api/v1/users/me/push-token
// ─────────────────────────────────────────────

const removePushToken = catchAsync(async (req, res) => {
  const { token } = req.body;
  if (!token) throw new AppError('Token is required.', 400);

  await UserService.removePushToken(req.user._id, token);

  res.status(200).json({ success: true, message: 'Push token removed.' });
});

// ─────────────────────────────────────────────
//  Admin: GET /api/v1/admin/users
// ─────────────────────────────────────────────

const adminListUsers = catchAsync(async (req, res) => {
  const result = await UserService.adminListUsers(req.query);

  res.status(200).json({ success: true, ...result });
});

// ─────────────────────────────────────────────
//  Admin: PATCH /api/v1/admin/users/:id/ban
// ─────────────────────────────────────────────

const adminBanUser = catchAsync(async (req, res) => {
  const { isBanned, reason } = req.body;
  const user = await UserService.setBanStatus(req.params.id, isBanned, reason);

  res.status(200).json({ success: true, data: { user } });
});

module.exports = {
  getMe,
  getUser,
  updateMe,
  updateUsername,
  uploadProfilePicture,
  deleteMe,
  followUser,
  unfollowUser,
  getFollowers,
  getFollowing,
  searchUsers,
  addPushToken,
  removePushToken,
  adminListUsers,
  adminBanUser,
};
