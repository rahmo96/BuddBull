const express = require('express');
const rateLimit = require('express-rate-limit');
const router = express.Router();

const { protect, restrictTo } = require('../middleware/auth.middleware');
const adminController = require('../controllers/admin.controller');
const {
  dashboardQuerySchema,
  userListSchema,
  banUserSchema,
  broadcastSchema,
  sportCategorySchema,
  gameListSchema,
  validate,
} = require('../validators/admin.validator');

// ── All admin routes require authentication + admin role ──────────────────────
router.use(protect, restrictTo('admin'));

// ── Strict rate limiter for admin (prevent scraping) ─────────────────────────
router.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 200,
    standardHeaders: true,
    legacyHeaders: false,
    message: { success: false, message: 'Too many admin requests — slow down.' },
  }),
);

// ── Dashboard ─────────────────────────────────────────────────────────────────
router.get('/dashboard', validate(dashboardQuerySchema, 'query'), adminController.getDashboard);

// ── Users ─────────────────────────────────────────────────────────────────────
router.get('/users', validate(userListSchema, 'query'), adminController.listUsers);
router.patch('/users/:userId/ban', validate(banUserSchema), adminController.banUser);
router.delete('/users/:userId', adminController.deleteUser);

// ── Games ─────────────────────────────────────────────────────────────────────
router.get('/games', validate(gameListSchema, 'query'), adminController.listGames);
router.delete('/games/:gameId', adminController.deleteGame);

// ── Exports ───────────────────────────────────────────────────────────────────
router.get('/export/users', adminController.exportUsers);
router.get('/export/games', adminController.exportGames);

// ── Broadcast ─────────────────────────────────────────────────────────────────
router.post('/broadcast', validate(broadcastSchema), adminController.broadcast);

// ── Sports categories ─────────────────────────────────────────────────────────
router.get('/sports', adminController.getSports);
router.post('/sports', validate(sportCategorySchema), adminController.createSport);
router.patch('/sports/:sportId', validate(sportCategorySchema), adminController.updateSport);
router.delete('/sports/:sportId', adminController.deleteSport);

module.exports = router;
