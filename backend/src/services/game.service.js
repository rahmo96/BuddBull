const mongoose = require('mongoose');
const Game = require('../models/Game.model');
const User = require('../models/User.model');
const Chat = require('../models/Chat.model');
const AppError = require('../utils/AppError');
const logger = require('../utils/logger');
const notificationInboxService = require('./notificationInbox.service');
const chatPresenceService = require('./chatPresence.service');

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────

/**
 * Resolves the approved player count for a game document.
 */
const approvedCount = (game) => game.players.filter((p) => p.status === 'approved').length;

/**
 * Confirms the acting user is the organizer (or an admin).
 * Throws 403 if not.
 */
const assertOrganizer = (game, userId, userRole) => {
  const isOrganizer = game.organizer.toString() === userId.toString();
  if (!isOrganizer && userRole !== 'admin') {
    throw new AppError('Only the organizer can perform this action.', 403);
  }
};

// ─────────────────────────────────────────────
//  Notification dispatch
// ─────────────────────────────────────────────
//
// `notify(type, payload)` is the single funnel every game-lifecycle
// event goes through. It used to be a `logger.debug` stub; it now
// also writes a persistent row into the per-user inbox via
// `notificationInboxService`.
//
// Design notes
// ────────────
//  - The debug log is preserved so existing observability and the
//    test-output trail (`[notification:stub] ...` style) keep working.
//  - Each event type is mapped to a `{ recipients, type, title, body,
//    data }` descriptor by a dispatcher function. Single-recipient
//    rows go through `createForUser` (one document with full
//    Mongoose validation); multi-recipient fan-outs go through
//    `createForManyUsers` (`insertMany` — one round trip).
//  - Inbox writes are awaited but the entire dispatch is wrapped in
//    a try/catch. A failing inbox insert MUST NOT break the actual
//    game flow that triggered it — game.service callers downstream
//    of `await notify(...)` rely on the game state being persisted
//    even if the bell-badge update is lost.

const _dispatchers = {
  'game:invite': (p) => ({
    recipients: [p.targetUserId],
    type: 'gameInvite',
    title: 'New Game Invite',
    body: p.gameTitle
      ? `You've been invited to "${p.gameTitle}".`
      : 'You have been invited to a game.',
    data: {
      gameId: String(p.gameId),
      organizerId: p.organizerId ? String(p.organizerId) : undefined,
    },
  }),

  'game:joinRequest': (p) => ({
    recipients: [p.organizerId],
    type: 'gameJoinRequest',
    title: 'New Join Request',
    body: 'A player has requested to join your game.',
    data: {
      gameId: String(p.gameId),
      requesterId: p.requesterId ? String(p.requesterId) : undefined,
    },
  }),

  'game:playerJoined': (p) => ({
    recipients: p.organizerId ? [p.organizerId] : [],
    type: 'gamePlayerJoined',
    title: 'New Player Joined',
    body: 'A new player has joined your game.',
    data: {
      gameId: String(p.gameId),
      userId: p.userId ? String(p.userId) : undefined,
    },
  }),

  'game:playerLeft': (p) => ({
    recipients: p.organizerId ? [p.organizerId] : [],
    type: 'gamePlayerLeft',
    title: 'A Player Left',
    body: 'A player has left your game.',
    data: {
      gameId: String(p.gameId),
      userId: p.userId ? String(p.userId) : undefined,
    },
  }),

  'game:approved': (p) => ({
    recipients: [p.targetUserId],
    type: 'gameApproved',
    title: 'Join Request Approved',
    body: 'You are in the game!',
    data: { gameId: String(p.gameId) },
  }),

  /** Organiser declined a *pending* join request (not the same as removing an approved player). */
  'game:joinRequestDenied': (p) => ({
    recipients: [p.targetUserId],
    type: 'gameJoinRequestDenied',
    title: 'Join Request Denied',
    body: 'Your request to join the game was declined.',
    data: {
      gameId: String(p.gameId),
      ...(p.reason ? { reason: String(p.reason) } : {}),
    },
  }),

  /** An *approved* participant was removed from the roster by the organiser. */
  'game:kicked': (p) => ({
    recipients: [p.targetUserId],
    type: 'gameKicked',
    title: 'Removed From Game',
    body: p.reason
      ? 'You have been removed from the game. Reason: ' + String(p.reason)
      : 'You have been removed from the game.',
    data: { gameId: String(p.gameId) },
  }),

  'game:cancelled': (p) => ({
    recipients: p.playerIds ?? [],
    type: 'gameCancelled',
    title: 'Game Cancelled',
    body: p.reason
      ? `${p.gameTitle ? `"${p.gameTitle}" was cancelled` : 'A game was cancelled'}: ${p.reason}`
      : `${p.gameTitle ? `"${p.gameTitle}" was cancelled.` : 'A game was cancelled.'}`,
    data: { gameId: String(p.gameId) },
  }),

  'game:merged': (p) => ({
    recipients: p.affectedPlayerIds ?? [],
    type: 'gameMerged',
    title: 'Game Merged',
    body: 'Your game has been merged into another group.',
    data: {
      gameId: String(p.targetGameId),
      sourceGameId: p.sourceGameId ? String(p.sourceGameId) : undefined,
    },
  }),

  'game:completed': (p) => ({
    recipients: p.approvedPlayerIds ?? [],
    type: 'gameCompleted',
    title: 'Game Completed',
    body: 'Tap to rate the players.',
    data: { gameId: String(p.gameId) },
  }),
};

