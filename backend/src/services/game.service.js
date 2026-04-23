const mongoose = require('mongoose');
const Game = require('../models/Game.model');
const User = require('../models/User.model');
const Chat = require('../models/Chat.model');
const AppError = require('../utils/AppError');
const logger = require('../utils/logger');

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

/**
 * Stubs a notification call. Wired up in Phase 7 with real FCM/email.
 */
const notify = (type, payload) => {
  logger.debug(`[notification:stub] ${type} → ${JSON.stringify(payload)}`);
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
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    // Create the game document
    const game = new Game({
      ...dto,
      organizer: organizerId,
      players: [{ user: organizerId, status: 'approved', role: 'co-organizer', joinedAt: new Date() }],
    });

    // Auto-provision the group chat
    const chat = await Chat.create(
      [
        {
          type: 'group',
          name: `${dto.title} — Chat`,
          game: game._id,
          participants: [{ user: organizerId, isAdmin: true }],
        },
      ],
      { session },
    );

    game.groupChat = chat[0]._id;
    await game.save({ session });
    await session.commitTransaction();

    // Increment organizer's gamesOrganized stat
    await User.findByIdAndUpdate(organizerId, { $inc: { 'stats.gamesOrganized': 1 } });

    logger.info(`Game created: ${game._id} by organizer ${organizerId}`);

    return game.populate('organizer', 'username firstName lastName profilePicture');
  } catch (err) {
    await session.abortTransaction();
    throw err;
  } finally {
    session.endSession();
  }
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
    sport, city, neighborhood, skillLevel,
    status = 'open', dateFrom, dateTo,
    isPrivate, q, page = 1, limit = 20,
    sortBy = 'scheduledAt', sortOrder = 'asc',
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
    query.$or = [
      { requiredSkillLevel: 'any' },
      { requiredSkillLevel: skillLevel },
    ];
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
  const query = {
    deletedAt: null,
    $or: [
      { organizer: userId },
      { 'players.user': userId, 'players.status': 'approved' },
    ],
  };

  if (status) query.status = status;

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

  return { games, pagination: { total, page: Number(page), limit: Number(limit), pages: Math.ceil(total / Number(limit)) } };
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
  const to = dateTo ? new Date(dateTo) : (() => { const d = new Date(); d.setDate(d.getDate() + 30); return d; })();

  const games = await Game.find({
    deletedAt: null,
    status: { $in: ['open', 'full', 'in_progress'] },
    scheduledAt: { $gte: from, $lte: to },
    $or: [
      { organizer: userId },
      { 'players.user': userId, 'players.status': 'approved' },
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
    throw new AppError(
      `Cannot reduce max players below the current approved count (${approvedCount(game)}).`,
      400,
    );
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
  notify('game:cancelled', { gameId, playerIds, reason });

  logger.info(`Game cancelled: ${gameId} — ${reason}`);
  return game;
};

// ─────────────────────────────────────────────
//  joinGame
// ─────────────────────────────────────────────

/**
 * Adds a player to a game.
 *
 * Checks:
 *  1. Game exists and is open
 *  2. Player isn't already in the game
 *  3. Player meets skill level requirement
 *  4. No schedule conflict with any of the player's other approved games
 *
 * Status set to 'pending' if requiresApproval, else 'approved'.
 */
const joinGame = async (gameId, userId) => {
  const game = await Game.findById(gameId).where({ deletedAt: null });
  if (!game) throw new AppError('Game not found.', 404);

  if (!['open', 'full'].includes(game.status)) {
    throw new AppError(`Cannot join a game with status '${game.status}'.`, 400);
  }

  if (game.status === 'full') throw new AppError('This game is already full.', 400);

  // Already in the game?
  const existingSlot = game.players.find((p) => p.user.toString() === userId.toString());
  if (existingSlot) {
    if (existingSlot.status === 'approved') throw new AppError('You are already in this game.', 409);
    if (existingSlot.status === 'pending') throw new AppError('Your join request is already pending.', 409);
    if (existingSlot.status === 'kicked') throw new AppError('You have been removed from this game.', 403);
    if (existingSlot.status === 'invited') {
      // Accept the invitation
      existingSlot.status = game.requiresApproval ? 'pending' : 'approved';
      existingSlot.resolvedAt = new Date();
      await game.save();
      return { game, status: existingSlot.status };
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

  // Double-booking check
  const hasConflict = await Game.hasConflict(userId, game.scheduledAt, game.durationMinutes);
  if (hasConflict) {
    throw new AppError(
      'You have a schedule conflict — another game you have joined overlaps with this time slot.',
      409,
    );
  }

  const playerStatus = game.requiresApproval ? 'pending' : 'approved';
  game.players.push({ user: userId, status: playerStatus, joinedAt: new Date() });
  await game.save();

  if (playerStatus === 'pending') {
    notify('game:joinRequest', { gameId, organizerId: game.organizer, requesterId: userId });
  } else {
    notify('game:playerJoined', { gameId, userId });
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
  if (!slot || ['left', 'kicked'].includes(slot.status)) {
    throw new AppError('You are not in this game.', 400);
  }

  slot.status = 'left';
  slot.resolvedAt = new Date();
  await game.save();

  notify('game:playerLeft', { gameId, userId, organizerId: game.organizer });

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

  game.players.push({ user: targetUserId, status: 'invited', joinedAt: new Date() });
  await game.save();

  notify('game:invite', { gameId, organizerId, targetUserId, gameTitle: game.title });

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
  const hasConflict = await Game.hasConflict(targetUserId, game.scheduledAt, game.durationMinutes);
  if (hasConflict) {
    throw new AppError('This player has a schedule conflict and cannot be approved for this time slot.', 409);
  }

  slot.status = 'approved';
  slot.resolvedAt = new Date();
  await game.save();

  notify('game:approved', { gameId, targetUserId });
  logger.info(`Player ${targetUserId} approved in game ${gameId}`);
  return game;
};

// ─────────────────────────────────────────────
//  kickPlayer
// ─────────────────────────────────────────────

const kickPlayer = async (gameId, organizerId, organizerRole, targetUserId, reason) => {
  const game = await Game.findById(gameId).where({ deletedAt: null });
  if (!game) throw new AppError('Game not found.', 404);

  assertOrganizer(game, organizerId, organizerRole);

  if (game.organizer.toString() === targetUserId.toString()) {
    throw new AppError('Cannot kick the organizer.', 400);
  }

  const slot = game.players.find((p) => p.user.toString() === targetUserId.toString());
  if (!slot) throw new AppError('Player is not in this game.', 404);
  if (['kicked', 'left'].includes(slot.status)) {
    throw new AppError(`Player is already ${slot.status}.`, 400);
  }

  slot.status = 'kicked';
  slot.resolvedAt = new Date();
  await game.save();

  notify('game:kicked', { gameId, targetUserId, reason });
  logger.info(`Player ${targetUserId} kicked from game ${gameId}. Reason: ${reason || 'none'}`);
  return game;
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

  if (source.status !== 'open') throw new AppError(`Source game status is '${source.status}'. Only open games can be merged.`, 400);
  if (target.status !== 'open') throw new AppError(`Target game status is '${target.status}'. Only open games can be merged.`, 400);

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
    target.players.filter((p) => ['approved', 'pending', 'invited'].includes(p.status))
      .map((p) => p.user.toString()),
  );

  for (const slot of sourceApproved) {
    if (!existingTargetUserIds.has(slot.user.toString())) {
      // Recheck schedule conflict for each migrating player
      // eslint-disable-next-line no-await-in-loop
      const conflict = await Game.hasConflict(slot.user, target.scheduledAt, target.durationMinutes);
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

  const allPlayerIds = [...new Set([
    ...sourceApproved.map((p) => p.user.toString()),
    ...target.players.filter((p) => p.status === 'approved').map((p) => p.user.toString()),
  ])];

  notify('game:merged', { sourceGameId, targetGameId, affectedPlayerIds: allPlayerIds });

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
  const approvedPlayerIds = game.players
    .filter((p) => p.status === 'approved')
    .map((p) => p.user);

  await User.updateMany(
    { _id: { $in: approvedPlayerIds } },
    { $inc: { 'stats.gamesPlayed': 1 } },
  );

  // Update streaks for each player (must run per-document for streak logic)
  const players = await User.find({ _id: { $in: approvedPlayerIds } });
  await Promise.all(
    players.map(async (player) => {
      player.updateStreak();
      await player.save({ validateBeforeSave: false });
    }),
  );

  notify('game:completed', { gameId, approvedPlayerIds });
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

  return { games, pagination: { total, page: Number(page), limit: Number(limit), pages: Math.ceil(total / Number(limit)) } };
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
  mergeGroups,
  completeGame,
  getPendingRequests,
  adminListGames,
};
