const crypto = require('crypto');
const User = require('../models/User.model');
const AppError = require('../utils/AppError');
const { signAccessToken, signRefreshToken, verifyRefreshToken, hashRefreshToken } = require('../utils/token');
const { sendEmail } = require('../utils/email');
const { clientUrl } = require('../config/environment');
const logger = require('../utils/logger');

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────

/**
 * Issues a fresh access + refresh token pair for the given user,
 * persists the refresh token hash, and returns both tokens.
 */
const issueTokenPair = async (user) => {
  const accessToken = signAccessToken(user._id, user.role);
  const { refreshToken, tokenHash } = signRefreshToken(user._id);

  user.refreshTokenHash = tokenHash;
  user.lastLoginAt = new Date();
  await user.save({ validateBeforeSave: false });

  return { accessToken, refreshToken };
};

// ─────────────────────────────────────────────
//  register
// ─────────────────────────────────────────────

/**
 * Creates a new user account and sends a verification email.
 *
 * @param {object} dto  { firstName, lastName, username, email, password, role }
 * @returns {{ user, accessToken, refreshToken }}
 */
const register = async (dto) => {
  const { firstName, lastName, username, email, password, role } = dto;

  // Reject disposable / invalid email domains (basic check)
  const domain = email.split('@')[1];
  const blockedDomains = ['mailinator.com', 'guerrillamail.com', 'trashmail.com', 'tempmail.com', 'yopmail.com'];
  if (blockedDomains.includes(domain)) {
    throw new AppError('Please use a valid, non-disposable email address.', 422);
  }

  // Duplicate checks (email and username handled separately for clarity)
  const emailTaken = await User.findOne({ email }).lean();
  if (emailTaken) throw new AppError('An account with that email already exists.', 409);

  const usernameTaken = await User.findOne({ username }).lean();
  if (usernameTaken) throw new AppError('That username is already taken.', 409);

  // Create user — password hashing handled by pre-save hook
  const user = new User({ firstName, lastName, username, email, password, role: role || 'player' });

  // Generate email verification token before first save
  const rawVerificationToken = user.createVerificationToken();
  await user.save();

  // Send verification email (non-blocking — failure should not break registration)
  const verificationUrl = `${clientUrl}/verify-email?token=${rawVerificationToken}`;
  try {
    await sendEmail(email, 'verifyEmail', { firstName, verificationUrl });
  } catch (emailErr) {
    logger.error(`Verification email failed for ${email}: ${emailErr.message}`);
    // Continue — user can request a resend
  }

  const { accessToken, refreshToken } = await issueTokenPair(user);

  logger.info(`New user registered: ${email} (${role || 'player'})`);

  return { user, accessToken, refreshToken };
};

// ─────────────────────────────────────────────
//  login
// ─────────────────────────────────────────────

/**
 * Authenticates a user by email + password.
 *
 * @returns {{ user, accessToken, refreshToken }}
 */
const login = async (email, password) => {
  // Must select password explicitly (select: false in schema)
  const user = await User.findOne({ email }).select('+password +passwordChangedAt');

  if (!user || !(await user.comparePassword(password))) {
    // Generic message — never reveal whether the email exists
    throw new AppError('Incorrect email or password.', 401);
  }

  if (!user.isActive || user.deletedAt) {
    throw new AppError('This account has been deactivated. Please contact support.', 403);
  }

  if (user.isBanned) {
    throw new AppError(`Your account has been suspended. Reason: ${user.banReason || 'policy violation'}.`, 403);
  }

  const { accessToken, refreshToken } = await issueTokenPair(user);

  logger.info(`User logged in: ${email}`);

  return { user, accessToken, refreshToken };
};

// ─────────────────────────────────────────────
//  logout
// ─────────────────────────────────────────────

/**
 * Invalidates the refresh token for the given user.
 * The access token will naturally expire; client must discard it.
 */
const logout = async (userId) => {
  await User.findByIdAndUpdate(userId, { $unset: { refreshTokenHash: '' } });
  logger.info(`User logged out: ${userId}`);
};

// ─────────────────────────────────────────────
//  refreshAccessToken
// ─────────────────────────────────────────────

/**
 * Validates a refresh token and issues a new access token.
 * Implements refresh-token rotation: old token is revoked and a new
 * pair is issued on every call.
 *
 * @param {string} refreshToken  JWT from HttpOnly cookie or body
 * @returns {{ accessToken, refreshToken }}
 */
const refreshAccessToken = async (refreshToken) => {
  if (!refreshToken) throw new AppError('Refresh token is required.', 401);

  // 1. Verify JWT signature
  let decoded;
  try {
    decoded = await verifyRefreshToken(refreshToken);
  } catch (_err) {
    throw new AppError('Invalid or expired refresh token. Please log in again.', 401);
  }

  // 2. Derive hash from the raw token inside the JWT payload
  const tokenHash = hashRefreshToken(decoded.token);

  // 3. Match against the stored hash
  const user = await User.findOne({ _id: decoded.id, refreshTokenHash: tokenHash }).active();

  if (!user) {
    // Possible token reuse after logout — treat as potential theft
    logger.warn(`Refresh token reuse attempt detected for userId: ${decoded.id}`);
    throw new AppError('Session invalid. Please log in again.', 401);
  }

  // 4. Rotate — issue new pair, revoke old
  const tokens = await issueTokenPair(user);

  return tokens;
};

