const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

// ─────────────────────────────────────────────
//  Sub-schemas
// ─────────────────────────────────────────────

/**
 * A single sport interest with skill level.
 * Embedded as an array in User to allow multi-sport profiles.
 */
const sportInterestSchema = new mongoose.Schema(
  {
    sport: {
      type: String,
      required: [true, 'Sport name is required'],
      trim: true,
      lowercase: true,
    },
    skillLevel: {
      type: String,
      enum: ['beginner', 'intermediate', 'advanced', 'professional'],
      default: 'beginner',
    },
    preferredPositions: [{ type: String, trim: true }],
    yearsOfExperience: { type: Number, min: 0, max: 50 },
  },
  { _id: false },
);

/**
 * Location stores only city / neighbourhood / country and a radius
 * preference. We deliberately never store precise GPS coordinates
 * for privacy reasons; geographic queries use area codes or
 * neighbourhood strings combined with the radius preference.
 */
const locationSchema = new mongoose.Schema(
  {
    country: { type: String, trim: true, default: 'US' },
    state: { type: String, trim: true },
    city: { type: String, trim: true },
    neighborhood: { type: String, trim: true },
    // Postal code used for approximate geo-lookups; never exposed raw
    postalCode: { type: String, trim: true, select: false },
    // Maximum distance (km) the user is willing to travel
    radiusKm: { type: Number, default: 10, min: 1, max: 200 },
  },
  { _id: false },
);

const notificationPrefsSchema = new mongoose.Schema(
  {
    gameInvites: { type: Boolean, default: true },
    gameReminders: { type: Boolean, default: true },
    gameStarting: { type: Boolean, default: true },
    groupMessages: { type: Boolean, default: true },
    directMessages: { type: Boolean, default: true },
    ratingReceived: { type: Boolean, default: true },
    groupMerges: { type: Boolean, default: true },
    broadcasts: { type: Boolean, default: true },
    recordsBroken: { type: Boolean, default: true },
  },
  { _id: false },
);

// ─────────────────────────────────────────────
//  Main User Schema
// ─────────────────────────────────────────────

