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

const admin = require('firebase-admin');

const User = require('../models/User.model');
const Chat = require('../models/Chat.model');
const Message = require('../models/Message.model');
const logger = require('../utils/logger');
const { toPlainDoc } = require('../utils/toPlainDoc');

const SENDER_FIELDS = 'firstName lastName username profilePicture';

const getFirebaseAuth = () => {
  if (!admin.apps.length) {
    const { FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY } = process.env;
    if (FIREBASE_PROJECT_ID && FIREBASE_CLIENT_EMAIL && FIREBASE_PRIVATE_KEY) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: FIREBASE_PROJECT_ID,
          clientEmail: FIREBASE_CLIENT_EMAIL,
          privateKey: FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
    } else {
      admin.initializeApp({ credential: admin.credential.applicationDefault() });
    }
  }
  return admin.auth();
};

// ── Auth middleware for socket connections ─────────────────────────────────────
const socketAuthMiddleware = async (socket, next) => {
  try {
    const token =
      socket.handshake.auth?.token ||
      socket.handshake.headers?.authorization?.replace('Bearer ', '');

    if (!token) return next(new Error('Authentication required'));

    const decodedToken = await getFirebaseAuth().verifyIdToken(token);

    const user = await User.findOne({ firebaseUid: decodedToken.uid })
      .select('_id firstName lastName username profilePicture isActive deletedAt isBanned banReason')
      .lean();

    if (!user || !user.isActive || user.deletedAt || user.isBanned) {
      return next(new Error('User not found or inactive'));
    }

    // Attach user to socket for use in event handlers.
    // Keep both Mongo _id and Firebase uid for debugging and downstream logic.
    socket.user = { ...user, id: decodedToken.uid, uid: decodedToken.uid };
    return next();
  } catch {
    return next(new Error('Invalid or expired token'));
  }
};

// ── Helper: check participation ────────────────────────────────────────────────
const getChat = async (chatId, userId) =>
  Chat.findOne({ _id: chatId, 'participants.user': userId, isDeleted: false });

/** Room id from client payload: `{ chatId }` object or bare string (legacy). */
const roomIdFromJoinPayload = (data) => {
  const room = data?.chatId ?? data;
  if (room == null || room === '') return null;
  return String(room);
};

// ── Main initialiser — call with the io instance ───────────────────────────────
module.exports = (io) => {
  // Apply auth to all sockets before connect
  io.use(socketAuthMiddleware);

  io.on('connection', (socket) => {
    const { user } = socket;
    logger.info(`[Socket] connected  user=${user.username}  id=${socket.id}`);

    // ── join_chat ────────────────────────────────────────────────────────────
    // Room membership is keyed by chatId string only — no DB lookup required to join
    // the Socket.io room (send_message / HTTP paths still enforce participation).
    socket.on('join_chat', (data) => {
      try {
        const room = roomIdFromJoinPayload(data);
        if (!room) return socket.emit('error', { message: 'chatId is required' });

        socket.join(room);
        socket.emit('joined_chat', { chatId: room });
        logger.debug(`[Socket] ${user.username} joined socket room ${room}`);
      } catch (err) {
        logger.error('[Socket] join_chat error:', err);
        socket.emit('error', { message: 'Failed to join chat' });
      }
    });

    // Alias for client compatibility
    socket.on('joinChat', (data) => {
      try {
        const room = roomIdFromJoinPayload(data);
        if (!room) return socket.emit('error', { message: 'chatId is required' });

        socket.join(room);
        socket.emit('joined_chat', { chatId: room });
        logger.debug(`[Socket] ${user.username} joined socket room ${room}`);
      } catch (err) {
        logger.error('[Socket] joinChat error:', err);
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

    // Alias for client compatibility
    socket.on('leaveChat', (payload) => socket.emit('leave_chat', payload));

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

        const plain = toPlainDoc(message);
        const receivePayload = { message: plain };

        // Direct to this socket + broadcast to everyone else in the room (no duplicate for sender).
        socket.emit('receive_message', receivePayload);
        socket.emit('newMessage', plain);
        socket.broadcast.to(chatId).emit('receive_message', receivePayload);
        socket.broadcast.to(chatId).emit('newMessage', plain);
      } catch (err) {
        logger.error('[Socket] send_message error:', err);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // ── markAsRead ───────────────────────────────────────────────────────────
    const markAsReadHandler = async ({ chatId, lastMessageId } = {}) => {
      try {
        if (!chatId || !lastMessageId) return;
        const chat = await getChat(chatId, user._id);
        if (!chat) return;

        // Mark all messages up to lastMessageId as read by this user
        await Message.updateMany(
          {
            chat: chatId,
            isDeleted: false,
            _id: { $lte: lastMessageId },
            'readBy.user': { $ne: user._id },
          },
          { $push: { readBy: { user: user._id, readAt: new Date() } } },
        );

        io.to(chatId).emit('messageRead', {
          chatId,
          userId: user._id,
          lastMessageId,
        });
      } catch (err) {
        logger.error('[Socket] markAsRead error:', err);
      }
    };

    socket.on('markAsRead', markAsReadHandler);
    socket.on('mark_as_read', markAsReadHandler);

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