/**
 * Strips keys whose value is `undefined` so we don't litter the
 * Mixed `data` field with empty fields.
 */
const _compact = (obj) => {
  const out = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v !== undefined && v !== null && v !== '') out[k] = v;
  }
  return out;
};

const notify = async (type, payload) => {
  // Preserve the existing debug breadcrumb so the test log and the
  // structured-logging dashboards both keep working.
  logger.debug(`[notification:stub] ${type} → ${JSON.stringify(payload)}`);

  const buildDescriptor = _dispatchers[type];
  if (!buildDescriptor) return;

  try {
    const desc = buildDescriptor(payload || {});
    const recipients = (desc.recipients || []).filter(Boolean);
    if (recipients.length === 0) return;

    const inboxPayload = {
      type: desc.type,
      title: desc.title,
      body: desc.body || '',
      data: _compact(desc.data || {}),
    };

    if (recipients.length === 1) {
      await notificationInboxService.createForUser(recipients[0], inboxPayload);
    } else {
      await notificationInboxService.createForManyUsers(recipients, inboxPayload);
    }
  } catch (err) {
    // Never let an inbox write failure cascade into the game-flow
    // failure that triggered it. The game state has already been
    // persisted by the time `notify` runs.
    logger.warn(`[notification] dispatch failed for ${type}: ${err.message}`);
  }
};

/**
 * Ensures the given user is an active participant in the game's group chat.
 * Creates the chat if the game is missing it (defensive against older data).
 */
const ensureGroupChatParticipant = async (gameId, userId, { isAdmin = false } = {}) => {
  const game = await Game.findById(gameId).where({ deletedAt: null });
  if (!game) throw new AppError('Game not found.', 404);

  let chatId = game.groupChat;
  if (!chatId) {
    const chat = await Chat.create({
      type: 'group',
      name: `${game.title} — Chat`,
      game: game._id,
      participants: [{ user: game.organizer, isAdmin: true }],
    });
    game.groupChat = chat._id;
    await game.save({ validateBeforeSave: false });
    chatId = chat._id;
  }

  // Two cases to cover:
  //  1. Brand-new participant → $push.
  //  2. Returning participant whose slot still exists but is closed
  //     (`leftAt !== null` because they previously left/were kicked) →
  //     clear `leftAt` so the chat gate flips back to "active".
  //
  // We run them as two narrow updates so each only touches the doc
  // it actually matches.
  await Chat.updateOne(
    { _id: chatId, deletedAt: null, 'participants.user': { $ne: userId } },
    { $push: { participants: { user: userId, isAdmin, leftAt: null } } },
  );
  await Chat.updateOne(
    { _id: chatId, deletedAt: null },
    { $set: { 'participants.$[slot].leftAt': null, 'participants.$[slot].isAdmin': isAdmin } },
    { arrayFilters: [{ 'slot.user': userId, 'slot.leftAt': { $ne: null } }] },
  );
};

// ─────────────────────────────────────────────
//  revokeGroupChatParticipant
// ─────────────────────────────────────────────

/**
 * Closes a player's slot in a game's group chat and notifies their
 * live sockets so the UI immediately leaves the room. Idempotent: if
 * the game has no chat, or the participant is already inactive, this
 * is a no-op (we still log so audit trails stay coherent).
 *
 * @param {Object} game           Hydrated Game document (has `groupChat`).
 * @param {string} userId         Affected user's Mongo `_id`.
 * @param {'kicked' | 'left'} reason  Drives the socket event name.
 * @param {string=} detail        Optional reason string (e.g. "no-show").
 */
const revokeGroupChatParticipant = async (game, userId, reason, detail) => {
  if (!game || !userId) return;
  const chatId = game.groupChat;
  if (!chatId) return;

  try {
    // DB-side gate: even if the socket emit fails (or the client ignores
    // the event) the chat HTTP/socket auth checks will refuse the user
    // because their participant slot now has `leftAt` set.
    await Chat.updateOne(
      { _id: chatId, deletedAt: null },
      { $set: { 'participants.$[slot].leftAt': new Date() } },
      { arrayFilters: [{ 'slot.user': userId, 'slot.leftAt': null }] },
    );
  } catch (err) {
    logger.warn(`[chat:presence] participant close failed (game=${game._id}, user=${userId}): ${err.message}`);
  }

  chatPresenceService.revokeChatAccess({
    userId,
    chatId,
    gameId: game._id,
    reason,
    detail,
  });
};

// ─────────────────────────────────────────────
//  createGame
// ─────────────────────────────────────────────

