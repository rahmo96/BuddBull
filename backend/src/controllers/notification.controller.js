const inboxService = require('../services/notificationInbox.service');
const catchAsync = require('../utils/catchAsync');

// ─────────────────────────────────────────────
//  Notification Inbox Controller
// ─────────────────────────────────────────────

exports.list = catchAsync(async (req, res) => {
  const result = await inboxService.listForUser(req.user._id, req.query);
  res.status(200).json({ success: true, data: result });
});

exports.markRead = catchAsync(async (req, res) => {
  const notification = await inboxService.markAsRead(req.user._id, req.params.id);
  res.status(200).json({ success: true, data: { notification } });
});

exports.markAllRead = catchAsync(async (req, res) => {
  const result = await inboxService.markAllAsRead(req.user._id);
  res.status(200).json({ success: true, data: result });
});