const userSchema = new mongoose.Schema(
  {
    // ── Identity ─────────────────────────────────────────────
    firstName: {
      type: String,
      required: [true, 'First name is required'],
      trim: true,
      maxlength: [50, 'First name cannot exceed 50 characters'],
    },
    lastName: {
      type: String,
      required: [true, 'Last name is required'],
      trim: true,
      maxlength: [50, 'Last name cannot exceed 50 characters'],
    },
    username: {
      type: String,
      required: [true, 'Username is required'],
      unique: true,
      lowercase: true,
      trim: true,
      minlength: [3, 'Username must be at least 3 characters'],
      maxlength: [30, 'Username cannot exceed 30 characters'],
      match: [/^[a-z0-9_.-]+$/, 'Username may only contain lowercase letters, numbers, underscores, dots, or hyphens'],
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^[^\s@]+@[^\s@]+\.[^\s@]+$/, 'Please provide a valid email address'],
    },

    // ── Auth ─────────────────────────────────────────────────
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [6, 'Password must be at least 6 characters'],
      select: false, // never returned by default queries
    },
    role: {
      type: String,
      enum: {
        values: ['player', 'organizer', 'admin'],
        message: 'Role must be player, organizer, or admin',
      },
      default: 'player',
    },

    // ── Profile ───────────────────────────────────────────────
    bio: {
      type: String,
      trim: true,
      maxlength: [500, 'Bio cannot exceed 500 characters'],
    },
    profilePicture: {
      type: String, // URL to cloud-stored image (S3 / Firebase Storage)
      default: null,
    },
    dateOfBirth: {
      type: Date,
      validate: {
        validator(dob) {
          // Must be at least 13 years old
          const minAge = new Date();
          minAge.setFullYear(minAge.getFullYear() - 13);
          return dob <= minAge;
        },
        message: 'You must be at least 13 years old',
      },
    },
    gender: {
      type: String,
      enum: ['male', 'female', 'non-binary', 'prefer_not_to_say'],
    },

    // ── Sports ────────────────────────────────────────────────
    sportsInterests: {
      type: [sportInterestSchema],
      validate: {
        validator: (arr) => arr.length <= 10,
        message: 'You can register interest in up to 10 sports',
      },
    },

    // ── Location (privacy-safe) ───────────────────────────────
    location: { type: locationSchema, default: () => ({}) },

    // ── Social graph ──────────────────────────────────────────
    followers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    following: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

    // ── Aggregate stats (denormalised for fast profile reads) ─
    stats: {
      gamesPlayed: { type: Number, default: 0, min: 0 },
      gamesOrganized: { type: Number, default: 0, min: 0 },
      gamesWon: { type: Number, default: 0, min: 0 },
      currentStreak: { type: Number, default: 0, min: 0 },
      longestStreak: { type: Number, default: 0, min: 0 },
      lastActivityDate: { type: Date },
      // Community score: average of post-game reliability + behaviour ratings
      averageRating: { type: Number, default: 0, min: 0, max: 5 },
      totalRatings: { type: Number, default: 0, min: 0 },
    },

    // ── Account state ─────────────────────────────────────────
    isVerified: { type: Boolean, default: false },
    isActive: { type: Boolean, default: true },
    isBanned: { type: Boolean, default: false },
    banReason: { type: String },

    // ── Tokens (hidden from normal selects) ───────────────────
    verificationToken: { type: String, select: false },
    verificationTokenExpiry: { type: Date, select: false },
    resetPasswordToken: { type: String, select: false },
    resetPasswordExpiry: { type: Date, select: false },
    refreshTokenHash: { type: String, select: false },

    // ── Notification preferences ──────────────────────────────
    notificationPreferences: { type: notificationPrefsSchema, default: () => ({}) },

    // ── Push notification device tokens (FCM) ─────────────────
    pushTokens: {
      type: [{ token: String, platform: { type: String, enum: ['ios', 'android', 'web'] } }],
      select: false,
    },

    // ── Password change tracking ─────────────────────────────
    // Set whenever the password is changed post-registration.
    // JWT iat is compared against this to invalidate old tokens.
    passwordChangedAt: { type: Date, select: false },

    // ── Soft delete ───────────────────────────────────────────
    deletedAt: { type: Date, default: null },

    lastLoginAt: { type: Date },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  },
);

// ─────────────────────────────────────────────
//  Virtuals
// ─────────────────────────────────────────────

userSchema.virtual('fullName').get(function () {
  return `${this.firstName} ${this.lastName}`;
});

userSchema.virtual('age').get(function () {
  if (!this.dateOfBirth) return null;
  const diff = Date.now() - this.dateOfBirth.getTime();
  return Math.floor(diff / (1000 * 60 * 60 * 24 * 365.25));
});

userSchema.virtual('followerCount').get(function () {
  return this.followers ? this.followers.length : 0;
});

userSchema.virtual('followingCount').get(function () {
  return this.following ? this.following.length : 0;
});

// ─────────────────────────────────────────────
//  Indexes
// ─────────────────────────────────────────────

// Unique constraints already handle index creation for email & username.
// Additional compound + partial indexes for common query patterns:

// Search by sport type within a city
userSchema.index({ 'location.city': 1, 'sportsInterests.sport': 1 });
// Soft-delete filter
userSchema.index({ deletedAt: 1, isActive: 1 });
// Text search on username, bio
userSchema.index({ username: 'text', firstName: 'text', lastName: 'text', bio: 'text' });
// Leaderboard / ranking queries
userSchema.index({ 'stats.averageRating': -1, 'stats.gamesPlayed': -1 });

// ─────────────────────────────────────────────
//  Pre-save Hooks
// ─────────────────────────────────────────────

