const Chat = require('../models/Chat.model');
const Message = require('../models/Message.model');
const User = require('../models/User.model');
const AppError = require('../utils/AppError');

// ── Helpers ───────────────────────────────────────────────────────────────────
const PARTICIPANT_FIELDS = 'firstName lastName username profilePicture';
const SENDER_FIELDS = 'firstName lastName username profilePicture';

const participantFilter = (userId) => ({
  'participants.user': userId,
  isDeleted: false,
});

// ── Get all chats for a user ──────────────────────────────────────────────────
const getChats = async (userId) => {
  const chats = await Chat.find(participantFilter(userId))
    .populate('participants.user', PARTICIPANT_FIELDS)
    .populate('game', 'title sport scheduledAt')
    .sort({ 'lastMessage.sentAt': -1, updatedAt: -1 })
    .lean();

  return chats.map((c) => _formatChat(c, userId));
};

// ── Get a single chat ─────────────────────────────────────────────────────────
const getChatById = async (chatId, userId) => {
  const chat = await Chat.findOne({ _id: chatId, ...participantFilter(userId) })
    .populate('participants.user', PARTICIPANT_FIELDS)
    .populate('game', 'title sport scheduledAt')
    .populate({
      path: 'pinnedMessages',
      populate: { path: 'sender', select: SENDER_FIELDS },
      select: 'content type sender createdAt',
    })
    .lean();

  if (!chat) throw new AppError('Chat not found or access denied', 404);

  // Mark messages as read
  await Chat.updateOne(
    { _id: chatId, 'participants.user': userId },
    { $set: { 'participants.$.lastReadAt': new Date() } },
  );

  return _formatChat(chat, userId);
};

// ── Create / find a DM between two users ─────────────────────────────────────
const createOrGetDM = async (userId, recipientId) => {
  if (userId.toString() === recipientId.toString()) {
    throw new AppError('Cannot create a DM with yourself', 400);
  }

  const recipient = await User.findById(recipientId).select('_id isActive isDeleted');
  if (!recipient || !recipient.isActive || recipient.isDeleted) {
    throw new AppError('User not found', 404);
  }

  const chat = await Chat.findOrCreateDM(userId, recipientId);
  await chat.populate('participants.user', PARTICIPANT_FIELDS);
  return _formatChat(chat.toObject(), userId);
};

// ── Get paginated messages for a chat ─────────────────────────────────────────
const getMessages = async (chatId, userId, { page = 1, limit = 30, before } = {}) => {
  const chat = await Chat.findOne({ _id: chatId, ...participantFilter(userId) });
  if (!chat) throw new AppError('Chat not found or access denied', 404);

  const filter = { chat: chatId, isDeleted: false };
  if (before) filter.createdAt = { $lt: new Date(before) };

  const messages = await Message.find(filter)
    .populate('sender', SENDER_FIELDS)
    .populate({
      path: 'replyTo',
      select: 'content sender type',
      populate: { path: 'sender', select: 'firstName lastName username' },
    })
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .lean();

  // Return in chronological order
  return messages.reverse().map(_formatMessage);
};

// ── Send a message (HTTP fallback — real-time uses socket) ────────────────────
const sendMessage = async (chatId, userId, { content, type = 'text', replyTo } = {}) => {
  const chat = await Chat.findOne({ _id: chatId, ...participantFilter(userId) });
  if (!chat) throw new AppError('Chat not found or access denied', 404);

  const message = await Message.create({
    chat: chatId,
    sender: userId,
    type,
    content,
    ...(replyTo && { replyTo }),
  });

  await Chat.findByIdAndUpdate(chatId, {
    lastMessage: { sender: userId, content: type === 'text' ? content : `[${type}]`, sentAt: new Date() },
    $inc: { messageCount: 1 },
  });

  await message.populate([
    { path: 'sender', select: SENDER_FIELDS },
    { path: 'replyTo', select: 'content sender', populate: { path: 'sender', select: 'firstName lastName username' } },
  ]);

  return _formatMessage(message.toObject());
};

// ── Pin a message ─────────────────────────────────────────────────────────────
const pinMessage = async (chatId, messageId, userId) => {
  const chat = await Chat.findOne({ _id: chatId, ...participantFilter(userId) });
  if (!chat) throw new AppError('Chat not found or access denied', 404);

  const participant = chat.participants.find((p) => p.user.toString() === userId.toString());
  if (!participant?.isAdmin) throw new AppError('Only admins can pin messages', 403);

  const message = await Message.findOne({ _id: messageId, chat: chatId, isDeleted: false });
  if (!message) throw new AppError('Message not found', 404);

  message.isPinned = true;
  await message.save();

  await Chat.findByIdAndUpdate(chatId, { $addToSet: { pinnedMessages: messageId } });
  return message;
};

// ── Unpin a message ───────────────────────────────────────────────────────────
const unpinMessage = async (chatId, messageId, userId) => {
  const chat = await Chat.findOne({ _id: chatId, ...participantFilter(userId) });
  if (!chat) throw new AppError('Chat not found or access denied', 404);

  const participant = chat.participants.find((p) => p.user.toString() === userId.toString());
  if (!participant?.isAdmin) throw new AppError('Only admins can unpin messages', 403);

  await Message.findByIdAndUpdate(messageId, { isPinned: false });
  await Chat.findByIdAndUpdate(chatId, { $pull: { pinnedMessages: messageId } });
};

// ── Delete a message ──────────────────────────────────────────────────────────
const deleteMessage = async (messageId, userId) => {
  const message = await Message.findOne({ _id: messageId, isDeleted: false });
  if (!message) throw new AppError('Message not found', 404);
  if (message.sender.toString() !== userId.toString()) {
    throw new AppError('You can only delete your own messages', 403);
  }
  await message.softDelete(userId);
  return message;
};

// ── Get unread count per chat ─────────────────────────────────────────────────
const getUnreadCounts = async (userId) => {
  const chats = await Chat.find(participantFilter(userId)).lean();
  const counts = {};
  for (const chat of chats) {
    const participant = chat.participants.find((p) => p.user.toString() === userId.toString());
    if (!participant) continue;
    const lastRead = participant.lastReadAt || new Date(0);
    // eslint-disable-next-line no-await-in-loop
    const count = await Message.countDocuments({
      chat: chat._id,
      createdAt: { $gt: lastRead },
      sender: { $ne: userId },
      isDeleted: false,
    });
    counts[chat._id.toString()] = count;
  }
  return counts;
};

// ── Formatters ────────────────────────────────────────────────────────────────
const _formatChat = (chat, userId) => {
  const participant = (chat.participants || []).find(
    (p) => (p.user?._id || p.user)?.toString() === userId.toString(),
  );
  return {
    ...chat,
    lastReadAt: participant?.lastReadAt,
    isMuted: participant?.isMuted || false,
    isAdmin: participant?.isAdmin || false,
  };
};

const _formatMessage = (msg) => ({
  id: msg._id,
  chatId: msg.chat,
  sender: msg.sender,
  type: msg.type,
  content: msg.isDeleted ? '[Message deleted]' : msg.content,
  replyTo: msg.replyTo || null,
  reactions: msg.reactions ? Object.fromEntries(msg.reactions) : {},
  isPinned: msg.isPinned,
  isDeleted: msg.isDeleted,
  sentAt: msg.createdAt,
  isEdited: msg.isEdited || false,
});

module.exports = { getChats, getChatById, createOrGetDM, getMessages, sendMessage, pinMessage, unpinMessage, deleteMessage, getUnreadCounts };