// ─────────────────────────────────────────────
//  verifyEmail
// ─────────────────────────────────────────────

/**
 * Marks the user's email as verified using the token from the
 * verification email.
 */
const verifyEmail = async (rawToken) => {
  const hashedToken = crypto.createHash('sha256').update(rawToken).digest('hex');

  const user = await User.findOne({
    verificationToken: hashedToken,
    verificationTokenExpiry: { $gt: Date.now() },
  }).select('+verificationToken +verificationTokenExpiry');

  if (!user) {
    throw new AppError('Verification link is invalid or has expired.', 400);
  }

  user.isVerified = true;
  user.verificationToken = undefined;
  user.verificationTokenExpiry = undefined;
  await user.save({ validateBeforeSave: false });

  // Send welcome email after verification
  try {
    await sendEmail(user.email, 'welcome', { firstName: user.firstName });
  } catch (emailErr) {
    logger.error(`Welcome email failed for ${user.email}: ${emailErr.message}`);
  }

  logger.info(`Email verified for user: ${user.email}`);
};

// ─────────────────────────────────────────────
//  resendVerificationEmail
// ─────────────────────────────────────────────

const resendVerificationEmail = async (userId) => {
  const user = await User.findById(userId).select('+verificationToken +verificationTokenExpiry');

  if (!user) throw new AppError('User not found.', 404);
  if (user.isVerified) throw new AppError('Email is already verified.', 400);

  const rawToken = user.createVerificationToken();
  await user.save({ validateBeforeSave: false });

  const verificationUrl = `${clientUrl}/verify-email?token=${rawToken}`;
  await sendEmail(user.email, 'verifyEmail', { firstName: user.firstName, verificationUrl });

  logger.info(`Verification email resent to: ${user.email}`);
};

// ─────────────────────────────────────────────
//  forgotPassword
// ─────────────────────────────────────────────

/**
 * Sends a password-reset link to the user's email.
 * Always returns success to prevent user enumeration attacks.
 */
const forgotPassword = async (email) => {
  const user = await User.findOne({ email, isActive: true, deletedAt: null });

  if (!user) {
    // Do NOT reveal that the email doesn't exist
    logger.warn(`Forgot-password attempt for unknown email: ${email}`);
    return;
  }

  const rawToken = user.createPasswordResetToken();
  await user.save({ validateBeforeSave: false });

  const resetUrl = `${clientUrl}/reset-password?token=${rawToken}`;
  try {
    await sendEmail(email, 'forgotPassword', {
      firstName: user.firstName,
      resetUrl,
      expiresInMinutes: 10,
    });
    logger.info(`Password reset email sent to: ${email}`);
  } catch (emailErr) {
    // Rollback the token if the email couldn't be sent
    user.resetPasswordToken = undefined;
    user.resetPasswordExpiry = undefined;
    await user.save({ validateBeforeSave: false });
    logger.error(`Failed to send password reset email to ${email}: ${emailErr.message}`);
    throw new AppError('Failed to send reset email. Please try again later.', 500);
  }
};

// ─────────────────────────────────────────────
//  resetPassword
// ─────────────────────────────────────────────

/**
 * Validates the reset token, updates the password, and returns
 * a fresh token pair (auto-login after reset).
 *
 * @param {string} rawToken    Token from the email link
 * @param {string} newPassword The new plaintext password
 * @returns {{ user, accessToken, refreshToken }}
 */
const resetPassword = async (rawToken, newPassword) => {
  const hashedToken = crypto.createHash('sha256').update(rawToken).digest('hex');

  const user = await User.findOne({
    resetPasswordToken: hashedToken,
    resetPasswordExpiry: { $gt: Date.now() },
  }).select('+resetPasswordToken +resetPasswordExpiry');

  if (!user) {
    throw new AppError('Password reset link is invalid or has expired.', 400);
  }

  user.password = newPassword;
  user.resetPasswordToken = undefined;
  user.resetPasswordExpiry = undefined;
  await user.save();

  // Notify user of successful password change
  try {
    await sendEmail(user.email, 'passwordChanged', { firstName: user.firstName });
  } catch (_err) {
    // Non-critical
  }

  logger.info(`Password reset for user: ${user.email}`);

  const { accessToken, refreshToken } = await issueTokenPair(user);
  return { user, accessToken, refreshToken };
};

// ─────────────────────────────────────────────
//  changePassword
// ─────────────────────────────────────────────

/**
 * Updates the password for an authenticated user.
 * Requires the current password for verification.
 */
const changePassword = async (userId, currentPassword, newPassword) => {
  const user = await User.findById(userId).select('+password');

  if (!user) throw new AppError('User not found.', 404);

  const isCorrect = await user.comparePassword(currentPassword);
  if (!isCorrect) throw new AppError('Current password is incorrect.', 401);

  user.password = newPassword;
  await user.save();

  try {
    await sendEmail(user.email, 'passwordChanged', { firstName: user.firstName });
  } catch (_err) {
    // Non-critical
  }

  logger.info(`Password changed for user: ${userId}`);

  const { accessToken, refreshToken } = await issueTokenPair(user);
  return { accessToken, refreshToken };
};

module.exports = {
  register,
  login,
  logout,
  refreshAccessToken,
  verifyEmail,
  resendVerificationEmail,
  forgotPassword,
  resetPassword,
  changePassword,
};
