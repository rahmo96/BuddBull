const catchAsync = require('../utils/catchAsync');
const AuthService = require('../services/auth.service');

/**
 * POST /api/v1/auth/sync
 *
 * Requires a valid Firebase ID token.
 * Syncs the Firebase identity into MongoDB (upsert by firebaseUid).
 */
const syncUser = catchAsync(async (req, res) => {
  const firebaseUid = req.user?.firebaseUid;
  const email = req.user?.email;

  const { firstName, lastName, username, role } = req.body || {};

  const user = await AuthService.syncUser(firebaseUid, email, {
    firstName,
    lastName,
    username,
    role,
  });

  res.status(200).json({
    success: true,
    data: { user },
  });
});

module.exports = {
  syncUser,
};