/**
 * Creates a new game and automatically provisions a group chat for it.
 *
 * @param {string} organizerId
 * @param {object} dto  Validated fields from createGameSchema
 * @returns {Document} Populated game document
 */
const createGame = async (organizerId, dto) => {
  const game = new Game({
    ...dto,
    organizer: organizerId,
    players: [
      {
        user: organizerId,
        status: 'approved',
        role: 'co-organizer',
        joinedAt: new Date(),
      },
    ],
  });

  await game.save();

  const chat = await Chat.create({
    type: 'group',
    name: `${dto.title} — Chat`,
    game: game._id,
    participants: [{ user: organizerId, isAdmin: true }],
  });

  game.groupChat = chat._id;
  await game.save();

  await User.findByIdAndUpdate(organizerId, { $inc: { 'stats.gamesOrganized': 1 } });

  logger.info(`Game created: ${game._id} by organizer ${organizerId}`);

  return game.populate('organizer', 'username firstName lastName profilePicture');
};

// ─────────────────────────────────────────────
//  getGame
// ─────────────────────────────────────────────

const getGame = async (gameId) => {
  if (!mongoose.Types.ObjectId.isValid(gameId)) throw new AppError('Invalid game ID.', 400);

  const game = await Game.findById(gameId)
    .where({ deletedAt: null })
    .populate('organizer', 'username firstName lastName profilePicture stats.averageRating')
    .populate('players.user', 'username firstName lastName profilePicture stats.averageRating')
    .populate('groupChat', '_id name');

  if (!game) throw new AppError('Game not found.', 404);
  return game;
};

// ─────────────────────────────────────────────
//  searchGames
// ─────────────────────────────────────────────

/**
 * Full-featured game search with area-based geographic filtering.
 * Never filters by precise GPS; uses city + neighbourhood strings.
 *
 * @param {object} filters  Validated searchGamesSchema fields
 * @param {object|null} viewer  req.user (may be null for unauthenticated)
 */
const searchGames = async (filters, viewer = null) => {
  const {
    sport,
    city,
    neighborhood,
    skillLevel,
    status = 'open',
    dateFrom,
    dateTo,
    isPrivate,
    q,
    page = 1,
    limit = 20,
    sortBy = 'scheduledAt',
    sortOrder = 'asc',
  } = filters;

  const query = { deletedAt: null };

  // Exclude private games from unauthenticated viewers
  if (!viewer || isPrivate === false) {
    query.isPrivate = false;
  } else if (isPrivate === true && viewer) {
    query.isPrivate = true;
  }

  if (status) query.status = status;

  if (sport) query.sport = sport.toLowerCase();

  if (city) query['location.city'] = new RegExp(city.trim(), 'i');
  if (neighborhood) query['location.neighborhood'] = new RegExp(neighborhood.trim(), 'i');

  if (skillLevel && skillLevel !== 'any') {
    query.$or = [{ requiredSkillLevel: 'any' }, { requiredSkillLevel: skillLevel }];
  }

  if (dateFrom || dateTo) {
    query.scheduledAt = {};
    if (dateFrom) query.scheduledAt.$gte = new Date(dateFrom);
    if (dateTo) query.scheduledAt.$lte = new Date(dateTo);
  } else if (status === 'open' || status === 'full') {
    // Default: only future games when searching active matches
    query.scheduledAt = { $gt: new Date() };
  }

  if (q) {
    query.$text = { $search: q };
  }

  const sortOptions = {};
  if (q) {
    sortOptions.score = { $meta: 'textScore' };
  } else {
    sortOptions[sortBy] = sortOrder === 'asc' ? 1 : -1;
  }

  const skip = (Number(page) - 1) * Number(limit);

  const [games, total] = await Promise.all([
    Game.find(query)
      .populate('organizer', 'username firstName lastName profilePicture stats.averageRating')
      .sort(sortOptions)
      .skip(skip)
      .limit(Number(limit))
      .lean(),
    Game.countDocuments(query),
  ]);

  return {
    games,
    pagination: {
      total,
      page: Number(page),
      limit: Number(limit),
      pages: Math.ceil(total / Number(limit)),
    },
  };
};

// ─────────────────────────────────────────────
//  getMyGames  (joined + organised)
// ─────────────────────────────────────────────

/**
 * Returns all games a user has organised or joined (with approved status).
 * Used for the "My Games" screen.
 */