userSchema.pre('save', async function (next) {
  // Only re-hash if the password field was modified
  if (!this.isModified('password')) return next();

  // Track when the password was last changed (skip on first save)
  if (!this.isNew) {
    // Subtract 1s to avoid edge cases where the token iat === passwordChangedAt
    this.passwordChangedAt = new Date(Date.now() - 1000);
  }

  try {
    const saltRounds = Number(process.env.BCRYPT_SALT_ROUNDS) || 12;
    this.password = await bcrypt.hash(this.password, saltRounds);
    return next();
  } catch (err) {
    return next(err);
  }
});

// ─────────────────────────────────────────────
//  Instance Methods
// ─────────────────────────────────────────────

/**
 * Compares a plaintext candidate password with the stored hash.
 * Used during login.
 */
userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

/**
 * Generates a cryptographically secure password-reset token,
 * stores its SHA-256 hash in the document, and returns the
 * raw token to be sent to the user's email.
 */
userSchema.methods.createPasswordResetToken = function () {
  const rawToken = crypto.randomBytes(32).toString('hex');
  this.resetPasswordToken = crypto.createHash('sha256').update(rawToken).digest('hex');
  this.resetPasswordExpiry = Date.now() + 10 * 60 * 1000; // 10 minutes
  return rawToken;
};

/**
 * Generates an email verification token (same pattern as reset token).
 */
userSchema.methods.createVerificationToken = function () {
  const rawToken = crypto.randomBytes(32).toString('hex');
  this.verificationToken = crypto.createHash('sha256').update(rawToken).digest('hex');
  this.verificationTokenExpiry = Date.now() + 24 * 60 * 60 * 1000; // 24 hours
  return rawToken;
};

/**
 * Soft-deletes the account by setting deletedAt and clearing PII.
 * Hard deletion (GDPR erasure) can be performed separately by admins.
 */
userSchema.methods.softDelete = function () {
  this.deletedAt = new Date();
  this.isActive = false;
  this.email = `deleted_${this._id}@buddbull.deleted`;
  this.username = `deleted_${this._id}`;
  this.pushTokens = [];
};

/**
 * Returns true if the password was changed AFTER the given JWT iat.
 * Used in auth middleware to invalidate tokens issued before a
 * password-reset event.
 *
 * @param {number} jwtIssuedAt  Unix timestamp (seconds) from JWT payload
 */
userSchema.methods.passwordChangedAfter = function (jwtIssuedAt) {
  if (!this.passwordChangedAt) return false;
  const changedAtMs = this.passwordChangedAt.getTime();
  return changedAtMs > jwtIssuedAt * 1000;
};

/**
 * Updates the rolling streak based on the last activity date.
 * Call after a game is completed.
 */
userSchema.methods.updateStreak = function () {
  const now = new Date();
  const last = this.stats.lastActivityDate;
  if (!last) {
    this.stats.currentStreak = 1;
  } else {
    const daysDiff = Math.floor((now - last) / (1000 * 60 * 60 * 24));
    if (daysDiff === 1) {
      this.stats.currentStreak += 1;
    } else if (daysDiff > 1) {
      this.stats.currentStreak = 1;
    }
    // daysDiff === 0: same-day activity, streak unchanged
  }
  if (this.stats.currentStreak > this.stats.longestStreak) {
    this.stats.longestStreak = this.stats.currentStreak;
  }
  this.stats.lastActivityDate = now;
};

// ─────────────────────────────────────────────
//  Query Helpers (chainable scopes)
// ─────────────────────────────────────────────

userSchema.query.active = function () {
  return this.where({ isActive: true, deletedAt: null });
};

userSchema.query.notBanned = function () {
  return this.where({ isBanned: false });
};

// ─────────────────────────────────────────────
//  Model Export
// ─────────────────────────────────────────────

const User = mongoose.model('User', userSchema);

module.exports = User;
