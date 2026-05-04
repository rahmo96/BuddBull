/**
 * Jest setupFile — runs in every test worker BEFORE any test module is imported.
 * This ensures .env.test is loaded before environment.js Joi validation fires.
 */
const path = require('path');

require('dotenv').config({ path: path.resolve(__dirname, '../../.env.test') });

// Ensure the memory-server uses MongoDB 6 (smaller binary, ~300 MB vs 777 MB)
process.env.MONGOMS_VERSION = '6.0.12';
