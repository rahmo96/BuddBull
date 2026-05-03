/**
 * Jest global setup — runs once in the main Jest process before any
 * test suites or workers are spawned.
 *
 * Setting MONGOMS_VERSION here is only for documentation / safety;
 * the authoritative location is jest.config.js (top-level process.env
 * assignment), which runs before any worker is forked.
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env.test') });

module.exports = async () => {
  process.env.NODE_ENV = 'test';
  process.env.MONGOMS_VERSION = '6.0.12';
};
