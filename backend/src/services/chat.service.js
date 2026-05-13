const Chat = require('../models/Chat.model');
const Message = require('../models/Message.model');
const User = require('../models/User.model');
const Game = require('../models/Game.model');
const AppError = require('../utils/AppError');
const logger = require('../utils/logger');

// ── Helpers ───────────────────────────────────────────────────────────────────
const PARTICIPANT_FIELDS = 'firstName lastName username profilePicture';
const SENDER_FIELDS = 'firstName lastName username profilePicture';

// `$elemMatch` ties the user-id and active-membership checks to the same
// participant slot. Without it a player whose slot has `leftAt: <date>`
// would still match if any *other* participant has `leftAt: null` — the
// classic dot-path-over-array pitfall. This gates GET /chats, /messages,
// /chats/:id and the chat-read endpoint.
const participantFilter = (userId) => ({
  participants: { $elemMatch: { user: userId, leftAt: null } },
  isActive: true,
  deletedAt: null,
});

/**
 * Resolves a chatId to a real group chat the user may access.
 *
 * Supported fallbacks:
 * - chatId is actually a gameId (client bug)
 * - chat exists but the participant row is missing (older data / join flow)
 * - chatId is a groupChatId but we need to find the owning game via Game.groupChat
 *
 * Returns: { chatId: ObjectId|string } or null
 */
const _resolveChatForUser = async (chatId, userId) => {
  // 1) Standard: find owning game by groupChat = chatId
  let game = await Game.findOne({ groupChat: chatId, deletedAt: null });

  // 2) Or chatId might be the gameId
  if (!game) {
    game = await Game.findById(chatId).where({ deletedAt: null });
  }

  if (!game) {
    logger.debug(`[chat.fallback] no game for chatId=${chatId}`);
    return null;
  }

  const isOrganizer = game.organizer?.toString() === userId.toString();
  const isApprovedPlayer = (game.players || []).some(
    (p) => p.user.toString() === userId.toString() && p.status === 'approved',
  );

  if (!isOrganizer && !isApprovedPlayer) {
    logger.debug('[chat.fallback] user not allowed', { chatId, userId, gameId: game._id.toString() });
    return null;
  }

  // Ensure group chat exists
  if (!game.groupChat) {
    logger.debug('[chat.fallback] creating missing group chat', { gameId: game._id.toString() });
    const created = await Chat.create({
      type: 'group',
      name: `${game.title} — Chat`,
      game: game._id,
      participants: [{ user: game.organizer, isAdmin: true }],
    });
    game.groupChat = created._id;
    await game.save({ validateBeforeSave: false });
  }

  // Ensure requester is a participant
  const updateRes = await Chat.updateOne(
    { _id: game.groupChat, deletedAt: null, 'participants.user': { $ne: userId } },
    { $push: { participants: { user: userId, isAdmin: false, leftAt: null } } },
  );
  if (updateRes?.modifiedCount) {
    logger.debug('[chat.fallback] participant added', { chatId: game.groupChat.toString(), userId: userId.toString() });
  }

  return { chatId: game.groupChat };
};

// ── Get all chats for a user ──────────────────────────────────────────────────
const getChats = async (userId) => {
  const chats = await Chat.find(participantFilter(userId))
    .populate('participants.user', PARTICIPANT_FIELDS)
    .populate('game', 'title sport scheduledAt')
    .sort({ 'lastMessage.sentAt': -1, updatedAt: -1 })
    .lean();

  if (chats.length === 0) return [];

  // Hydrate each chat with the viewer's unread count in one round trip
  // per chat. The chat-list screen needs this for per-row badges, and
  // the bottom-nav badge sums it up — so the alternative (separate
  // `/chats/unread` poll) would double the cold-start cost.
  const counts = await Promise.all(
    chats.map((chat) => {
      const participant = (chat.participants || []).find(
        (p) => (p.user?._id || p.user)?.toString() === userId.toString(),
      );
      const lastRead = participant?.lastReadAt || new Date(0);
      return Message.countDocuments({
        chat: chat._id,
        createdAt: { $gt: lastRead },
        sender: { $ne: userId },
        isDeleted: false,
      });
    }),
  );

  return chats.map((c, i) => ({ ..._formatChat(c, userId), unreadCount: counts[i] }));
};

// ── Get a single chat ─────────────────────────────────────────────────────────
const getChatById = async (chatId, userId) => {
  let chat = await Chat.findOne({ _id: chatId, ...participantFilter(userId) })
    .populate('participants.user', PARTICIPANT_FIELDS)
    .populate('game', 'title sport scheduledAt')
    .populate({
      path: 'pinnedMessages',
      populate: { path: 'sender', select: SENDER_FIELDS },
      select: 'content type sender createdAt',
    })
    .lean();

  // Fallback: some clients send a gameId, or chat exists but participant row is missing.
  if (!chat) {
    const resolved = await _resolveChatForUser(chatId, userId);
    if (resolved?.chatId) {
      // Re-fetch as normal by chat id
      chat = await Chat.findOne({ _id: resolved.chatId, ...participantFilter(userId) })
        .populate('participants.user', PARTICIPANT_FIELDS)
        .populate('game', 'title sport scheduledAt')
        .populate({
          path: 'pinnedMessages',
          populate: { path: 'sender', select: SENDER_FIELDS },
          select: 'content type sender createdAt',
        })
        .lean();
    }
  }

  if (!chat) throw new AppError('Chat not found or access denied', 404);

  // Mark messages as read
  await Chat.updateOne(
    { _id: chat._id, 'participants.user': userId },
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
  let chat = await Chat.findOne({ _id: chatId, ...participantFilter(userId) });
  if (!chat) {
    const resolved = await _resolveChatForUser(chatId, userId);
    if (resolved?.chatId) {
      chat = await Chat.findOne({ _id: resolved.chatId, ...participantFilter(userId) });
    }
  }

  if (!chat) throw new AppError('Chat not found or access denied', 404);

  const filter = { chat: chat._id, isDeleted: false };
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
  const participant = (chat.participants || []).find((p) => (p.user?._id || p.user)?.toString() === userId.toString());
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
  reactions: Object.fromEntries(msg?.reactions instanceof Map ? msg.reactions : Object.entries(msg?.reactions || {})),
  readBy: (msg?.readBy || []).map((r) => (r.user?._id || r.user)?.toString()).filter(Boolean),
  isPinned: msg.isPinned,
  isDeleted: msg.isDeleted,
  sentAt: msg.createdAt,
  isEdited: msg.isEdited || false,
});

module.exports = {
  getChats,
  getChatById,
  createOrGetDM,
  getMessages,
  sendMessage,
  pinMessage,
  unpinMessage,
  deleteMessage,
  getUnreadCounts,
};
