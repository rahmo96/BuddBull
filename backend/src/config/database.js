const mongoose = require('mongoose');
const logger = require('../utils/logger');
const { mongoUri, nodeEnv } = require('./environment');

const MAX_RETRIES = 5;
const RETRY_INTERVAL_MS = 5000;

let retryCount = 0;

const mongooseOptions = {
  // Lean connection pool tuned for production throughput
  maxPoolSize: nodeEnv === 'production' ? 20 : 5,
  minPoolSize: 2,
  socketTimeoutMS: 45000,
  serverSelectionTimeoutMS: 10000,
  heartbeatFrequencyMS: 10000,
  // Write concern — ensure data durability
  writeConcern: { w: 'majority', wtimeout: 5000 },
};

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(mongoUri, mongooseOptions);
    retryCount = 0;
    logger.info(`MongoDB connected: ${conn.connection.host} (db: ${conn.connection.name})`);
  } catch (err) {
    retryCount += 1;
    logger.error(`MongoDB connection error (attempt ${retryCount}/${MAX_RETRIES}): ${err.message}`);

    if (retryCount >= MAX_RETRIES) {
      logger.error('Maximum MongoDB connection retries reached. Exiting.');
      process.exit(1);
    }

    logger.info(`Retrying MongoDB connection in ${RETRY_INTERVAL_MS / 1000}s…`);
    setTimeout(connectDB, RETRY_INTERVAL_MS);
  }
};

// Surface connection lifecycle events to the logger
mongoose.connection.on('disconnected', () => logger.warn('MongoDB disconnected'));
mongoose.connection.on('reconnected', () => logger.info('MongoDB reconnected'));
mongoose.connection.on('error', (err) => logger.error(`MongoDB error: ${err.message}`));

// Graceful shutdown on SIGINT / SIGTERM
const gracefulDisconnect = async (signal) => {
  logger.info(`${signal} received — closing MongoDB connection gracefully`);
  await mongoose.connection.close();
  process.exit(0);
};

process.on('SIGINT', () => gracefulDisconnect('SIGINT'));
process.on('SIGTERM', () => gracefulDisconnect('SIGTERM'));

module.exports = connectDB;
