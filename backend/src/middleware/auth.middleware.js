const admin = require('firebase-admin');
const User = require('../models/User.model');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

const getFirebaseAuth = () => {
  if (!admin.apps.length) {
    // Prefer Application Default Credentials (GOOGLE_APPLICATION_CREDENTIALS),
    // but allow explicit service account env vars similar to notification.service.js.
    const { FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY } = process.env;
    if (FIREBASE_PROJECT_ID && FIREBASE_CLIENT_EMAIL && FIREBASE_PRIVATE_KEY) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: FIREBASE_PROJECT_ID,
          clientEmail: FIREBASE_CLIENT_EMAIL,
          privateKey: FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
    } else {
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
    }
  }

  return admin.auth();
};

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

  // 2. Verify Firebase ID token
  let decodedToken;
  try {
    decodedToken = await getFirebaseAuth().verifyIdToken(token);
  } catch (_err) {
    return next(new AppError('Invalid or expired token. Please authenticate again.', 401));
  }

  // 3. Find user by Firebase UID and ensure account is healthy
  const user = await User.findOne({ firebaseUid: decodedToken.uid }).active().notBanned();

  // Allow first-time users to hit the auth sync endpoint even if the Mongo user
  // row doesn't exist yet (it will be created via upsert in AuthService.syncUser).
  if (!user) {
    const isAuthSync = req.baseUrl === '/api/v1/auth' && req.path === '/sync';
    if (!isAuthSync) {
      return next(new AppError('The account associated with this token no longer exists.', 401));
    }
  }

  // 4. Attach user and token metadata to the request
  req.user = user || {
    firebaseUid: decodedToken.uid,
    email: decodedToken.email,
  };
  req.tokenPayload = decodedToken;

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
    const decodedToken = await getFirebaseAuth().verifyIdToken(token);
    const user = await User.findOne({ firebaseUid: decodedToken.uid }).active().notBanned();
    if (user) {
      req.user = user;
      req.tokenPayload = decodedToken;
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

module.exports = {
  protect,
  restrictTo,
  optionalAuth,
  verifyOwnership,
};