const getMyGames = async (userId, { status, page = 1, limit = 20 } = {}) => {
  // Use `$elemMatch` so the two conditions apply to the SAME player slot.
  // A plain `{ 'players.user': X, 'players.status': 'approved' }` is a
  // dot-path predicate over the entire array — it would match any doc
  // that contains a player with userId X AND a (different!) player with
  // status 'approved'. That's how `pending` users were incorrectly
  // seeing other people's approved games on the home screen.
  const base = {
    deletedAt: null,
    $or: [
      { organizer: userId },
      { players: { $elemMatch: { user: userId, status: 'approved' } } },
    ],
  };

  let query;
  if (status) {
    query = { ...base, status };
  } else {
    const ratingService = require('./rating.service');
    const pending = await ratingService.getPendingRatings(userId);
    const pendingGameIds = pending.map((p) => p.game.id).filter(Boolean);

    const completedWithPending =
      pendingGameIds.length > 0
        ? [{ _id: { $in: pendingGameIds }, status: 'completed' }]
        : [];

    query = {
      ...base,
      $and: [
        {
          $or: [{ status: { $ne: 'completed' } }, ...completedWithPending],
        },
      ],
    };
  }

  const skip = (Number(page) - 1) * Number(limit);

  const [games, total] = await Promise.all([
    Game.find(query)
      .populate('organizer', 'username firstName lastName profilePicture')
      .sort({ scheduledAt: 1 })
      .skip(skip)
      .limit(Number(limit))
      .lean(),
    Game.countDocuments(query),
  ]);

  return {
    games,
    pagination: {
      total,
      page: Number(page),
      limit: Number(limit),
      pages: Math.ceil(total / Number(limit)),
    },
  };
};

// ─────────────────────────────────────────────
//  getCalendar
// ─────────────────────────────────────────────

/**
 * Returns all upcoming games for a user within a date range.
 * Powers the calendar/schedule view with double-booking indicators.
 */
const getCalendar = async (userId, { dateFrom, dateTo }) => {
  const from = dateFrom ? new Date(dateFrom) : new Date();
  const to = dateTo
    ? new Date(dateTo)
    : (() => {
        const d = new Date();
        d.setDate(d.getDate() + 30);
        return d;
      })();

  const ratingService = require('./rating.service');
  const pending = await ratingService.getPendingRatings(userId);
  const pendingGameIds = pending.map((p) => p.game.id).filter(Boolean);

  // See `getMyGames` for the $elemMatch rationale — pending players must
  // not see games they aren't actually approved for.
  const participation = {
    $or: [
      { organizer: userId },
      { players: { $elemMatch: { user: userId, status: 'approved' } } },
    ],
  };

  const upcomingBranch = {
    status: { $in: ['open', 'full', 'in_progress'] },
    scheduledAt: { $gte: from, $lte: to },
  };

  const completedPendingBranch =
    pendingGameIds.length > 0
      ? {
          _id: { $in: pendingGameIds },
          status: 'completed',
        }
      : null;

  const games = await Game.find({
    deletedAt: null,
    $and: [
      participation,
      {
        $or: completedPendingBranch
          ? [upcomingBranch, completedPendingBranch]
          : [upcomingBranch],
      },
    ],
  })
    .populate('organizer', 'username firstName lastName')
    .sort({ scheduledAt: 1 })
    .lean();

  return games;
};

// ─────────────────────────────────────────────
//  updateGame
// ─────────────────────────────────────────────

const updateGame = async (gameId, userId, userRole, updates) => {
  const game = await Game.findById(gameId).where({ deletedAt: null });
  if (!game) throw new AppError('Game not found.', 404);

  assertOrganizer(game, userId, userRole);

  if (['completed', 'cancelled'].includes(game.status)) {
    throw new AppError(`Cannot update a game with status '${game.status}'.`, 400);
  }

  // Prevent lowering maxPlayers below current approved count
  if (updates.maxPlayers && updates.maxPlayers < approvedCount(game)) {
    throw new AppError(`Cannot reduce max players below the current approved count (${approvedCount(game)}).`, 400);
  }

  Object.assign(game, updates);
  await game.save();

  logger.info(`Game updated: ${gameId}`);
  return game;
};

// ─────────────────────────────────────────────
//  cancelGame
// ─────────────────────────────────────────────

const cancelGame = async (gameId, userId, userRole, reason) => {
  const game = await Game.findById(gameId).where({ deletedAt: null });
  if (!game) throw new AppError('Game not found.', 404);

  assertOrganizer(game, userId, userRole);

  if (game.status === 'cancelled') throw new AppError('Game is already cancelled.', 400);
  if (game.status === 'completed') throw new AppError('Cannot cancel a completed game.', 400);

  game.status = 'cancelled';
  game.cancelledReason = reason;
  game.cancelledAt = new Date();
  game.cancelledBy = userId;
  await game.save();

  // Notify all approved players
  const playerIds = game.players.filter((p) => p.status === 'approved').map((p) => p.user);
  await notify('game:cancelled', { gameId, playerIds, reason, gameTitle: game.title });

  logger.info(`Game cancelled: ${gameId} — ${reason}`);
  return game;
};

// ─────────────────────────────────────────────
//  joinGame
// ─────────────────────────────────────────────

/**
 * Adds a player to a game (or re-adds one who previously left/was kicked).
 *
 * Status transitions on an existing slot:
 *   approved  →  409 "already in this game"
 *   pending   →  409 "request already pending"
 *   invited   →  promoted to approved/pending depending on `requiresApproval`
 *                or `isPrivate` (this is the "accept invite" path)
 *   left      →  treated as a fresh re-join; status reset to approved/pending
 *   kicked    →  same as left (re-request allowed)
 *   rejected  →  organiser declined a join request; same re-join path as kicked
 *
 * Plus the standard validations:
 *  1. Game exists and is not deleted
 *  2. Game is open (not full / completed / cancelled)
 *  3. Player meets the skill-level requirement
 *  4. No schedule conflict with any of the player's other approved games
 */
