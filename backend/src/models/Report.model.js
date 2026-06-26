const mongoose = require('mongoose');

const REPORT_TARGET_TYPES = ['user', 'game'];
const REPORT_STATUSES = ['open', 'in_progress', 'closed'];
const REPORT_CATEGORIES = ['harassment', 'unsafe_play', 'cheating', 'other'];

const reportSchema = new mongoose.Schema(
  {
    reporter: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    targetType: {
      type: String,
      enum: REPORT_TARGET_TYPES,
      required: true,
    },
    reportedUser: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    reportedGame: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Game',
      default: null,
    },
    title: {
      type: String,
      required: true,
      trim: true,
      maxlength: 120,
    },
    reason: {
      type: String,
      required: true,
      trim: true,
      maxlength: 2000,
    },
    category: {
      type: String,
      enum: REPORT_CATEGORIES,
      default: 'other',
    },
    status: {
      type: String,
      enum: REPORT_STATUSES,
      default: 'open',
      index: true,
    },
    adminNotes: {
      type: String,
      trim: true,
      maxlength: 2000,
      default: '',
    },
    closedAt: { type: Date, default: null },
    closedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    deletedAt: { type: Date, default: null },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  },
);

reportSchema.index({ status: 1, createdAt: -1 });
reportSchema.index({ targetType: 1, createdAt: -1 });
reportSchema.index({ reporter: 1, createdAt: -1 });

reportSchema.statics.TARGET_TYPES = REPORT_TARGET_TYPES;
reportSchema.statics.STATUSES = REPORT_STATUSES;
reportSchema.statics.CATEGORIES = REPORT_CATEGORIES;

module.exports =
  mongoose.models.Report || mongoose.model('Report', reportSchema);
