/**
 * BuddBull — Socket.io event manager (Phase 6)
 *
 * Events (client → server):
 *   join_chat       { chatId }
 *   leave_chat      { chatId }
 *   send_message    { chatId, content, type?, replyTo? }
 *   typing          { chatId }
 *   stop_typing     { chatId }
 *   pin_message     { chatId, messageId }
 *   delete_message  { messageId }
 *
 * Events (server → client):
 *   joined_chat     { chatId }
 *   receive_message { message }
 *   message_pinned  { messageId }
 *   message_unpinned{ messageId }
 *   message_deleted { messageId }
 *   typing          { userId, username, chatId }
 *   stop_typing     { userId, chatId }
 *   error           { message }
 */

const jwt = require('jsonwebtoken');

const User = require('../models/User.model');
const Chat = require('../models/Chat.model');
const Message = require('../models/Message.model');
const logger = require('../utils/logger');

const SENDER_FIELDS = 'firstName lastName username profilePicture';

// ── Auth middleware for socket connections ─────────────────────────────────────
const socketAuthMiddleware = async (socket, next) => {
  try {
    const token =
      socket.handshake.auth?.token ||
      socket.handshake.headers?.authorization?.replace('Bearer ', '');

    if (!token) return next(new Error('Authentication required'));

    const decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET);

    const user = await User.findById(decoded.userId)
      .select('_id firstName lastName username profilePicture isActive isDeleted')
      .lean();

    if (!user || !user.isActive || user.isDeleted) {
      return next(new Error('User not found or inactive'));
    }

    // Attach user to socket for use in event handlers
    socket.user = user;
    return next();
  } catch {
    return next(new Error('Invalid or expired token'));
  }
};

// ── Helper: check participation ────────────────────────────────────────────────
const getChat = async (chatId, userId) =>
  Chat.findOne({ _id: chatId, 'participants.user': userId, isDeleted: false });

// ── Main initialiser — call with the io instance ───────────────────────────────
module.exports = (io) => {
  // Apply auth to all sockets before connect
  io.use(socketAuthMiddleware);

  io.on('connection', (socket) => {
    const { user } = socket;
    logger.info(`[Socket] connected  user=${user.username}  id=${socket.id}`);

    // ── join_chat ────────────────────────────────────────────────────────────
    socket.on('join_chat', async ({ chatId } = {}) => {
      try {
        const chat = await getChat(chatId, user._id);
        if (!chat) return socket.emit('error', { message: 'Chat not found' });

        socket.join(chatId);
        socket.emit('joined_chat', { chatId });
        logger.debug(`[Socket] ${user.username} joined chat ${chatId}`);
      } catch (err) {
        logger.error('[Socket] join_chat error:', err);
        socket.emit('error', { message: 'Failed to join chat' });
      }
    });

    // ── leave_chat ───────────────────────────────────────────────────────────
    socket.on('leave_chat', ({ chatId } = {}) => {
      if (chatId) {
        socket.leave(chatId);
        logger.debug(`[Socket] ${user.username} left chat ${chatId}`);
      }
    });

    // ── send_message ─────────────────────────────────────────────────────────
    socket.on('send_message', async ({ chatId, content, type = 'text', replyTo } = {}) => {
      try {
        if (!chatId) return socket.emit('error', { message: 'chatId is required' });
        if (type === 'text' && !content?.trim()) {
          return socket.emit('error', { message: 'Message content is required' });
        }

        const chat = await getChat(chatId, user._id);
        if (!chat) return socket.emit('error', { message: 'Chat not found' });

        const message = await Message.create({
          chat: chatId,
          sender: user._id,
          type,
          content: content?.trim() || '',
          ...(replyTo && { replyTo }),
        });

        await Chat.findByIdAndUpdate(chatId, {
          lastMessage: {
            sender: user._id,
            content: type === 'text' ? content.trim() : `[${type}]`,
            sentAt: new Date(),
          },
          $inc: { messageCount: 1 },
        });

        await message.populate([
          { path: 'sender', select: SENDER_FIELDS },
          {
            path: 'replyTo',
            select: 'content sender type',
            populate: { path: 'sender', select: 'firstName lastName username' },
          },
        ]);

        io.to(chatId).emit('receive_message', { message });
      } catch (err) {
        logger.error('[Socket] send_message error:', err);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // ── typing / stop_typing ─────────────────────────────────────────────────
    socket.on('typing', ({ chatId } = {}) => {
      if (!chatId) return;
      socket.to(chatId).emit('typing', {
        userId: user._id,
        username: user.username,
        chatId,
      });
    });

    socket.on('stop_typing', ({ chatId } = {}) => {
      if (!chatId) return;
      socket.to(chatId).emit('stop_typing', { userId: user._id, chatId });
    });

    // ── pin_message ──────────────────────────────────────────────────────────
    socket.on('pin_message', async ({ chatId, messageId } = {}) => {
      try {
        if (!chatId || !messageId) return socket.emit('error', { message: 'chatId and messageId are required' });

        const chat = await getChat(chatId, user._id);
        if (!chat) return socket.emit('error', { message: 'Chat not found' });

        const participant = chat.participants.find(
          (p) => p.user.toString() === user._id.toString(),
        );
        if (!participant?.isAdmin) {
          return socket.emit('error', { message: 'Only admins can pin messages' });
        }

        const message = await Message.findOne({ _id: messageId, chat: chatId, isDeleted: false });
        if (!message) return socket.emit('error', { message: 'Message not found' });

        message.isPinned = true;
        await message.save();
        await Chat.findByIdAndUpdate(chatId, { $addToSet: { pinnedMessages: messageId } });

        io.to(chatId).emit('message_pinned', { messageId });
      } catch (err) {
        logger.error('[Socket] pin_message error:', err);
        socket.emit('error', { message: 'Failed to pin message' });
      }
    });

    // ── delete_message ───────────────────────────────────────────────────────
    socket.on('delete_message', async ({ messageId } = {}) => {
      try {
        if (!messageId) return socket.emit('error', { message: 'messageId is required' });

        const message = await Message.findOne({ _id: messageId, isDeleted: false });
        if (!message) return socket.emit('error', { message: 'Message not found' });

        if (message.sender.toString() !== user._id.toString()) {
          return socket.emit('error', { message: "Cannot delete another user's message" });
        }

        await message.softDelete(user._id);
        io.to(message.chat.toString()).emit('message_deleted', { messageId });
      } catch (err) {
        logger.error('[Socket] delete_message error:', err);
        socket.emit('error', { message: 'Failed to delete message' });
      }
    });

    // ── disconnect ───────────────────────────────────────────────────────────
    socket.on('disconnect', (reason) => {
      logger.info(`[Socket] disconnected  user=${user.username}  reason=${reason}`);
    });
  });
};