const joinGame = async (gameId, userId) => {
  const game = await Game.findById(gameId).where({ deletedAt: null });
  if (!game) throw new AppError('Game not found.', 404);

  if (!['open', 'full'].includes(game.status)) {
    throw new AppError(`Cannot join a game with status '${game.status}'.`, 400);
  }

  if (game.status === 'full') throw new AppError('This game is already full.', 400);

  // Helper: target status for a fresh (or re-applied) join.
  const targetStatus = () =>
    (game.requiresApproval || game.isPrivate) ? 'pending' : 'approved';

  // Already in the game?
  const existingSlot = game.players.find((p) => p.user.toString() === userId.toString());
  if (existingSlot) {
    if (existingSlot.status === 'approved') {
      throw new AppError('You are already in this game.', 409);
    }
    if (existingSlot.status === 'pending') {
      throw new AppError('Your join request is already pending.', 409);
    }
    if (existingSlot.status === 'invited') {
      // Accept the invitation.
      existingSlot.status = targetStatus();
      existingSlot.resolvedAt = new Date();
      await game.save();

      if (existingSlot.status === 'approved') {
        await ensureGroupChatParticipant(gameId, userId, { isAdmin: false });
        await notify('game:playerJoined', { gameId, userId, organizerId: game.organizer });
      } else {
        await notify('game:joinRequest', { gameId, organizerId: game.organizer, requesterId: userId });
      }
      return { game, status: existingSlot.status };
    }
    if (['left', 'kicked', 'rejected'].includes(existingSlot.status)) {
      // Re-join path. Fall through to the skill-level + schedule-conflict
      // checks below by NOT returning here, then the post-validation block
      // detects this slot and mutates it in place instead of pushing a dup.
    } else {
      // Any other unexpected slot state — never $push a second row for the same user.
      throw new AppError('You already have a slot in this game.', 409);
    }
  }

  // Skill level check (skip if game accepts 'any')
  if (game.requiredSkillLevel !== 'any') {
    const user = await User.findById(userId).lean();
    const userSport = user?.sportsInterests?.find((s) => s.sport === game.sport);
    if (!userSport) {
      throw new AppError(`You haven't listed ${game.sport} as one of your sports. Update your profile first.`, 400);
    }

    const LEVELS = ['beginner', 'intermediate', 'advanced', 'professional'];
    const required = LEVELS.indexOf(game.requiredSkillLevel);
    const playerLevel = LEVELS.indexOf(userSport.skillLevel);
    if (playerLevel < required) {
      throw new AppError(
        `This game requires ${game.requiredSkillLevel} skill level. Your registered level: ${userSport.skillLevel}.`,
        400,
      );
    }
  }

  // Double-booking check — proposed window as explicit Dates / ms (see Game.findScheduleConflictGame)
  const proposedStart = game.scheduledAt instanceof Date ? game.scheduledAt : new Date(game.scheduledAt);
  if (Number.isNaN(proposedStart.getTime())) {
    throw new AppError('This game has an invalid scheduled time.', 500);
  }
  const proposedDurationMinutes = Number(game.durationMinutes);
  const durationMinutes =
    Number.isFinite(proposedDurationMinutes) && proposedDurationMinutes >= 0 ? proposedDurationMinutes : 0;

  const conflictingGame = await Game.findScheduleConflictGame(userId, proposedStart, durationMinutes, game._id);
  if (conflictingGame) {
    throw new AppError(
      'You have a schedule conflict — another game you have joined overlaps with this time slot.',
      409,
    );
  }

  // A game needs organiser approval if either flag is set:
  //   - `isPrivate`     → game is hidden from public search AND join requests queue up
  //   - `requiresApproval` → game is searchable but joins still queue up
  // Treat them as equivalent join-time gates.
  const playerStatus = targetStatus();

  // We only reach this branch when the slot is 'left', 'kicked', or
  // 'rejected' (organiser declined a join request) — the
  // approved/pending/invited cases all short-circuited above.
  if (existingSlot && ['left', 'kicked', 'rejected'].includes(existingSlot.status)) {
    existingSlot.status = playerStatus;
    existingSlot.joinedAt = new Date();
    existingSlot.resolvedAt = playerStatus === 'approved' ? new Date() : undefined;
  } else {
    game.players.push({ user: userId, status: playerStatus, joinedAt: new Date() });
  }
  await game.save();

  if (playerStatus === 'pending') {
    await notify('game:joinRequest', { gameId, organizerId: game.organizer, requesterId: userId });
  } else {
    // Add approved players to the group chat so they can access messages.
    await ensureGroupChatParticipant(gameId, userId, { isAdmin: false });
    await notify('game:playerJoined', { gameId, userId, organizerId: game.organizer });
  }

  logger.info(`Player ${userId} joined game ${gameId} (status: ${playerStatus})`);
  return { game, status: playerStatus };
};

