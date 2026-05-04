const User = require('../models/User.model');
const Game = require('../models/Game.model');
const PerformanceLog = require('../models/PerformanceLog.model');
const Chat = require('../models/Chat.model');
const SportCategory = require('../models/SportCategory.model');
const AppError = require('../utils/AppError');
const { toCSV } = require('../utils/csvExport');
const logger = require('../utils/logger');

// ── Dashboard ─────────────────────────────────────────────────────────────────
const getDashboardStats = async ({ period = '30d' } = {}) => {
  const periodDays = { '7d': 7, '30d': 30, '90d': 90 }[period] ?? 30;
  const since = new Date(Date.now() - periodDays * 24 * 60 * 60 * 1000);
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

  const [
    totalUsers,
    activeUsers,
    newUsers,
    bannedUsers,
    totalGames,
    activeGames,
    completedGames,
    cancelledGames,
    totalLogs,
    sportBreakdown,
    dailyRegistrations,
    churnCount,
  ] = await Promise.all([
    User.countDocuments({ isDeleted: false }),
    User.countDocuments({ isDeleted: false, isBanned: false, lastLoginAt: { $gte: thirtyDaysAgo } }),
    User.countDocuments({ isDeleted: false, createdAt: { $gte: since } }),
    User.countDocuments({ isBanned: true }),
    Game.countDocuments({ isDeleted: false }),
    Game.countDocuments({ isDeleted: false, status: { $in: ['open', 'full'] } }),
    Game.countDocuments({ isDeleted: false, status: 'completed' }),
    Game.countDocuments({ isDeleted: false, status: 'cancelled' }),
    PerformanceLog.countDocuments({ isDeleted: false }),
    // Top sports by number of games
    Game.aggregate([
      { $match: { isDeleted: false } },
      { $group: { _id: '$sport', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 10 },
      { $project: { _id: 0, sport: '$_id', count: 1 } },
    ]),
    // Daily new registrations for the period (for sparkline)
    User.aggregate([
      { $match: { isDeleted: false, createdAt: { $gte: since } } },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
      { $project: { _id: 0, date: '$_id', count: 1 } },
    ]),
    // Churned users: registered > 30d ago but never logged in OR lastLogin > 60d ago
    User.countDocuments({
      isDeleted: false,
      isBanned: false,
      createdAt: { $lt: thirtyDaysAgo },
      $or: [
        { lastLoginAt: { $exists: false } },
        { lastLoginAt: { $lt: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000) } },
      ],
    }),
  ]);

  const churnRate = totalUsers > 0 ? ((churnCount / totalUsers) * 100).toFixed(1) : '0.0';

  return {
    period,
    users: {
      total: totalUsers,
      active: activeUsers,
      new: newUsers,
      banned: bannedUsers,
      churned: churnCount,
      churnRate: `${churnRate}%`,
    },
    games: {
      total: totalGames,
      active: activeGames,
      completed: completedGames,
      cancelled: cancelledGames,
    },
    performance: { totalLogs },
    sportBreakdown,
    dailyRegistrations,
  };
};

// ── User management ───────────────────────────────────────────────────────────
const listUsers = async ({ page = 1, limit = 20, search, role, status, sort = '-createdAt' } = {}) => {
  const filter = { isDeleted: false };

  if (search) {
    filter.$or = [
      { username: { $regex: search, $options: 'i' } },
      { email: { $regex: search, $options: 'i' } },
      { firstName: { $regex: search, $options: 'i' } },
      { lastName: { $regex: search, $options: 'i' } },
    ];
  }
  if (role) filter.role = role;
  if (status === 'banned') filter.isBanned = true;
  else if (status === 'active') filter.isBanned = false;
  else if (status === 'deleted') { delete filter.isDeleted; filter.isDeleted = true; }

  const [users, total] = await Promise.all([
    User.find(filter)
      .select('firstName lastName username email role isBanned isEmailVerified createdAt lastLoginAt stats.gamesPlayed')
      .sort(sort)
      .skip((page - 1) * limit)
      .limit(limit)
      .lean(),
    User.countDocuments(filter),
  ]);

  return { users, total, page, totalPages: Math.ceil(total / limit) };
};

const banUser = async (userId, { isBanned, reason } = {}) => {
  const user = await User.findOne({ _id: userId, isDeleted: false });
  if (!user) throw new AppError('User not found', 404);
  if (user.role === 'admin') throw new AppError('Cannot ban an admin account', 403);

  user.isBanned = isBanned;
  if (isBanned && reason) user.banReason = reason;
  if (!isBanned) user.banReason = undefined;
  await user.save({ validateBeforeSave: false });

  logger.info(`[Admin] User ${isBanned ? 'banned' : 'unbanned'}: ${user.username} (${userId})`);
  return user;
};

const adminDeleteUser = async (userId, adminId) => {
  if (userId.toString() === adminId.toString()) {
    throw new AppError('You cannot delete your own admin account', 403);
  }
  const user = await User.findOne({ _id: userId, isDeleted: false });
  if (!user) throw new AppError('User not found', 404);
  if (user.role === 'admin') throw new AppError('Cannot delete an admin account', 403);

  await user.softDelete(adminId);
  logger.info(`[Admin] User deleted: ${user.username} (${userId}) by admin ${adminId}`);
};

