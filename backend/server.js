/**
 * BuddBull — HTTP server entry point.
 *
 * Responsibilities:
 *  1. Load environment variables (must happen before any other import)
 *  2. Connect to MongoDB
 *  3. Create the Express app
 *  4. Attach Socket.io (wired in Phase 6)
 *  5. Start listening
 */

require('dotenv').config();

const http = require('http');
const { Server: SocketIOServer } = require('socket.io');

const connectDB = require('./src/config/database');
const createApp = require('./src/app');
const logger = require('./src/utils/logger');
const registerSocketHandlers = require('./src/socket/socket.manager');
const { port, nodeEnv, clientUrl } = require('./src/config/environment');

const startServer = async () => {
  // ── 1. Database ────────────────────────────────────────────
  await connectDB();

  // ── 2. Express app ─────────────────────────────────────────
  const app = createApp();

  // ── 3. HTTP server ─────────────────────────────────────────
  const server = http.createServer(app);

  // ── 4. Socket.io (stub — fully wired in Phase 6) ───────────
  const io = new SocketIOServer(server, {
    cors: {
      origin: [clientUrl, 'http://localhost:3000'],
      methods: ['GET', 'POST'],
      credentials: true,
    },
    pingTimeout: 60000,
    pingInterval: 25000,
  });

  // Make io accessible inside route handlers via req.app.get('io')
  app.set('io', io);

  // ── 4b. Register all socket event handlers (Phase 6) ──────────
  registerSocketHandlers(io);

  // ── 5. Listen ───────────────────────────────────────────────
  server.listen(port, () => {
    logger.info(`BuddBull API  [${nodeEnv}]  →  http://localhost:${port}`);
    logger.info(`Health check →  http://localhost:${port}/health`);
  });

  // ── Unhandled promise rejections ────────────────────────────
  process.on('unhandledRejection', (reason) => {
    logger.error(`Unhandled Rejection: ${reason}`);
    server.close(() => process.exit(1));
  });

  process.on('uncaughtException', (err) => {
    logger.error(`Uncaught Exception: ${err.message}\n${err.stack}`);
    process.exit(1);
  });
};

startServer();
