/**
 * Test database helper.
 *
 * Spins up an in-memory MongoDB instance using mongodb-memory-server
 * so tests are completely isolated from real data and require no
 * running MongoDB installation.
 *
 * Usage in test files:
 *   const testDb = require('./helpers/testDb');
 *   beforeAll(testDb.connect);
 *   afterEach(testDb.clearAll);
 *   afterAll(testDb.disconnect);
 */

const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongod;

/**
 * Starts the in-memory server and connects Mongoose.
 */
const connect = async () => {
  mongod = await MongoMemoryServer.create();
  const uri = mongod.getUri();
  await mongoose.connect(uri, { dbName: 'buddbull-test' });
};

/**
 * Drops every collection so each test starts with a clean slate.
 */
const clearAll = async () => {
  const { collections } = mongoose.connection;
  await Promise.all(Object.values(collections).map((col) => col.deleteMany({})));
};

/**
 * Closes the Mongoose connection and stops the in-memory server.
 */
const disconnect = async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.connection.close();
  if (mongod) await mongod.stop();
};

module.exports = { connect, clearAll, disconnect };
