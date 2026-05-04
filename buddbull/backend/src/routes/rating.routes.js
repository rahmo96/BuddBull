const express = require('express');
const router = express.Router();

const { protect } = require('../middleware/auth.middleware');
const ratingController = require('../controllers/rating.controller');
const { ratePlayerSchema, getRatingsSchema, validate } = require('../validators/rating.validator');

router.use(protect);

// ── Create / update a rating ───────────────────────────────────────────────────
router.post('/', validate(ratePlayerSchema), ratingController.ratePlayer);

// ── My pending ratings (games where I haven't rated opponents yet) ─────────────
router.get('/pending', ratingController.getPendingRatings);

// ── My received ratings ────────────────────────────────────────────────────────
router.get('/received', validate(getRatingsSchema, 'query'), ratingController.getMyReceivedRatings);

// ── My given ratings ───────────────────────────────────────────────────────────
router.get('/given', validate(getRatingsSchema, 'query'), ratingController.getMyGivenRatings);

// ── Public rating summary for any user's profile ──────────────────────────────
router.get('/summary/:userId', ratingController.getProfileSummary);

module.exports = router;
