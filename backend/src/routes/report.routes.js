const express = require('express');

const { protect } = require('../middleware/auth.middleware');
const reportController = require('../controllers/report.controller');
const {
  createReportSchema,
  validate,
} = require('../validators/report.validator');

const router = express.Router();

router.use(protect);

router.post('/', validate(createReportSchema), reportController.create);
router.get('/me', reportController.listMine);

module.exports = router;
