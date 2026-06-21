const reportService = require('../services/report.service');
const catchAsync = require('../utils/catchAsync');

exports.create = catchAsync(async (req, res) => {
  const report = await reportService.createReport(req.user._id, req.body);
  res.status(201).json({
    success: true,
    message: 'Report submitted successfully',
    data: { report },
  });
});

exports.listMine = catchAsync(async (req, res) => {
  const result = await reportService.listMyReports(req.user._id, req.query);
  res.status(200).json({ success: true, data: result });
});

exports.listAdmin = catchAsync(async (req, res) => {
  const result = await reportService.listReportsAdmin(req.query);
  res.status(200).json({ success: true, data: result });
});

exports.updateAdmin = catchAsync(async (req, res) => {
  const report = await reportService.updateReportAdmin(
    req.params.reportId,
    req.user._id,
    req.body,
  );
  res.status(200).json({
    success: true,
    message: 'Report updated',
    data: { report },
  });
});
