const User = require('../models/User.model');
const AppError = require('./AppError');

/**
 * Throws 403 if the user account is soft-restricted (can log in, but cannot
 * join/create games or send chat messages).
 *
 * @param {string|import('mongoose').Types.ObjectId|{ isRestricted?: boolean }} userOrId
 */
const assertNotRestricted = async (userOrId) => {
  let isRestricted = false;

  if (userOrId && typeof userOrId === 'object' && 'isRestricted' in userOrId) {
    isRestricted = !!userOrId.isRestricted;
  } else {
    const user = await User.findById(userOrId).select('isRestricted').lean();
    if (!user) throw new AppError('User not found', 404);
    isRestricted = !!user.isRestricted;
  }

  if (isRestricted) {
    throw new AppError('Your account is restricted from this action.', 403);
  }
};

module.exports = { assertNotRestricted };
