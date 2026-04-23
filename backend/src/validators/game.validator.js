const Joi = require('joi');
const { validate } = require('./auth.validator');

// ─────────────────────────────────────────────
//  Reusable sub-schemas
// ─────────────────────────────────────────────

const locationSchema = Joi.object({
  venueName: Joi.string().trim().max(100),
  address: Joi.string().trim().max(200),
  neighborhood: Joi.string().trim().max(100).required().messages({
    'any.required': 'Neighborhood is required for matchmaking.',
  }),
  city: Joi.string().trim().max(100).required().messages({
    'any.required': 'City is required.',
  }),
  state: Joi.string().trim().max(60),
  country: Joi.string().trim().max(60).default('US'),
  postalCode: Joi.string().trim().max(20),
});

const SPORTS = [
  'football', 'soccer', 'basketball', 'tennis', 'volleyball', 'cricket',
  'badminton', 'table tennis', 'rugby', 'baseball', 'hockey', 'swimming',
  'cycling', 'running', 'gym', 'yoga', 'boxing', 'martial arts', 'golf', 'other',
];

// ─────────────────────────────────────────────
//  Schemas
// ─────────────────────────────────────────────

const createGameSchema = Joi.object({
  title: Joi.string().trim().min(3).max(100).required().messages({
    'any.required': 'Game title is required.',
    'string.min': 'Title must be at least 3 characters.',
  }),
  description: Joi.string().trim().max(1000).allow('', null),
  sport: Joi.string().trim().lowercase().required().messages({
    'any.required': 'Sport type is required.',
  }),
  tags: Joi.array().items(Joi.string().trim().lowercase().max(30)).max(10),
  scheduledAt: Joi.date().iso().greater('now').required().messages({
    'any.required': 'Scheduled date/time is required.',
    'date.greater': 'Game must be scheduled in the future.',
  }),
  durationMinutes: Joi.number().integer().min(15).max(480).required().messages({
    'any.required': 'Duration is required.',
    'number.min': 'Duration must be at least 15 minutes.',
    'number.max': 'Duration cannot exceed 8 hours.',
  }),
  location: locationSchema.required(),
  maxPlayers: Joi.number().integer().min(2).max(100).required().messages({
    'any.required': 'Maximum player count is required.',
  }),
  minPlayersToStart: Joi.number().integer().min(2).default(2),
  requiredSkillLevel: Joi.string()
    .valid('any', 'beginner', 'intermediate', 'advanced', 'professional')
    .default('any'),
  isPrivate: Joi.boolean().default(false),
  requiresApproval: Joi.boolean().default(false),
  allowSpectators: Joi.boolean().default(true),
});

const updateGameSchema = Joi.object({
  title: Joi.string().trim().min(3).max(100),
  description: Joi.string().trim().max(1000).allow('', null),
  tags: Joi.array().items(Joi.string().trim().lowercase().max(30)).max(10),
  scheduledAt: Joi.date().iso().greater('now'),
  durationMinutes: Joi.number().integer().min(15).max(480),
  location: locationSchema,
  maxPlayers: Joi.number().integer().min(2).max(100),
  minPlayersToStart: Joi.number().integer().min(2),
  requiredSkillLevel: Joi.string().valid('any', 'beginner', 'intermediate', 'advanced', 'professional'),
  isPrivate: Joi.boolean(),
  requiresApproval: Joi.boolean(),
  allowSpectators: Joi.boolean(),
}).min(1);

const searchGamesSchema = Joi.object({
  sport: Joi.string().trim().lowercase(),
  city: Joi.string().trim().max(100),
  neighborhood: Joi.string().trim().max(100),
  skillLevel: Joi.string().valid('any', 'beginner', 'intermediate', 'advanced', 'professional'),
  status: Joi.string().valid('open', 'full', 'in_progress', 'completed', 'cancelled').default('open'),
  dateFrom: Joi.date().iso(),
  dateTo: Joi.date().iso().when('dateFrom', { is: Joi.exist(), then: Joi.date().greater(Joi.ref('dateFrom')) }),
  isPrivate: Joi.boolean(),
  q: Joi.string().trim().max(100),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(50).default(20),
  sortBy: Joi.string().valid('scheduledAt', 'createdAt', 'maxPlayers').default('scheduledAt'),
  sortOrder: Joi.string().valid('asc', 'desc').default('asc'),
});

const calendarSchema = Joi.object({
  dateFrom: Joi.date().iso().default(() => new Date()),
  dateTo: Joi.date().iso().default(() => {
    const d = new Date();
    d.setDate(d.getDate() + 30);
    return d;
  }),
});

const completeGameSchema = Joi.object({
  winnerDescription: Joi.string().trim().max(200),
  score: Joi.string().trim().max(50),
  mvpUserId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/).messages({
    'string.pattern.base': 'Invalid MVP user ID.',
  }),
  notes: Joi.string().trim().max(500),
});

const kickPlayerSchema = Joi.object({
  reason: Joi.string().trim().max(300),
});

const mergeSchema = Joi.object({
  expandCapacity: Joi.boolean().default(false),
});

const cancelSchema = Joi.object({
  reason: Joi.string().trim().max(300).required().messages({
    'any.required': 'Cancellation reason is required.',
  }),
});

module.exports = {
  validate,
  createGameSchema,
  updateGameSchema,
  searchGamesSchema,
  calendarSchema,
  completeGameSchema,
  kickPlayerSchema,
  mergeSchema,
  cancelSchema,
  SPORTS,
};
