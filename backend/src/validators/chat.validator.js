const Joi = require('joi');

const mongoId = Joi.string()
  .regex(/^[0-9a-fA-F]{24}$/)
  .messages({ 'string.pattern.base': 'Invalid ID format' });

// ── Schemas ───────────────────────────────────────────────────────────────────
const sendMessageSchema = Joi.object({
  content: Joi.string().trim().max(5000).when('type', {
    is: Joi.valid('image', 'video', 'file'),
    then: Joi.optional().allow(''),
    otherwise: Joi.required(),
  }),
  type: Joi.string().valid('text', 'image', 'video', 'file').default('text'),
  replyTo: mongoId.optional(),
});

const createDMSchema = Joi.object({
  recipientId: mongoId.required(),
});

const pinMessageSchema = Joi.object({
  messageId: mongoId.required(),
});

const getMessagesSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(50).default(30),
  before: Joi.string().isoDate().optional(),
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

module.exports = { sendMessageSchema, createDMSchema, pinMessageSchema, getMessagesSchema, validate };
