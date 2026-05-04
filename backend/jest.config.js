/**
 * Jest configuration.
 *
 * Key decisions:
 *  - MONGOMS_VERSION is set here (process-level) so it is visible to
 *    every Jest worker before mongodb-memory-server resolves the binary.
 *  - testEnvironment is 'node' since this is a pure Node.js backend.
 *  - testTimeout 120 s covers the FIRST run where the binary must download.
 *    Subsequent runs will be <5 s since the binary is cached at:
 *    %USERPROFILE%\.cache\mongodb-binaries
 */

module.exports = {
  testEnvironment: 'node',
  testTimeout: 120000,
  testMatch: ['**/tests/**/*.test.js', '**/?(*.)+(spec|test).js'],
  collectCoverageFrom: ['src/**/*.js', '!src/config/**'],

  // Runs in each worker BEFORE any test module is imported.
  // This ensures .env.test vars (including MONGO_URI, JWT_SECRET, MONGOMS_VERSION)
  // are available before environment.js Joi validation and mongodb-memory-server init.
  setupFiles: ['<rootDir>/tests/helpers/loadTestEnv.js'],

  globalSetup: './tests/helpers/jestGlobalSetup.js',
};
