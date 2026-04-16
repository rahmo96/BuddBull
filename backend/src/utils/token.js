const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { promisify } = require('util');
const { jwt: jwtConfig } = require('../config/environment');

// ─────────────────────────────────────────────
//  Access Token  (short-lived, stateless)
// ─────────────────────────────────────────────

/**
 * Signs a new access token.
 * Payload: { id, role }
 */
const signAccessToken = (userId, role) =>
  jwt.sign({ id: userId, role }, jwtConfig.secret, {
    expiresIn: jwtConfig.expiresIn,
    issuer: 'buddbull',
    audience: 'buddbull-client',
  });

/**
 * Verifies an access token and returns its decoded payload.
 * Throws JsonWebTokenError or TokenExpiredError on failure.
 */
const verifyAccessToken = (token) =>
  promisify(jwt.verify)(token, jwtConfig.secret, {
    issuer: 'buddbull',
    audience: 'buddbull-client',
  });

// ─────────────────────────────────────────────
//  Refresh Token  (long-lived, stateful)
// ─────────────────────────────────────────────
//
//  Strategy:
//   1. Generate a cryptographically random raw token (32 bytes).
//   2. Sign it as a JWT so the client has a single opaque value.
//   3. Store the SHA-256 hash in User.refreshTokenHash (DB).
//   4. On /refresh: verify JWT signature → re-hash payload token →
//      compare to stored hash → issue new access token.
//   5. On logout: clear the stored hash → token is permanently invalidated.

/**
 * Signs a new refresh token.
 * Payload: { id, token } — where token is a random hex string.
 * Returns { refreshToken (JWT), rawToken (hex), tokenHash (sha256) }
 */
const signRefreshToken = (userId) => {
  const rawToken = crypto.randomBytes(32).toString('hex');
  const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');

  const refreshToken = jwt.sign({ id: userId, token: rawToken }, jwtConfig.refreshSecret, {
    expiresIn: jwtConfig.refreshExpiresIn,
    issuer: 'buddbull',
    audience: 'buddbull-refresh',
  });

  return { refreshToken, tokenHash };
};

/**
 * Verifies a refresh token JWT and returns its decoded payload.
 * Throws on invalid / expired token.
 */
const verifyRefreshToken = (token) =>
  promisify(jwt.verify)(token, jwtConfig.refreshSecret, {
    issuer: 'buddbull',
    audience: 'buddbull-refresh',
  });

/**
 * Derives the stored hash from a raw refresh token string.
 * Used to look up the user row during /refresh.
 */
const hashRefreshToken = (rawToken) => crypto.createHash('sha256').update(rawToken).digest('hex');

// ─────────────────────────────────────────────
//  Cookie helpers
// ─────────────────────────────────────────────

const REFRESH_COOKIE_NAME = 'buddbull_rt';

const refreshCookieOptions = {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: process.env.NODE_ENV === 'production' ? 'None' : 'Lax',
  maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days in ms
  path: '/api/v1/auth/refresh',
};

/**
 * Attaches the refresh token as an HttpOnly cookie and
 * returns the access token in the JSON response body.
 *
 * Separation: access token in body (short-lived, used by mobile/SPA);
 *             refresh token in cookie (long-lived, inaccessible to JS).
 */
const sendTokenResponse = (res, statusCode, user, accessToken, refreshToken) => {
  res.cookie(REFRESH_COOKIE_NAME, refreshToken, refreshCookieOptions);

  const userObj = user.toObject ? user.toObject() : user;
  // Strip fields that should never leave the server
  delete userObj.password;
  delete userObj.refreshTokenHash;
  delete userObj.verificationToken;
  delete userObj.resetPasswordToken;
  delete userObj.__v;

  // Include tokens in body for mobile clients (web can still use cookie for refresh)
  res.status(statusCode).json({
    success: true,
    data: {
      user: userObj,
      accessToken,
      refreshToken,
    },
  });
};

/**
 * Clears the refresh token cookie (used on logout).
 */
const clearRefreshCookie = (res) => {
  res.clearCookie(REFRESH_COOKIE_NAME, { path: '/api/v1/auth/refresh' });
};

module.exports = {
  signAccessToken,
  verifyAccessToken,
  signRefreshToken,
  verifyRefreshToken,
  hashRefreshToken,
  sendTokenResponse,
  clearRefreshCookie,
  REFRESH_COOKIE_NAME,
};
