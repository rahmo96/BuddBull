const catchAsync = require('../utils/catchAsync');
const { sendTokenResponse, clearRefreshCookie, REFRESH_COOKIE_NAME } = require('../utils/token');
const AuthService = require('../services/auth.service');

// ─────────────────────────────────────────────
//  POST /api/v1/auth/register
// ─────────────────────────────────────────────

const register = catchAsync(async (req, res) => {
  const { user, accessToken, refreshToken } = await AuthService.register(req.body);
  sendTokenResponse(res, 201, user, accessToken, refreshToken);
});

// ─────────────────────────────────────────────
//  POST /api/v1/auth/login
// ─────────────────────────────────────────────

const login = catchAsync(async (req, res) => {
  const { email, password } = req.body;
  const { user, accessToken, refreshToken } = await AuthService.login(email, password);
  sendTokenResponse(res, 200, user, accessToken, refreshToken);
});

// ─────────────────────────────────────────────
//  POST /api/v1/auth/logout
// ─────────────────────────────────────────────

const logout = catchAsync(async (req, res) => {
  await AuthService.logout(req.user._id);
  clearRefreshCookie(res);

  res.status(200).json({ success: true, message: 'Logged out successfully.' });
});

// ─────────────────────────────────────────────
//  POST /api/v1/auth/refresh
// ─────────────────────────────────────────────

const refresh = catchAsync(async (req, res) => {
  // Accept refresh token from HttpOnly cookie (preferred) or request body (mobile fallback)
  const incomingToken = req.cookies?.[REFRESH_COOKIE_NAME] || req.body?.refreshToken;

  const { accessToken, refreshToken } = await AuthService.refreshAccessToken(incomingToken);
  sendTokenResponse(res, 200, req.user || {}, accessToken, refreshToken);
});

// ─────────────────────────────────────────────
//  GET /api/v1/auth/verify-email/:token
// ─────────────────────────────────────────────

const verifyEmail = catchAsync(async (req, res) => {
  await AuthService.verifyEmail(req.params.token);

  res.status(200).json({
    success: true,
    message: 'Email verified successfully. Welcome to BuddBull!',
  });
});

// ─────────────────────────────────────────────
//  POST /api/v1/auth/resend-verification
// ─────────────────────────────────────────────

const resendVerification = catchAsync(async (req, res) => {
  await AuthService.resendVerificationEmail(req.user._id);

  res.status(200).json({
    success: true,
    message: 'Verification email sent. Please check your inbox.',
  });
});

// ─────────────────────────────────────────────
//  POST /api/v1/auth/forgot-password
// ─────────────────────────────────────────────

const forgotPassword = catchAsync(async (req, res) => {
  await AuthService.forgotPassword(req.body.email);

  // Always return 200 to prevent user enumeration
  res.status(200).json({
    success: true,
    message: 'If an account with that email exists, a password reset link has been sent.',
  });
});

// ─────────────────────────────────────────────
//  PATCH /api/v1/auth/reset-password/:token
// ─────────────────────────────────────────────

const resetPassword = catchAsync(async (req, res) => {
  const { user, accessToken, refreshToken } = await AuthService.resetPassword(
    req.params.token,
    req.body.password,
  );
  sendTokenResponse(res, 200, user, accessToken, refreshToken);
});

// ─────────────────────────────────────────────
//  PATCH /api/v1/auth/change-password
// ─────────────────────────────────────────────

const changePassword = catchAsync(async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  const { accessToken, refreshToken } = await AuthService.changePassword(
    req.user._id,
    currentPassword,
    newPassword,
  );

  // Re-issue tokens after password change (old access token will also be invalidated
  // on next use because passwordChangedAt will be updated)
  res.status(200).json({
    success: true,
    message: 'Password changed successfully.',
    accessToken,
    refreshToken,
  });
});

module.exports = {
  register,
  login,
  logout,
  refresh,
  verifyEmail,
  resendVerification,
  forgotPassword,
  resetPassword,
  changePassword,
};
