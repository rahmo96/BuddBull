const Joi = require('joi');

// ─────────────────────────────────────────────
//  Reusable field rules
// ─────────────────────────────────────────────

const password = Joi.string()
  .min(6)
  .max(128)
  .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, 'strong')
  .messages({
    'string.min': 'Password must be at least 6 characters long.',
    'string.max': 'Password cannot exceed 128 characters.',
    'string.pattern.name': 'Password must contain at least one uppercase letter, one lowercase letter, and one number.',
  });

const email = Joi.string()
  .email({ tlds: { allow: true } })
  .lowercase()
  .trim()
  .max(254)
  .messages({
    'string.email': 'Please provide a valid email address.',
  });

// ─────────────────────────────────────────────
//  Schemas
// ─────────────────────────────────────────────

const registerSchema = Joi.object({
  firstName: Joi.string().trim().min(2).max(50).required().messages({
    'string.min': 'First name must be at least 2 characters.',
    'any.required': 'First name is required.',
  }),
  lastName: Joi.string().trim().min(2).max(50).required().messages({
    'string.min': 'Last name must be at least 2 characters.',
    'any.required': 'Last name is required.',
  }),
  username: Joi.string()
    .trim()
    .lowercase()
    .min(3)
    .max(30)
    .pattern(/^[a-z0-9_.-]+$/)
    .required()
    .messages({
      'string.pattern.base': 'Username may only contain lowercase letters, numbers, underscores, dots, or hyphens.',
      'string.min': 'Username must be at least 3 characters.',
      'any.required': 'Username is required.',
    }),
  email: email.required(),
  password: password.required(),
  role: Joi.string().valid('player', 'organizer').default('player'),
});

const loginSchema = Joi.object({
  email: email.required(),
  password: Joi.string().required().messages({
    'any.required': 'Password is required.',
  }),
});

const forgotPasswordSchema = Joi.object({
  email: email.required(),
});

const resetPasswordSchema = Joi.object({
  password: password.required(),
  passwordConfirm: Joi.any()
    .equal(Joi.ref('password'))
    .required()
    .messages({ 'any.only': 'Passwords do not match.' }),
});

const changePasswordSchema = Joi.object({
  currentPassword: Joi.string().required().messages({
    'any.required': 'Current password is required.',
  }),
  newPassword: password.required().disallow(Joi.ref('currentPassword')).messages({
    'any.invalid': 'New password must be different from your current password.',
  }),
  newPasswordConfirm: Joi.any()
    .equal(Joi.ref('newPassword'))
    .required()
    .messages({ 'any.only': 'Passwords do not match.' }),
});

const refreshTokenSchema = Joi.object({
  // Refresh token can come from body OR cookie — body is optional here
  refreshToken: Joi.string().optional(),
});

// ─────────────────────────────────────────────
//  Validation middleware factory
// ─────────────────────────────────────────────

/**
 * Returns Express middleware that validates req.body (default) or req.query
 * against a Joi schema. On failure, passes a structured 422 error to the
 * error handler.
 *
 * @param {Joi.Schema} schema
 * @param {'body'|'query'} target  Defaults to 'body'
 */
const validate = (schema, target = 'body') => (req, res, next) => {
  const source = target === 'query' ? req.query : req.body;

  const { error, value } = schema.validate(source, {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    const details = error.details.map((d) => ({
      field: d.path.join('.'),
      message: d.message,
    }));
    return res.status(422).json({
      success: false,
      message: 'Validation failed',
      errors: details,
    });
  }

  if (target === 'query') {
    req.query = value;
  } else {
    req.body = value;
  }
  return next();
};

module.exports = {
  validate,
  registerSchema,
  loginSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  changePasswordSchema,
  refreshTokenSchema,
};
