const Joi = require('joi');

const mongoId = Joi.string()
  .regex(/^[0-9a-fA-F]{24}$/)
  .messages({ 'string.pattern.base': 'Invalid ID format' });

const createReportSchema = Joi.object({
  targetType: Joi.string().valid('user', 'game').required(),
  reportedUserId: mongoId.when('targetType', {
    is: 'user',
    then: Joi.required(),
    otherwise: Joi.optional().allow(null),
  }),
  reportedGameId: mongoId.when('targetType', {
    is: 'game',
    then: Joi.required(),
    otherwise: Joi.optional().allow(null),
  }),
  title: Joi.string().trim().min(1).max(120).required(),
  reason: Joi.string().trim().min(1).max(2000).required(),
  category: Joi.string().valid('harassment', 'unsafe_play', 'cheating', 'other').optional(),
});

const reportListSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  status: Joi.string().valid('open', 'in_progress', 'closed').optional(),
  targetType: Joi.string().valid('user', 'game').optional(),
  sort: Joi.string().valid('createdAt', '-createdAt').default('-createdAt'),
});

const updateReportSchema = Joi.object({
  status: Joi.string().valid('open', 'in_progress', 'closed').optional(),
  adminNotes: Joi.string().trim().max(2000).optional().allow(''),
}).min(1);

const validate =
  (schema, source = 'body') =>
    (req, res, next) => {
      const { error, value } = schema.validate(req[source], {
        abortEarly: false,
        stripUnknown: true,
      });
      if (error) {
        const messages = error.details.map((d) => d.message).join('; ');
        return res.status(400).json({ success: false, message: messages });
      }
      req[source] = value;
      return next();
    };

module.exports = {
  createReportSchema,
  reportListSchema,
  updateReportSchema,
  validate,
};