// ─────────────────────────────────────────────
//  leaveGame
// ─────────────────────────────────────────────

const leaveGame = async (gameId, userId) => {
  const game = await Game.findById(gameId).where({ deletedAt: null });
  if (!game) throw new AppError('Game not found.', 404);

  if (game.organizer.toString() === userId.toString()) {
    throw new AppError('Organizers cannot leave their own game. Cancel it instead.', 400);
  }

  if (game.status === 'completed') throw new AppError('Cannot leave a completed game.', 400);

  const slot = game.players.find((p) => p.user.toString() === userId.toString());
  if (!slot || ['left', 'kicked', 'rejected'].includes(slot.status)) {
    throw new AppError('You are not in this game.', 400);
  }

  slot.status = 'left';
  slot.resolvedAt = new Date();
  await game.save();

  // Pull the player out of the game's group chat immediately. The DB
  // update marks their participant slot as `leftAt: now` so the socket
  // & HTTP layers refuse subsequent message reads/writes, while the
  // socket emit forces their open clients to leave the room and pop
  // the chat screen.
  await revokeGroupChatParticipant(game, userId, 'left');

  await notify('game:playerLeft', { gameId, userId, organizerId: game.organizer });

  logger.info(`Player ${userId} left game ${gameId}`);
};

// ─────────────────────────────────────────────
//  invitePlayer
// ─────────────────────────────────────────────

const invitePlayer = async (gameId, organizerId, organizerRole, targetUserId) => {
  const game = await Game.findById(gameId).where({ deletedAt: null });
  if (!game) throw new AppError('Game not found.', 404);

  assertOrganizer(game, organizerId, organizerRole);

  if (!['open', 'full'].includes(game.status)) {
    throw new AppError(`Cannot invite players to a game with status '${game.status}'.`, 400);
  }

  const existing = game.players.find((p) => p.user.toString() === targetUserId.toString());
  if (existing && ['invited', 'approved', 'pending'].includes(existing.status)) {
    throw new AppError('This user already has an active slot in the game.', 409);
  }

  const target = await User.findById(targetUserId).active().notBanned();
  if (!target) throw new AppError('Target user not found.', 404);

  // Re-invite after a closed slot — mutate in place instead of pushing a
  // second participant row with the same user id.
  if (existing && ['left', 'kicked', 'rejected'].includes(existing.status)) {
    existing.status = 'invited';
    existing.joinedAt = new Date();
    existing.resolvedAt = undefined;
    await game.save();

    await notify('game:invite', {
      gameId,
      organizerId,
      targetUserId,
      gameTitle: game.title,
    });

    logger.info(`Re-invited user ${targetUserId} to game ${gameId}`);
    return game;
  }

  game.players.push({ user: targetUserId, status: 'invited', joinedAt: new Date() });
  await game.save();

  await notify('game:invite', {
    gameId,
    organizerId,
    targetUserId,
    gameTitle: game.title,
  });

  logger.info(`Invited user ${targetUserId} to game ${gameId}`);
  return game;
};

// ─────────────────────────────────────────────
//  approvePlayer
// ─────────────────────────────────────────────

const approvePlayer = async (gameId, organizerId, organizerRole, targetUserId) => {
  const game = await Game.findById(gameId).where({ deletedAt: null });
  if (!game) throw new AppError('Game not found.', 404);

  assertOrganizer(game, organizerId, organizerRole);

  const slot = game.players.find((p) => p.user.toString() === targetUserId.toString());
  if (!slot) throw new AppError('Player is not in this game.', 404);
  if (slot.status !== 'pending' && slot.status !== 'invited') {
    throw new AppError(`Cannot approve a player with status '${slot.status}'.`, 400);
  }

  if (approvedCount(game) >= game.maxPlayers) {
    throw new AppError('Game is already full. Increase max players before approving more.', 400);
  }

  // Schedule conflict check at approve-time as well
  const hasConflict = await Game.hasConflict(targetUserId, game.scheduledAt, game.durationMinutes, game._id);
  if (hasConflict) {
    throw new AppError('This player has a schedule conflict and cannot be approved for this time slot.', 409);
  }

  slot.status = 'approved';
  slot.resolvedAt = new Date();
  await game.save();

  // Approved players must be added to the game group chat.
  await ensureGroupChatParticipant(gameId, targetUserId, { isAdmin: false });

  await notify('game:approved', { gameId, targetUserId });
  logger.info(`Player ${targetUserId} approved in game ${gameId}`);
  return game;
};

// ─────────────────────────────────────────────
//  kickPlayer
// ─────────────────────────────────────────────

