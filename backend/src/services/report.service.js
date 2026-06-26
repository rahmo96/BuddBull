const Report = require('../models/Report.model');
const User = require('../models/User.model');
const Game = require('../models/Game.model');
const AppError = require('../utils/AppError');
const notificationInbox = require('./notificationInbox.service');
const logger = require('../utils/logger');

const DUPLICATE_WINDOW_MS = 24 * 60 * 60 * 1000;

const _populateFields = [
  { path: 'reporter', select: 'username firstName lastName profilePicture' },
  { path: 'reportedUser', select: 'username firstName lastName profilePicture' },
  { path: 'reportedGame', select: 'title sport status scheduledAt' },
  { path: 'closedBy', select: 'username firstName lastName' },
];

const createReport = async (reporterId, { targetType, reportedUserId, reportedGameId, title, reason, category }) => {
  if (targetType === 'user') {
    if (!reportedUserId) throw new AppError('reportedUserId is required for user reports', 400);
    if (reportedUserId.toString() === reporterId.toString()) {
      throw new AppError('You cannot report yourself', 400);
    }
    const user = await User.findOne({ _id: reportedUserId, deletedAt: null });
    if (!user) throw new AppError('Reported user not found', 404);
  } else if (targetType === 'game') {
    if (!reportedGameId) throw new AppError('reportedGameId is required for game reports', 400);
    const game = await Game.findOne({ _id: reportedGameId, deletedAt: null });
    if (!game) throw new AppError('Reported game not found', 404);
  } else {
    throw new AppError('Invalid target type', 400);
  }

  const duplicateFilter = {
    reporter: reporterId,
    targetType,
    status: { $in: ['open', 'in_progress'] },
    deletedAt: null,
    createdAt: { $gte: new Date(Date.now() - DUPLICATE_WINDOW_MS) },
  };
  if (targetType === 'user') duplicateFilter.reportedUser = reportedUserId;
  if (targetType === 'game') duplicateFilter.reportedGame = reportedGameId;

  const existing = await Report.findOne(duplicateFilter).select('_id');
  if (existing) {
    throw new AppError('You already have an open report for this target. Please wait for it to be reviewed.', 409);
  }

  const report = await Report.create({
    reporter: reporterId,
    targetType,
    reportedUser: targetType === 'user' ? reportedUserId : null,
    reportedGame: targetType === 'game' ? reportedGameId : null,
    title,
    reason,
    category: category || 'other',
  });

  logger.info(`[Report] Created ${report._id} by ${reporterId} (${targetType})`);
  return report.populate(_populateFields);
};

const listMyReports = async (reporterId, { page = 1, limit = 20 } = {}) => {
  const pageNum = Math.max(1, Number(page) || 1);
  const pageSize = Math.min(50, Math.max(1, Number(limit) || 20));
  const skip = (pageNum - 1) * pageSize;

  const filter = { reporter: reporterId, deletedAt: null };

  const [reports, total] = await Promise.all([
    Report.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(pageSize)
      .populate(_populateFields)
      .lean(),
    Report.countDocuments(filter),
  ]);

  return {
    reports,
    total,
    page: pageNum,
    totalPages: Math.ceil(total / pageSize) || 1,
  };
};

const listReportsAdmin = async ({
  page = 1,
  limit = 20,
  status,
  targetType,
  sort = '-createdAt',
} = {}) => {
  const pageNum = Math.max(1, Number(page) || 1);
  const pageSize = Math.min(100, Math.max(1, Number(limit) || 20));
  const skip = (pageNum - 1) * pageSize;

  const filter = { deletedAt: null };
  if (status) filter.status = status;
  if (targetType) filter.targetType = targetType;

  const sortField = sort.startsWith('-') ? sort.slice(1) : sort;
  const sortDir = sort.startsWith('-') ? -1 : 1;

  const [reports, total] = await Promise.all([
    Report.find(filter)
      .sort({ [sortField]: sortDir })
      .skip(skip)
      .limit(pageSize)
      .populate(_populateFields)
      .lean(),
    Report.countDocuments(filter),
  ]);

  return {
    reports,
    total,
    page: pageNum,
    totalPages: Math.ceil(total / pageSize) || 1,
  };
};

const updateReportAdmin = async (reportId, adminId, { status, adminNotes } = {}) => {
  const report = await Report.findOne({ _id: reportId, deletedAt: null });
  if (!report) throw new AppError('Report not found', 404);

  const previousStatus = report.status;

  if (status) report.status = status;
  if (adminNotes !== undefined) report.adminNotes = adminNotes;

  if (status === 'closed' && previousStatus !== 'closed') {
    report.closedAt = new Date();
    report.closedBy = adminId;
  } else if (status && status !== 'closed') {
    report.closedAt = null;
    report.closedBy = null;
  }

  await report.save();
  await report.populate(_populateFields);

  if (status === 'closed' && previousStatus !== 'closed') {
    await notificationInbox.createForUser(report.reporter, {
      type: 'reportClosed',
      title: 'Your report has been closed',
      body: `Your report "${report.title}" has been reviewed and closed.`,
      data: {
        reportId: String(report._id),
        status: report.status,
        targetType: report.targetType,
      },
    });
  }

  logger.info(`[Report] Updated ${reportId} by admin ${adminId} → status=${report.status}`);
  return report;
};

module.exports = {
  createReport,
  listMyReports,
  listReportsAdmin,
  updateReportAdmin,
};
