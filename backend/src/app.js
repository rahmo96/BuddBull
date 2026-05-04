const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const cookieParser = require('cookie-parser');
const mongoSanitize = require('express-mongo-sanitize');
const { xss } = require('express-xss-sanitizer');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const path = require('path');

const errorHandler = require('./middleware/errorHandler');
const notFound = require('./middleware/notFound');
const logger = require('./utils/logger');
const { clientUrl, rateLimit: rateLimitConfig, nodeEnv, upload } = require('./config/environment');

// ── Route imports ─────────────────────────────────────────────
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const gameRoutes = require('./routes/game.routes');
const performanceRoutes = require('./routes/performance.routes');
const chatRoutes = require('./routes/chat.routes');
const ratingRoutes = require('./routes/rating.routes');
const adminRoutes = require('./routes/admin.routes');

const createApp = () => {
  const app = express();

  // ── Trust proxy (required when behind nginx / load balancer) ─
  app.set('trust proxy', 1);

  // ── Security headers ─────────────────────────────────────────
  app.use(helmet());

  // ── CORS ──────────────────────────────────────────────────────
  app.use(
    cors({
      origin: (origin, callback) => {
        const allowedOrigins = [clientUrl, 'http://localhost:3000', 'http://localhost:8080'];
        // Allow mobile apps that have no origin header
        if (!origin || allowedOrigins.includes(origin)) return callback(null, true);
        return callback(new Error(`CORS policy violation: ${origin}`));
      },
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    }),
  );

  // ── HTTP request logger ───────────────────────────────────────
  if (nodeEnv !== 'test') {
    app.use(
      morgan('combined', {
        stream: { write: (msg) => logger.http(msg.trim()) },
        skip: (req) => req.url === '/health',
      }),
    );
  }

  // ── Body parsing & cookies ────────────────────────────────────
  app.use(express.json({ limit: '10kb' }));
  app.use(express.urlencoded({ extended: true, limit: '10kb' }));
  app.use(cookieParser());

  // ── Data sanitisation: prevent NoSQL injection ────────────────
  app.use(mongoSanitize());

  // ── XSS sanitisation ──────────────────────────────────────────
  app.use(xss());

  // ── Response compression ─────────────────────────────────────
  app.use(compression());

  // ── Global rate limiter ───────────────────────────────────────
  app.use(
    '/api/',
    rateLimit({
      windowMs: rateLimitConfig.windowMs,
      max: rateLimitConfig.max,
      standardHeaders: true,
      legacyHeaders: false,
      message: {
        success: false,
        message: 'Too many requests — please try again later.',
      },
    }),
  );

  // ── Static file serving (local profile pictures) ─────────────
  app.use('/uploads', express.static(path.join(process.cwd(), upload.dir)));

  // ── Health check (unauthenticated, excluded from rate limit) ──
  app.get('/health', (req, res) =>
    res.status(200).json({
      success: true,
      message: 'BuddBull API is running',
      environment: nodeEnv,
      timestamp: new Date().toISOString(),
    }),
  );

  // ── API Routes ────────────────────────────────────────────────
  app.use('/api/v1/auth', authRoutes);
  app.use('/api/v1/users', userRoutes);
  app.use('/api/v1/games', gameRoutes);
  app.use('/api/v1/performance', performanceRoutes);
  app.use('/api/v1/chats', chatRoutes);
  app.use('/api/v1/ratings', ratingRoutes);
  app.use('/api/v1/admin', adminRoutes);

  // ── Catch-all 404 ────────────────────────────────────────────
  app.use(notFound);

  // ── Centralised error handler (must be last) ─────────────────
  app.use(errorHandler);

  return app;
};

module.exports = createApp;
