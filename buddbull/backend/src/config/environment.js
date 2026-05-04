const Joi = require('joi');

/**
 * Validates all required environment variables at startup.
 * The application will refuse to start if critical vars are missing,
 * preventing silent misconfigurations in production.
 */
const envSchema = Joi.object({
  NODE_ENV: Joi.string().valid('development', 'test', 'production').default('development'),
  PORT: Joi.number().integer().min(1024).max(65535).default(5000),

  MONGO_URI: Joi.string().uri().required(),

  JWT_SECRET: Joi.string().min(32).required(),
  JWT_EXPIRES_IN: Joi.string().default('7d'),
  JWT_REFRESH_SECRET: Joi.string().min(32).required(),
  JWT_REFRESH_EXPIRES_IN: Joi.string().default('30d'),

  BCRYPT_SALT_ROUNDS: Joi.number().integer().min(10).max(14).default(12),

  EMAIL_HOST: Joi.string().required(),
  EMAIL_PORT: Joi.number().integer().default(587),
  EMAIL_SECURE: Joi.boolean().default(false),
  EMAIL_USER: Joi.string().required(),
  EMAIL_PASS: Joi.string().required(),
  EMAIL_FROM: Joi.string().default('BuddBull <noreply@buddbull.app>'),

  UPLOAD_DRIVER: Joi.string().valid('local', 's3').default('local'),
  UPLOAD_DIR: Joi.string().default('uploads/'),

  RATE_LIMIT_WINDOW_MS: Joi.number().integer().default(15 * 60 * 1000),
  RATE_LIMIT_MAX: Joi.number().integer().default(100),

  CLIENT_URL: Joi.string().uri().default('http://localhost:3000'),
})
  .unknown(true) // allow extra keys (AWS_, FIREBASE_, SENTRY_DSN, etc.)
  .required();

const { error, value: env } = envSchema.validate(process.env);

if (error) {
  throw new Error(`Environment validation failed: ${error.message}`);
}

module.exports = {
  nodeEnv: env.NODE_ENV,
  port: env.PORT,
  mongoUri: env.MONGO_URI,
  jwt: {
    secret: env.JWT_SECRET,
    expiresIn: env.JWT_EXPIRES_IN,
    refreshSecret: env.JWT_REFRESH_SECRET,
    refreshExpiresIn: env.JWT_REFRESH_EXPIRES_IN,
  },
  bcryptSaltRounds: Number(env.BCRYPT_SALT_ROUNDS),
  email: {
    host: env.EMAIL_HOST,
    port: Number(env.EMAIL_PORT),
    secure: env.EMAIL_SECURE === 'true',
    user: env.EMAIL_USER,
    pass: env.EMAIL_PASS,
    from: env.EMAIL_FROM,
  },
  upload: {
    driver: env.UPLOAD_DRIVER,
    dir: env.UPLOAD_DIR,
  },
  rateLimit: {
    windowMs: Number(env.RATE_LIMIT_WINDOW_MS),
    max: Number(env.RATE_LIMIT_MAX),
  },
  clientUrl: env.CLIENT_URL,
};
