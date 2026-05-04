const express = require('express');
const router = express.Router();

const { protect } = require('../middleware/auth.middleware');
const chatController = require('../controllers/chat.controller');
const {
  sendMessageSchema,
  createDMSchema,
  pinMessageSchema,
  getMessagesSchema,
  validate,
} = require('../validators/chat.validator');

// All chat routes require authentication
router.use(protect);

// ── Chat list ──────────────────────────────────────────────────────────────────
router.get('/', chatController.getChats);
router.get('/unread', chatController.getUnreadCounts);
router.post('/dm', validate(createDMSchema), chatController.createDM);

// ── Single chat ────────────────────────────────────────────────────────────────
router.get('/:chatId', chatController.getChatById);

// ── Messages ───────────────────────────────────────────────────────────────────
router.get('/:chatId/messages', validate(getMessagesSchema, 'query'), chatController.getMessages);
router.post('/:chatId/messages', validate(sendMessageSchema), chatController.sendMessage);
router.delete('/:chatId/messages/:messageId', chatController.deleteMessage);

// ── Pins ───────────────────────────────────────────────────────────────────────
router.post('/:chatId/pin', validate(pinMessageSchema), chatController.pinMessage);
router.delete('/:chatId/pin/:messageId', chatController.unpinMessage);

module.exports = router;