const kickPlayer = async (
  gameId,
  organizerId,
  organizerRole,
  targetUserId,
  reason,
  { terminalPlayerStatus = 'kicked' } = {},
) => {
  const game = await Game.findById(gameId).where({ deletedAt: null });
  if (!game) throw new AppError('Game not found.', 404);

  assertOrganizer(game, organizerId, organizerRole);

  if (game.organizer.toString() === targetUserId.toString()) {
    throw new AppError('Cannot kick the organizer.', 400);
  }

  const slot = game.players.find((p) => p.user.toString() === targetUserId.toString());
  if (!slot) throw new AppError('Player is not in this game.', 404);
  if (['kicked', 'left', 'rejected'].includes(slot.status)) {
    throw new AppError(`Player is already ${slot.status}.`, 400);
  }

  const previousStatus = slot.status;

  slot.status = terminalPlayerStatus;
  slot.resolvedAt = new Date();
  await game.save();

  // Only *approved* players are in the group chat; pending/invited rejects
  // must not emit `chat:kicked` or touch chat rows they never accessed.
  if (previousStatus === 'approved') {
    await revokeGroupChatParticipant(game, targetUserId, 'kicked', reason);
  }

  if (previousStatus === 'pending') {
    await notify('game:joinRequestDenied', { gameId, targetUserId, reason });
  } else {
    await notify('game:kicked', { gameId, targetUserId, reason });
  }

  logger.info(`Player ${targetUserId} removed from game ${gameId} (was ${previousStatus}, now ${terminalPlayerStatus}). Reason: ${reason || 'none'}`);
  return game;
};

// ─────────────────────────────────────────────
//  handleJoinRequest  (approve / reject)
// ─────────────────────────────────────────────

/**
 * Organiser action on a pending join request — the producer behind the
 * "Approve" / "Reject" quick-action buttons in the notification inbox.
 *
 * `decision`:
 *  - 'approve' → delegates to [approvePlayer] (fires `game:approved`)
 *  - 'reject'  → delegates to [kickPlayer]   (fires `game:joinRequestDenied`)
 *
 * The slot must be in `pending` status; anything else throws 409 so a
 * stale notification (e.g. the organiser tapped Approve twice) returns
 * a clean error instead of silently double-acting.
 */
const handleJoinRequest = async (
  gameId,
  organizerId,
  organizerRole,
  requesterUserId,
  decision,
  reason,
) => {
  if (!['approve', 'reject'].includes(decision)) {
    throw new AppError("Decision must be 'approve' or 'reject'.", 400);
  }

  const game = await Game.findById(gameId).where({ deletedAt: null });
  if (!game) throw new AppError('Game not found.', 404);
  assertOrganizer(game, organizerId, organizerRole);

  const slot = game.players.find((p) => p.user.toString() === requesterUserId.toString());
  if (!slot) throw new AppError('Player is not in this game.', 404);
  if (slot.status !== 'pending') {
    throw new AppError(
      `Cannot ${decision} a player whose request is already '${slot.status}'.`,
      409,
    );
  }

  if (decision === 'approve') {
    return approvePlayer(gameId, organizerId, organizerRole, requesterUserId);
  }
  return kickPlayer(gameId, organizerId, organizerRole, requesterUserId, reason, {
    terminalPlayerStatus: 'rejected',
  });
};

// ─────────────────────────────────────────────
//  mergeGroups
// ─────────────────────────────────────────────

/**
 * Merges two under-capacity games.
 *
 * Rules:
 *  - Actor must be the organizer of the SOURCE game
 *  - Both games must be open (not full, completed, or cancelled)
 *  - The combined approved count must not exceed target's maxPlayers
 *    unless expandCapacity is explicitly set to true
 *
 * After merge:
 *  - Approved source players are moved to target
 *  - Source game status → 'cancelled', mergedInto → targetId
 *  - Target game isMerged = true, mergedWith.push(sourceId)
 *  - Source group chat members are added to target chat (Phase 6)
 *
 * @param {string} sourceGameId  Game being absorbed
 * @param {string} targetGameId  Game surviving the merge
 * @param {string} organizerId   Must own sourceGameId
 * @param {string} organizerRole
 * @param {boolean} expandCapacity  If true, increase target.maxPlayers
 */
