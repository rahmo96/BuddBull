const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/AppError');
const GameService = require('../services/game.service');

// ─────────────────────────────────────────────
//  POST /api/v1/games
// ─────────────────────────────────────────────

const createGame = catchAsync(async (req, res) => {
  const game = await GameService.createGame(req.user._id, req.body);

  res.status(201).json({ success: true, data: { game } });
});

// ─────────────────────────────────────────────
//  GET /api/v1/games
// ─────────────────────────────────────────────

const searchGames = catchAsync(async (req, res) => {
  const result = await GameService.searchGames(req.query, req.user || null);

  res.status(200).json({ success: true, ...result });
});

// ─────────────────────────────────────────────
//  GET /api/v1/games/me
// ─────────────────────────────────────────────

const getMyGames = catchAsync(async (req, res) => {
  const result = await GameService.getMyGames(req.user._id, req.query);

  res.status(200).json({ success: true, ...result });
});

// ─────────────────────────────────────────────
//  GET /api/v1/games/calendar
// ─────────────────────────────────────────────

const getCalendar = catchAsync(async (req, res) => {
  const games = await GameService.getCalendar(req.user._id, req.query);

  res.status(200).json({ success: true, results: games.length, data: { games } });
});

// ─────────────────────────────────────────────
//  GET /api/v1/games/:id
// ─────────────────────────────────────────────

const getGame = catchAsync(async (req, res) => {
  const game = await GameService.getGame(req.params.id);

  res.status(200).json({ success: true, data: { game } });
});

// ─────────────────────────────────────────────
//  PATCH /api/v1/games/:id
// ─────────────────────────────────────────────

const updateGame = catchAsync(async (req, res) => {
  const game = await GameService.updateGame(req.params.id, req.user._id, req.user.role, req.body);

  res.status(200).json({ success: true, data: { game } });
});

// ─────────────────────────────────────────────
//  DELETE /api/v1/games/:id
// ─────────────────────────────────────────────

const cancelGame = catchAsync(async (req, res) => {
  const { reason } = req.body;
  if (!reason) throw new AppError('Cancellation reason is required.', 400);

  const game = await GameService.cancelGame(req.params.id, req.user._id, req.user.role, reason);

  res.status(200).json({ success: true, message: 'Game cancelled.', data: { game } });
});

// ─────────────────────────────────────────────
//  POST /api/v1/games/:id/join
// ─────────────────────────────────────────────

const joinGame = catchAsync(async (req, res) => {
  const { game, status } = await GameService.joinGame(req.params.id, req.user._id);

  const message = status === 'approved'
    ? 'You have joined the game!'
    : 'Your join request is pending organizer approval.';

  res.status(200).json({ success: true, message, data: { status, game } });
});

// ─────────────────────────────────────────────
//  DELETE /api/v1/games/:id/leave
// ─────────────────────────────────────────────

const leaveGame = catchAsync(async (req, res) => {
  await GameService.leaveGame(req.params.id, req.user._id);

  res.status(200).json({ success: true, message: 'You have left the game.' });
});

// ─────────────────────────────────────────────
//  POST /api/v1/games/:id/invite/:userId
// ─────────────────────────────────────────────

const invitePlayer = catchAsync(async (req, res) => {
  const game = await GameService.invitePlayer(
    req.params.id,
    req.user._id,
    req.user.role,
    req.params.userId,
  );

  res.status(200).json({ success: true, message: 'Invitation sent.', data: { game } });
});

// ─────────────────────────────────────────────
//  PATCH /api/v1/games/:id/players/:userId/approve
// ─────────────────────────────────────────────

const approvePlayer = catchAsync(async (req, res) => {
  const game = await GameService.approvePlayer(
    req.params.id,
    req.user._id,
    req.user.role,
    req.params.userId,
  );

  res.status(200).json({ success: true, message: 'Player approved.', data: { game } });
});

// ─────────────────────────────────────────────
//  DELETE /api/v1/games/:id/players/:userId
// ─────────────────────────────────────────────

const kickPlayer = catchAsync(async (req, res) => {
  const game = await GameService.kickPlayer(
    req.params.id,
    req.user._id,
    req.user.role,
    req.params.userId,
    req.body.reason,
  );

  res.status(200).json({ success: true, message: 'Player removed from game.', data: { game } });
});

// ─────────────────────────────────────────────
//  GET /api/v1/games/:id/players/pending
// ─────────────────────────────────────────────

const getPendingRequests = catchAsync(async (req, res) => {
  const pending = await GameService.getPendingRequests(
    req.params.id,
    req.user._id,
    req.user.role,
  );

  res.status(200).json({ success: true, results: pending.length, data: { pending } });
});

// ─────────────────────────────────────────────
//  POST /api/v1/games/:id/merge/:targetId
// ─────────────────────────────────────────────

const mergeGroups = catchAsync(async (req, res) => {
  const { expandCapacity } = req.body;
  const game = await GameService.mergeGroups(
    req.params.id,
    req.params.targetId,
    req.user._id,
    req.user.role,
    expandCapacity,
  );

  res.status(200).json({
    success: true,
    message: 'Groups merged successfully.',
    data: { game },
  });
});

// ─────────────────────────────────────────────
//  PATCH /api/v1/games/:id/complete
// ─────────────────────────────────────────────

const completeGame = catchAsync(async (req, res) => {
  const game = await GameService.completeGame(
    req.params.id,
    req.user._id,
    req.user.role,
    req.body,
  );

  res.status(200).json({ success: true, message: 'Game marked as completed.', data: { game } });
});

// ─────────────────────────────────────────────
//  Admin: GET /api/v1/games/admin/list
// ─────────────────────────────────────────────

const adminListGames = catchAsync(async (req, res) => {
  const result = await GameService.adminListGames(req.query);

  res.status(200).json({ success: true, ...result });
});

module.exports = {
  createGame,
  searchGames,
  getMyGames,
  getCalendar,
  getGame,
  updateGame,
  cancelGame,
  joinGame,
  leaveGame,
  invitePlayer,
  approvePlayer,
  kickPlayer,
  getPendingRequests,
  mergeGroups,
  completeGame,
  adminListGames,
};
