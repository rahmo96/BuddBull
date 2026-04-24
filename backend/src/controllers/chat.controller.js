const chatService = require('../services/chat.service');
const catchAsync = require('../utils/catchAsync');

exports.getChats = catchAsync(async (req, res) => {
  const chats = await chatService.getChats(req.user._id);
  res.status(200).json({ success: true, data: { chats } });
});

exports.getChatById = catchAsync(async (req, res) => {
  const chat = await chatService.getChatById(req.params.chatId, req.user._id);
  res.status(200).json({ success: true, data: { chat } });
});

exports.createDM = catchAsync(async (req, res) => {
  const chat = await chatService.createOrGetDM(req.user._id, req.body.recipientId);
  res.status(200).json({ success: true, data: { chat } });
});

exports.getMessages = catchAsync(async (req, res) => {
  const messages = await chatService.getMessages(req.params.chatId, req.user._id, req.query);
  res.status(200).json({ success: true, data: { messages } });
});

exports.sendMessage = catchAsync(async (req, res) => {
  const message = await chatService.sendMessage(req.params.chatId, req.user._id, req.body);

  // Broadcast to socket room in real-time (non-blocking)
  const io = req.app.get('io');
  if (io) io.to(req.params.chatId).emit('receive_message', { message });

  res.status(201).json({ success: true, data: { message } });
});

exports.pinMessage = catchAsync(async (req, res) => {
  const message = await chatService.pinMessage(req.params.chatId, req.body.messageId, req.user._id);

  const io = req.app.get('io');
  if (io) io.to(req.params.chatId).emit('message_pinned', { messageId: req.body.messageId });

  res.status(200).json({ success: true, data: { message } });
});

exports.unpinMessage = catchAsync(async (req, res) => {
  await chatService.unpinMessage(req.params.chatId, req.params.messageId, req.user._id);

  const io = req.app.get('io');
  if (io) io.to(req.params.chatId).emit('message_unpinned', { messageId: req.params.messageId });

  res.status(200).json({ success: true, message: 'Message unpinned' });
});

exports.deleteMessage = catchAsync(async (req, res) => {
  const message = await chatService.deleteMessage(req.params.messageId, req.user._id);

  const io = req.app.get('io');
  if (io) io.to(message.chat.toString()).emit('message_deleted', { messageId: req.params.messageId });

  res.status(200).json({ success: true, message: 'Message deleted' });
});

exports.getUnreadCounts = catchAsync(async (req, res) => {
  const counts = await chatService.getUnreadCounts(req.user._id);
  res.status(200).json({ success: true, data: { counts } });
});
