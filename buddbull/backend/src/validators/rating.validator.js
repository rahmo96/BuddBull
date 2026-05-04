const Joi = require('joi');

const mongoId = Joi.string()
  .regex(/^[0-9a-fA-F]{24}$/)
  .messages({ 'string.pattern.base': 'Invalid ID format' });

const score = Joi.number().integer().min(1).max(5);

const ratePlayerSchema = Joi.object({
  rateeId: mongoId.required(),
  gameId: mongoId.required(),
  reliabilityScore: score.required(),
  behaviorScore: score.required(),
  comment: Joi.string().trim().max(500).optional().allow(''),
  isAnonymous: Joi.boolean().default(false),
});

const getRatingsSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(50).default(20),
});

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

module.exports = { ratePlayerSchema, getRatingsSchema, validate };
