/**
 * Jest setupFile — runs in every test worker BEFORE any test module is imported.
 * Loads .env.test when present and applies safe CI defaults when variables are absent.
 */

const path = require('path');

require('dotenv').config({ path: path.resolve(__dirname, '../../.env.test') });

// Ensure mongodb-memory-server uses a pinned binary cache key (see README / jest.config).
process.env.MONGOMS_VERSION = process.env.MONGOMS_VERSION || '6.0.12';

/** Placeholder URIs satisfy Joi URI checks; mongoose never connects until testDb swaps to memory URI. */
const defaults = {
  NODE_ENV: 'test',
  MONGO_URI: 'mongodb://127.0.0.1:27017/buddbull-test-placeholder',
  JWT_SECRET: 'jest-jwt-secret-32chars-min______',
  JWT_REFRESH_SECRET: 'jest-refresh-secret-32chars-min__',
  EMAIL_HOST: 'smtp.test.local',
  EMAIL_USER: 'test@test.local',
  EMAIL_PASS: 'test',
  EMAIL_FROM: 'jest <noreply@test.local>',
  CLIENT_URL: 'http://localhost:3000',
  GOOGLE_MAPS_API_KEY: '',
  RATE_LIMIT_WINDOW_MS: '60000',
  RATE_LIMIT_MAX: '100000',
};

Object.keys(defaults).forEach((key) => {
  if (process.env[key] === undefined || process.env[key] === '') {
    process.env[key] = defaults[key];
  }
});