const mergeGroups = async (sourceGameId, targetGameId, organizerId, organizerRole, expandCapacity = false) => {
  if (sourceGameId === targetGameId) {
    throw new AppError('Cannot merge a game with itself.', 400);
  }

  const [source, target] = await Promise.all([
    Game.findById(sourceGameId).where({ deletedAt: null }),
    Game.findById(targetGameId).where({ deletedAt: null }),
  ]);

  if (!source) throw new AppError('Source game not found.', 404);
  if (!target) throw new AppError('Target game not found.', 404);

  assertOrganizer(source, organizerId, organizerRole);

  if (source.status !== 'open')
    throw new AppError(`Source game status is '${source.status}'. Only open games can be merged.`, 400);
  if (target.status !== 'open')
    throw new AppError(`Target game status is '${target.status}'. Only open games can be merged.`, 400);

  const sourceApproved = source.players.filter((p) => p.status === 'approved');
  const targetApproved = approvedCount(target);
  const combinedCount = targetApproved + sourceApproved.length;

  if (combinedCount > target.maxPlayers) {
    if (!expandCapacity) {
      throw new AppError(
        `Merge would result in ${combinedCount} players, exceeding target capacity of ${target.maxPlayers}. ` +
          'Pass expandCapacity: true to automatically increase the target game capacity.',
        400,
      );
    }
    target.maxPlayers = combinedCount;
  }

  // Deduplicate — don't add players already in target
  const existingTargetUserIds = new Set(
    target.players.filter((p) => ['approved', 'pending', 'invited'].includes(p.status)).map((p) => p.user.toString()),
  );

  for (const slot of sourceApproved) {
    if (!existingTargetUserIds.has(slot.user.toString())) {
      // Recheck schedule conflict for each migrating player
      // eslint-disable-next-line no-await-in-loop
      const conflict = await Game.hasConflict(slot.user, target.scheduledAt, target.durationMinutes, target._id);
      if (!conflict) {
        target.players.push({ user: slot.user, status: 'approved', joinedAt: new Date() });
      }
      // Players with conflicts are silently skipped (organizer should handle manually)
    }
  }

  // Finalise merge
  const now = new Date();
  source.status = 'cancelled';
  source.cancelledReason = `Merged into game: ${target.title}`;
  source.cancelledAt = now;
  source.mergedInto = target._id;

  target.isMerged = true;
  target.mergedWith.push(source._id);
  target.mergedAt = now;

  await Promise.all([source.save(), target.save()]);

  const allPlayerIds = [
    ...new Set([
      ...sourceApproved.map((p) => p.user.toString()),
      ...target.players.filter((p) => p.status === 'approved').map((p) => p.user.toString()),
    ]),
  ];

  await notify('game:merged', { sourceGameId, targetGameId, affectedPlayerIds: allPlayerIds });

  logger.info(`Merge complete: ${sourceGameId} → ${targetGameId} (${sourceApproved.length} players transferred)`);

  return target;
};

// ─────────────────────────────────────────────
//  completeGame
// ─────────────────────────────────────────────

/**
 * Marks a game as completed, records the result, and updates
 * aggregate stats for all approved players.
 */
const completeGame = async (gameId, organizerId, organizerRole, resultDto) => {
  const game = await Game.findById(gameId).where({ deletedAt: null });
  if (!game) throw new AppError('Game not found.', 404);

  assertOrganizer(game, organizerId, organizerRole);

  if (game.status === 'completed') throw new AppError('Game is already completed.', 400);
  if (game.status === 'cancelled') throw new AppError('Cannot complete a cancelled game.', 400);

  game.status = 'completed';
  game.result = {
    winnerDescription: resultDto.winnerDescription,
    score: resultDto.score,
    mvpUser: resultDto.mvpUserId || null,
    notes: resultDto.notes,
    recordedAt: new Date(),
    recordedBy: organizerId,
  };

  await game.save();

  // Bulk-update stats for all approved players
  const approvedPlayerIds = game.players.filter((p) => p.status === 'approved').map((p) => p.user);

  await User.updateMany({ _id: { $in: approvedPlayerIds } }, { $inc: { 'stats.gamesPlayed': 1 } });

  // Update streaks for each player (must run per-document for streak logic)
  const players = await User.find({ _id: { $in: approvedPlayerIds } });
  await Promise.all(
    players.map(async (player) => {
      player.updateStreak();
      await player.save({ validateBeforeSave: false });
    }),
  );

  await notify('game:completed', { gameId, approvedPlayerIds });
  logger.info(`Game completed: ${gameId}`);

  return game;
};

// ─────────────────────────────────────────────
//  getPendingRequests
// ─────────────────────────────────────────────

/**
 * Returns all pending join requests for a game (organizer view).
 */
const getPendingRequests = async (gameId, organizerId, organizerRole) => {
  const game = await Game.findById(gameId)
    .where({ deletedAt: null })
    .populate('players.user', 'username firstName lastName profilePicture stats');

  if (!game) throw new AppError('Game not found.', 404);
  assertOrganizer(game, organizerId, organizerRole);

  const pending = game.players.filter((p) => p.status === 'pending');
  return pending;
};

// ─────────────────────────────────────────────
//  Admin helpers
// ─────────────────────────────────────────────

/**
 * Admin: list all games (dashboard use).
 */
const adminListGames = async ({ page = 1, limit = 50, status, sport } = {}) => {
  const query = { deletedAt: null };
  if (status) query.status = status;
  if (sport) query.sport = sport;

  const skip = (Number(page) - 1) * Number(limit);

  const [games, total] = await Promise.all([
    Game.find(query)
      .populate('organizer', 'username email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(Number(limit))
      .lean(),
    Game.countDocuments(query),
  ]);

  return {
    games,
    pagination: {
      total,
      page: Number(page),
      limit: Number(limit),
      pages: Math.ceil(total / Number(limit)),
    },
  };
};

module.exports = {
  createGame,
  getGame,
  searchGames,
  getMyGames,
  getCalendar,
  updateGame,
  cancelGame,
  joinGame,
  leaveGame,
  invitePlayer,
  approvePlayer,
  kickPlayer,
  handleJoinRequest,
  mergeGroups,
  completeGame,
  getPendingRequests,
  adminListGames,
};
