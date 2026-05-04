const adminService = require('../services/admin.service');
const notificationService = require('../services/notification.service');
const catchAsync = require('../utils/catchAsync');

// ── Dashboard ─────────────────────────────────────────────────────────────────
exports.getDashboard = catchAsync(async (req, res) => {
  const stats = await adminService.getDashboardStats(req.query);
  res.status(200).json({ success: true, data: stats });
});

// ── User management ───────────────────────────────────────────────────────────
exports.listUsers = catchAsync(async (req, res) => {
  const result = await adminService.listUsers(req.query);
  res.status(200).json({ success: true, data: result });
});

exports.banUser = catchAsync(async (req, res) => {
  const user = await adminService.banUser(req.params.userId, req.body);
  res.status(200).json({
    success: true,
    message: `User has been ${user.isBanned ? 'banned' : 'unbanned'}`,
    data: { user },
  });
});

exports.deleteUser = catchAsync(async (req, res) => {
  await adminService.adminDeleteUser(req.params.userId, req.user._id);
  res.status(200).json({ success: true, message: 'User account deleted' });
});

// ── Game management ───────────────────────────────────────────────────────────
exports.listGames = catchAsync(async (req, res) => {
  const result = await adminService.listGames(req.query);
  res.status(200).json({ success: true, data: result });
});

exports.deleteGame = catchAsync(async (req, res) => {
  await adminService.adminDeleteGame(req.params.gameId, req.user._id);
  res.status(200).json({ success: true, message: 'Game deleted' });
});

// ── CSV exports ───────────────────────────────────────────────────────────────
exports.exportUsers = catchAsync(async (req, res) => {
  const csv = await adminService.exportUsersCSV();
  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', `attachment; filename="buddbull-users-${Date.now()}.csv"`);
  res.status(200).send(csv);
});

exports.exportGames = catchAsync(async (req, res) => {
  const csv = await adminService.exportGamesCSV();
  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', `attachment; filename="buddbull-games-${Date.now()}.csv"`);
  res.status(200).send(csv);
});

// ── Broadcast ─────────────────────────────────────────────────────────────────
exports.broadcast = catchAsync(async (req, res) => {
  const io = req.app.get('io');
  const result = await adminService.broadcastMessage(req.body, io, notificationService);
  res.status(200).json({ success: true, message: 'Broadcast sent', data: result });
});

// ── Sports categories ─────────────────────────────────────────────────────────
exports.getSports = catchAsync(async (req, res) => {
  const sports = await adminService.getSports();
  res.status(200).json({ success: true, data: { sports } });
});

exports.createSport = catchAsync(async (req, res) => {
  const sport = await adminService.createSport(req.body, req.user._id);
  res.status(201).json({ success: true, data: { sport } });
});

exports.updateSport = catchAsync(async (req, res) => {
  const sport = await adminService.updateSport(req.params.sportId, req.body);
  res.status(200).json({ success: true, data: { sport } });
});

exports.deleteSport = catchAsync(async (req, res) => {
  await adminService.deleteSport(req.params.sportId);
  res.status(200).json({ success: true, message: 'Sport category deactivated' });
});
