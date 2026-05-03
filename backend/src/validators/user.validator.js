const Joi = require('joi');
const { validate } = require('./auth.validator');

// ─────────────────────────────────────────────
//  Reusable sub-schemas
// ─────────────────────────────────────────────

const sportInterestSchema = Joi.object({
  sport: Joi.string().trim().lowercase().min(2).max(50).required(),
  skillLevel: Joi.string().valid('beginner', 'intermediate', 'advanced', 'professional').default('beginner'),
  preferredPositions: Joi.array().items(Joi.string().trim().max(30)).max(5),
  yearsOfExperience: Joi.number().integer().min(0).max(50),
});

const locationSchema = Joi.object({
  country: Joi.string().trim().max(60),
  state: Joi.string().trim().max(60),
  city: Joi.string().trim().max(100),
  neighborhood: Joi.string().trim().max(100),
  postalCode: Joi.string().trim().max(20),
  radiusKm: Joi.number().integer().min(1).max(200).default(10),
});

const notificationPrefsSchema = Joi.object({
  gameInvites: Joi.boolean(),
  gameReminders: Joi.boolean(),
  gameStarting: Joi.boolean(),
  groupMessages: Joi.boolean(),
  directMessages: Joi.boolean(),
  ratingReceived: Joi.boolean(),
  groupMerges: Joi.boolean(),
  broadcasts: Joi.boolean(),
  recordsBroken: Joi.boolean(),
});

// ─────────────────────────────────────────────
//  Schemas
// ─────────────────────────────────────────────

const updateProfileSchema = Joi.object({
  firstName: Joi.string().trim().min(2).max(50),
  lastName: Joi.string().trim().min(2).max(50),
  bio: Joi.string().trim().max(500).allow('', null),
  dateOfBirth: Joi.date().max('now').iso(),
  gender: Joi.string().valid('male', 'female', 'non-binary', 'prefer_not_to_say'),
  sportsInterests: Joi.array().items(sportInterestSchema).max(10),
  location: locationSchema,
  notificationPreferences: notificationPrefsSchema,
}).min(1); // at least one field must be provided

const updateUsernameSchema = Joi.object({
  username: Joi.string()
    .trim()
    .lowercase()
    .min(3)
    .max(30)
    .pattern(/^[a-z0-9_.-]+$/)
    .required()
    .messages({
      'string.pattern.base': 'Username may only contain lowercase letters, numbers, underscores, dots, or hyphens.',
    }),
});

const searchUsersSchema = Joi.object({
  q: Joi.string().trim().min(1).max(100),
  sport: Joi.string().trim().lowercase(),
  city: Joi.string().trim().max(100),
  skillLevel: Joi.string().valid('beginner', 'intermediate', 'advanced', 'professional'),
  role: Joi.string().valid('player', 'organizer'),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(50).default(20),
});

const addPushTokenSchema = Joi.object({
  token: Joi.string().trim().required(),
  platform: Joi.string().valid('ios', 'android', 'web').required(),
});

// ─────────────────────────────────────────────
//  Param validators (sanitise URL params)
// ─────────────────────────────────────────────

const mongoIdSchema = Joi.string()
  .pattern(/^[0-9a-fA-F]{24}$/)
  .required()
  .messages({ 'string.pattern.base': 'Invalid ID format.' });

const validateMongoId = (paramName) => (req, res, next) => {
  const { error } = mongoIdSchema.validate(req.params[paramName]);
  if (error) {
    return res.status(400).json({ success: false, message: `Invalid ${paramName}: must be a valid MongoDB ObjectId.` });
  }
  return next();
};

module.exports = {
  validate,
  updateProfileSchema,
  updateUsernameSchema,
  searchUsersSchema,
  addPushTokenSchema,
  validateMongoId,
};
