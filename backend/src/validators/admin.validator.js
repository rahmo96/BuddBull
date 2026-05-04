const Joi = require('joi');

const mongoId = Joi.string()
  .regex(/^[0-9a-fA-F]{24}$/)
  .messages({ 'string.pattern.base': 'Invalid ID format' });

// ── Schemas ──────────────────────────────────────────────────────────────────
const dashboardQuerySchema = Joi.object({
  period: Joi.string().valid('7d', '30d', '90d').default('30d'),
});

const userListSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  search: Joi.string().trim().max(100).optional().allow(''),
  role: Joi.string().valid('player', 'organizer', 'admin').optional(),
  status: Joi.string().valid('active', 'banned', 'deleted').optional(),
  sort: Joi.string().valid('createdAt', '-createdAt', 'username', '-username').default('-createdAt'),
});

const banUserSchema = Joi.object({
  reason: Joi.string().trim().max(500).optional().allow(''),
  isBanned: Joi.boolean().required(),
});

const broadcastSchema = Joi.object({
  title: Joi.string().trim().min(1).max(100).required(),
  body: Joi.string().trim().min(1).max(1000).required(),
  channel: Joi.string().valid('socket', 'email', 'both').default('socket'),
});

const sportCategorySchema = Joi.object({
  name: Joi.string().trim().min(1).max(50).required(),
  icon: Joi.string().trim().max(10).optional().default('🏅'),
  color: Joi.string()
    .trim()
    .regex(/^#[0-9A-Fa-f]{6}$/)
    .optional()
    .default('#3B82F6'),
  description: Joi.string().trim().max(200).optional().allow(''),
  isActive: Joi.boolean().optional(),
  sortOrder: Joi.number().integer().optional(),
});

const gameListSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  sport: Joi.string().optional(),
  status: Joi.string().valid('open', 'full', 'cancelled', 'completed').optional(),
  sort: Joi.string().valid('createdAt', '-createdAt', 'scheduledAt', '-scheduledAt').default('-createdAt'),
});

// ── Middleware factory ────────────────────────────────────────────────────────
const validate = (schema, source = 'body') =>
  (req, res, next) => {
    const { error, value } = schema.validate(req[source], { abortEarly: false, stripUnknown: true });
    if (error) {
      const messages = error.details.map((d) => d.message).join('; ');
      return res.status(400).json({ success: false, message: messages });
    }
    req[source] = value;
    return next();
  };

module.exports = {
  dashboardQuerySchema,
  userListSchema,
  banUserSchema,
  broadcastSchema,
  sportCategorySchema,
  gameListSchema,
  validate,
};
