const User = require('../models/User.model');
/**
 * Syncs a Firebase-authenticated user into MongoDB.
 *
 * @param {string} firebaseUid
 * @param {string} email
 * @param {object} profileData { firstName, lastName, username, role }
 * @returns {Promise<User>}
 */
const syncUser = async (firebaseUid, email, profileData = {}) => {
  const update = {
    firebaseUid,
    email,
    firstName: profileData.firstName,
    lastName: profileData.lastName,
    username: profileData.username,
    role: profileData.role,
  };

  return User.findOneAndUpdate(
    { firebaseUid },
    { $set: update },
    {
      upsert: true,
      new: true,
      runValidators: true,
      setDefaultsOnInsert: true,
    },
  );
};

module.exports = {
  syncUser,
};
