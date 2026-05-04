const Joi = require('joi');
const { validate } = require('./auth.validator');

// ─────────────────────────────────────────────
//  Sub-schemas
// ─────────────────────────────────────────────

const sportStatSchema = Joi.object({
  key: Joi.string().trim().max(50).required(),
  value: Joi.alternatives().try(Joi.number(), Joi.string().max(100)).required(),
  unit: Joi.string().trim().max(20),
});

// ─────────────────────────────────────────────
//  Schemas
// ─────────────────────────────────────────────

const createLogSchema = Joi.object({
  gameId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/).allow(null).messages({
    'string.pattern.base': 'Invalid game ID.',
  }),
  type: Joi.string().valid('match', 'training', 'fitness').required().messages({
    'any.required': 'Log type is required.',
    'any.only': 'Type must be match, training, or fitness.',
  }),
  sport: Joi.string().trim().lowercase().required().messages({
    'any.required': 'Sport is required.',
  }),
  loggedAt: Joi.date().iso().max('now').required().messages({
    'any.required': 'Activity date is required.',
    'date.max': 'Activity date cannot be in the future.',
  }),
  matchOutcome: Joi.string().valid('win', 'loss', 'draw', 'no_result').when('type', {
    is: 'match',
    then: Joi.string().valid('win', 'loss', 'draw', 'no_result'),
  }),
  opponentDescription: Joi.string().trim().max(100).allow('', null),
  durationMinutes: Joi.number().integer().min(1).max(600),
  stats: Joi.array().items(sportStatSchema).max(50),
  physicalMetrics: Joi.object({
    caloriesBurned: Joi.number().min(0).max(10000),
    averageHeartRate: Joi.number().min(0).max(250),
    maxHeartRate: Joi.number().min(0).max(250),
    distanceKm: Joi.number().min(0).max(1000),
    stepsCount: Joi.number().integer().min(0),
    perceivedExertion: Joi.number().integer().min(1).max(10),
  }),
  mood: Joi.string().valid('terrible', 'bad', 'neutral', 'good', 'excellent'),
  selfRating: Joi.number().min(1).max(5),
  notes: Joi.string().trim().max(1000).allow('', null),
  isPublic: Joi.boolean().default(false),
});

const updateLogSchema = Joi.object({
  matchOutcome: Joi.string().valid('win', 'loss', 'draw', 'no_result'),
  durationMinutes: Joi.number().integer().min(1).max(600),
  stats: Joi.array().items(sportStatSchema).max(50),
  physicalMetrics: Joi.object({
    caloriesBurned: Joi.number().min(0),
    averageHeartRate: Joi.number().min(0).max(250),
    maxHeartRate: Joi.number().min(0).max(250),
    distanceKm: Joi.number().min(0),
    stepsCount: Joi.number().integer().min(0),
    perceivedExertion: Joi.number().integer().min(1).max(10),
  }),
  mood: Joi.string().valid('terrible', 'bad', 'neutral', 'good', 'excellent'),
  selfRating: Joi.number().min(1).max(5),
  notes: Joi.string().trim().max(1000).allow('', null),
  isPublic: Joi.boolean(),
}).min(1);

const getLogsSchema = Joi.object({
  sport: Joi.string().trim().lowercase(),
  type: Joi.string().valid('match', 'training', 'fitness'),
  dateFrom: Joi.date().iso(),
  dateTo: Joi.date().iso(),
  matchOutcome: Joi.string().valid('win', 'loss', 'draw', 'no_result'),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
});

const statsQuerySchema = Joi.object({
  dateFrom: Joi.date().iso(),
  dateTo: Joi.date().iso(),
  sport: Joi.string().trim().lowercase(),
});

module.exports = {
  validate,
  createLogSchema,
  updateLogSchema,
  getLogsSchema,
  statsQuerySchema,
};
