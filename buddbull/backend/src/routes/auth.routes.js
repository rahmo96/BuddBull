const express = require('express');
const rateLimit = require('express-rate-limit');

const AuthController = require('../controllers/auth.controller');
const { protect } = require('../middleware/auth.middleware');
const { validate, registerSchema, loginSchema, forgotPasswordSchema, resetPasswordSchema, changePasswordSchema } =
  require('../validators/auth.validator');

const router = express.Router();

// ── Stricter rate limits for sensitive auth endpoints ──────────

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10,
  message: { success: false, message: 'Too many attempts. Please try again in 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
});

const forgotPasswordLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5,
  message: { success: false, message: 'Too many password reset requests. Please try again in 1 hour.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// ─────────────────────────────────────────────
//  Public routes  (no JWT required)
// ─────────────────────────────────────────────

/**
 * @route  POST /api/v1/auth/register
 * @desc   Create new account
 * @access Public
 */
router.post('/register', authLimiter, validate(registerSchema), AuthController.register);

/**
 * @route  POST /api/v1/auth/login
 * @desc   Authenticate and receive tokens
 * @access Public
 */
router.post('/login', authLimiter, validate(loginSchema), AuthController.login);

/**
 * @route  POST /api/v1/auth/refresh
 * @desc   Issue a new access token using the refresh token (cookie or body)
 * @access Public (but requires valid refresh token)
 */
router.post('/refresh', AuthController.refresh);

/**
 * @route  GET /api/v1/auth/verify-email/:token
 * @desc   Verify email address from link in verification email
 * @access Public
 */
router.get('/verify-email/:token', AuthController.verifyEmail);

/**
 * @route  POST /api/v1/auth/forgot-password
 * @desc   Send password reset email
 * @access Public
 */
router.post('/forgot-password', forgotPasswordLimiter, validate(forgotPasswordSchema), AuthController.forgotPassword);

/**
 * @route  PATCH /api/v1/auth/reset-password/:token
 * @desc   Set new password using the token from the reset email
 * @access Public (token acts as credential)
 */
router.patch('/reset-password/:token', validate(resetPasswordSchema), AuthController.resetPassword);

// ─────────────────────────────────────────────
//  Protected routes  (JWT required)
// ─────────────────────────────────────────────

/**
 * @route  POST /api/v1/auth/logout
 * @desc   Invalidate refresh token and clear cookie
 * @access Private
 */
router.post('/logout', protect, AuthController.logout);

/**
 * @route  POST /api/v1/auth/resend-verification
 * @desc   Re-send the email verification link
 * @access Private
 */
router.post('/resend-verification', protect, AuthController.resendVerification);

/**
 * @route  PATCH /api/v1/auth/change-password
 * @desc   Change password (requires current password)
 * @access Private
 */
router.patch('/change-password', protect, validate(changePasswordSchema), AuthController.changePassword);

module.exports = router;
