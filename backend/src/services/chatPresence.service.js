/**
 * Chat presence helpers
 * ─────────────────────────────────────────────
 *
 * Thin façade over Socket.io that lets non-socket layers (the game
 * service in particular) push events at a user and forcibly evict
 * them from a chat room. We keep this in its own module so the game
 * service stays transport-agnostic and so unit tests can DI a stub.
 *
 * The `io` handle is injected from `server.js` via `setIo(io)` —
 * mirroring the pattern used by `notificationInbox.service.js`. If
 * `setIo` is never called (e.g. inside Jest with no HTTP server), the
 * emit/leave helpers become silent no-ops so the rest of the request
 * lifecycle continues unaffected.
 */

const logger = require('../utils/logger');

let _io = null;

const setIo = (io) => {
  _io = io || null;
};

const getIo = () => _io;

/**
 * Emits `event` to the target user's private socket room (every connected
 * device for that user joins a room keyed by `String(user._id)` — see
 * socket.manager.js).
 */
const emitToUser = (userId, event, payload = {}) => {
  if (!_io || !userId || !event) return false;
  try {
    _io.to(String(userId)).emit(event, payload);
    return true;
  } catch (err) {
    logger.warn(`[chat:presence] emit ${event} failed for ${userId}: ${err.message}`);
    return false;
  }
};

/**
 * Forces every active socket belonging to `userId` to leave the given
 * chat room. This is what prevents a kicked/left player from receiving
 * any further `receive_message` / `newMessage` broadcasts while they
 * still have the app open — even before their UI reacts to the
 * `chat:kicked` event.
 */
const forceUserOutOfChat = (userId, chatId) => {
  if (!_io || !userId || !chatId) return 0;
  try {
    const userRoom = String(userId);
    const sockets = _io.sockets?.adapter?.rooms?.get(userRoom);
    if (!sockets || sockets.size === 0) return 0;

    let removed = 0;
    for (const socketId of sockets) {
      const s = _io.sockets.sockets.get(socketId);
      if (s) {
        s.leave(String(chatId));
        removed += 1;
      }
    }
    return removed;
  } catch (err) {
    logger.warn(`[chat:presence] forceLeave failed for ${userId}/${chatId}: ${err.message}`);
    return 0;
  }
};

/**
 * One-shot helper: mark the user as evicted on the wire AND notify them.
 *
 * @param {Object}   params
 * @param {string}   params.userId   Mongo `_id` of the affected user.
 * @param {string}   params.chatId   Mongo `_id` of the chat being revoked.
 * @param {string}   params.gameId   Owning game (lets the client cross-reference).
 * @param {'kicked' | 'left'} params.reason  Drives which event name fires.
 * @param {string=}  params.detail   Optional human-readable note.
 */
const revokeChatAccess = ({ userId, chatId, gameId, reason, detail }) => {
  if (!userId || !chatId) return;

  forceUserOutOfChat(userId, chatId);

  const event = reason === 'kicked' ? 'chat:kicked' : 'chat:left';
  emitToUser(userId, event, {
    chatId: String(chatId),
    gameId: gameId ? String(gameId) : undefined,
    reason,
    detail: detail || undefined,
  });
};

module.exports = {
  setIo,
  getIo,
  emitToUser,
  forceUserOutOfChat,
  revokeChatAccess,
};