// ── Game management ───────────────────────────────────────────────────────────
const listGames = async ({ page = 1, limit = 20, sport, status, sort = '-createdAt' } = {}) => {
  const filter = { isDeleted: false };
  if (sport) filter.sport = sport;
  if (status) filter.status = status;

  const [games, total] = await Promise.all([
    Game.find(filter)
      .select('title sport status scheduledAt location.city players organizer maxPlayers createdAt')
      .populate('organizer', 'firstName lastName username')
      .sort(sort)
      .skip((page - 1) * limit)
      .limit(limit)
      .lean(),
    Game.countDocuments(filter),
  ]);

  return { games, total, page, totalPages: Math.ceil(total / limit) };
};

const adminDeleteGame = async (gameId, adminId) => {
  const game = await Game.findOne({ _id: gameId, isDeleted: false });
  if (!game) throw new AppError('Game not found', 404);
  await game.softDelete(adminId);
  logger.info(`[Admin] Game deleted: ${game.title} (${gameId}) by admin ${adminId}`);
};

// ── CSV export ────────────────────────────────────────────────────────────────
const exportUsersCSV = async () => {
  const users = await User.find({ isDeleted: false })
    .select('firstName lastName username email role isBanned isEmailVerified createdAt lastLoginAt stats')
    .lean();

  return toCSV(users, [
    { label: 'ID', path: '_id' },
    { label: 'First Name', path: 'firstName' },
    { label: 'Last Name', path: 'lastName' },
    { label: 'Username', path: 'username' },
    { label: 'Email', path: 'email' },
    { label: 'Role', path: 'role' },
    { label: 'Banned', path: 'isBanned' },
    { label: 'Email Verified', path: 'isEmailVerified' },
    { label: 'Games Played', path: 'stats.gamesPlayed' },
    { label: 'Wins', path: 'stats.wins' },
    { label: 'Last Login', path: 'lastLoginAt' },
    { label: 'Joined', path: 'createdAt' },
  ]);
};

const exportGamesCSV = async () => {
  const games = await Game.find({ isDeleted: false })
    .populate('organizer', 'username')
    .lean();

  return toCSV(games, [
    { label: 'ID', path: '_id' },
    { label: 'Title', path: 'title' },
    { label: 'Sport', path: 'sport' },
    { label: 'Status', path: 'status' },
    { label: 'City', path: 'location.city' },
    { label: 'Neighbourhood', path: 'location.neighbourhood' },
    { label: 'Organizer', path: 'organizer.username' },
    { label: 'Max Players', path: 'maxPlayers' },
    { label: 'Scheduled At', path: 'scheduledAt' },
    { label: 'Created At', path: 'createdAt' },
  ]);
};

// ── Broadcast ─────────────────────────────────────────────────────────────────
const broadcastMessage = async ({ title, body, channel = 'socket' }, io, notificationService) => {
  if (channel === 'socket' || channel === 'both') {
    if (io) {
      io.emit('broadcast', { title, body, sentAt: new Date().toISOString() });
    }
  }

  if (channel === 'email' || channel === 'both') {
    // Send to all non-banned, verified users in batches
    const users = await User.find({
      isDeleted: false,
      isBanned: false,
      isEmailVerified: true,
    }).select('email firstName').lean();

    const batchSize = 50;
    for (let i = 0; i < users.length; i += batchSize) {
      const batch = users.slice(i, i + batchSize);
      await Promise.allSettled(
        batch.map((u) => notificationService.sendEmail(u.email, { title, body, firstName: u.firstName })),
      );
    }
    logger.info(`[Admin] Broadcast email sent to ${users.length} users`);
  }

  logger.info(`[Admin] Broadcast: "${title}" via ${channel}`);
  return { channel, recipients: channel === 'socket' ? 'all connected clients' : 'all email subscribers' };
};

// ── Sports categories ─────────────────────────────────────────────────────────
const getSports = async () =>
  SportCategory.find({ isActive: true }).sort({ sortOrder: 1, name: 1 }).lean();

const createSport = async (data, adminId) => {
  const sport = await SportCategory.create({ ...data, createdBy: adminId });
  return sport;
};

const updateSport = async (sportId, data) => {
  const sport = await SportCategory.findByIdAndUpdate(sportId, data, {
    new: true,
    runValidators: true,
  });
  if (!sport) throw new AppError('Sport category not found', 404);
  return sport;
};

const deleteSport = async (sportId) => {
  const sport = await SportCategory.findByIdAndUpdate(sportId, { isActive: false }, { new: true });
  if (!sport) throw new AppError('Sport category not found', 404);
  logger.info(`[Admin] Sport deactivated: ${sport.name}`);
};

module.exports = {
  getDashboardStats,
  listUsers,
  banUser,
  adminDeleteUser,
  listGames,
  adminDeleteGame,
  exportUsersCSV,
  exportGamesCSV,
  broadcastMessage,
  getSports,
  createSport,
  updateSport,
  deleteSport,
};
