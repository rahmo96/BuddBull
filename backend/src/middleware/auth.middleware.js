const User = require('../models/User.model');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');
const { verifyAccessToken } = require('../utils/token');

// ─────────────────────────────────────────────
//  protect  — verifies JWT and attaches req.user
// ─────────────────────────────────────────────

/**
 * Protects any route that requires authentication.
 *
 * Token resolution order:
 *  1. Authorization: Bearer <token>  (primary — used by mobile & SPA)
 *  2. x-auth-token header            (legacy fallback)
 *
 * After a successful verification the full user document
 * (excluding password + token fields) is attached to req.user.
 */
const protect = catchAsync(async (req, res, next) => {
  // 1. Extract token
  let token;
  if (req.headers.authorization?.startsWith('Bearer ')) {
    token = req.headers.authorization.split(' ')[1];
  } else if (req.headers['x-auth-token']) {
    token = req.headers['x-auth-token'];
  }

  if (!token) {
    return next(new AppError('You are not logged in. Please authenticate to continue.', 401));
  }

  // 2. Verify signature + expiry
  const decoded = await verifyAccessToken(token);

  // 3. Confirm the user still exists and is in a healthy state
  const user = await User.findById(decoded.id)
    .select('+passwordChangedAt')
    .active()
    .notBanned();

  if (!user) {
    return next(new AppError('The account associated with this token no longer exists.', 401));
  }

  // 4. Reject tokens issued before a password change
  if (user.passwordChangedAfter(decoded.iat)) {
    return next(new AppError('Your password was recently changed. Please log in again.', 401));
  }

  // 5. Attach user and token metadata to the request
  req.user = user;
  req.tokenPayload = decoded;

  return next();
});

// ─────────────────────────────────────────────
//  restrictTo  — Role-Based Access Control
// ─────────────────────────────────────────────

/**
 * Factory that returns middleware restricting access to specific roles.
 * Must be used AFTER `protect`.
 *
 * Usage:
 *   router.delete('/users/:id', protect, restrictTo('admin'), deleteUser)
 *   router.post('/games',       protect, restrictTo('organizer', 'admin'), createGame)
 */
const restrictTo =
  (...roles) =>
  (req, res, next) => {
    if (!req.user) {
      return next(new AppError('Authentication required before role check.', 401));
    }

    if (!roles.includes(req.user.role)) {
      return next(
        new AppError(`Access denied. Required role(s): ${roles.join(' or ')}. Your role: ${req.user.role}.`, 403),
      );
    }

    return next();
  };

// ─────────────────────────────────────────────
//  optionalAuth  — attaches user if token present, never blocks
// ─────────────────────────────────────────────

/**
 * Like `protect` but does not reject unauthenticated requests.
 * Useful for public routes that show extra data to logged-in users
 * (e.g., public game list that shows "joined" state to auth'd users).
 */
const optionalAuth = catchAsync(async (req, res, next) => {
  let token;
  if (req.headers.authorization?.startsWith('Bearer ')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (!token) return next();

  try {
    const decoded = await verifyAccessToken(token);
    const user = await User.findById(decoded.id).active().notBanned();
    if (user && !user.passwordChangedAfter(decoded.iat)) {
      req.user = user;
      req.tokenPayload = decoded;
    }
  } catch (_err) {
    // Token invalid — proceed as unauthenticated (do not error)
  }

  return next();
});

// ─────────────────────────────────────────────
//  verifyOwnership  — ensures the acting user owns the resource
// ─────────────────────────────────────────────

/**
 * Middleware factory that checks req.user.id === req.params[paramName].
 * Admins bypass this check.
 *
 * Usage:
 *   router.patch('/users/:id', protect, verifyOwnership('id'), updateUser)
 */
const verifyOwnership =
  (paramName = 'id') =>
  (req, res, next) => {
    const isAdmin = req.user.role === 'admin';
    const isOwner = req.user._id.toString() === req.params[paramName];

    if (!isAdmin && !isOwner) {
      return next(new AppError('You are not authorised to modify this resource.', 403));
    }

    return next();
  };

module.exports = { protect, restrictTo, optionalAuth, verifyOwnership };
