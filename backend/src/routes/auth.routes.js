const express = require('express');

const AuthController = require('../controllers/auth.controller');
const { protect } = require('../middleware/auth.middleware');

const router = express.Router();

/**
 * @route  POST /api/v1/auth/sync
 * @desc   Upsert/sync Firebase user into MongoDB
 * @access Private (Firebase ID token required)
 */
router.post('/sync', protect, AuthController.syncUser);

module.exports = router;
