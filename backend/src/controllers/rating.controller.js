const ratingService = require('../services/rating.service');
const catchAsync = require('../utils/catchAsync');

exports.ratePlayer = catchAsync(async (req, res) => {
  const rating = await ratingService.ratePlayer({ raterId: req.user._id, ...req.body });
  res.status(201).json({ success: true, data: { rating } });
});

exports.getProfileSummary = catchAsync(async (req, res) => {
  const summary = await ratingService.getProfileSummary(req.params.userId);
  res.status(200).json({ success: true, data: { summary } });
});

exports.getMyReceivedRatings = catchAsync(async (req, res) => {
  const result = await ratingService.getRatingsForUser(req.user._id, req.query);
  res.status(200).json({ success: true, data: result });
});

exports.getMyGivenRatings = catchAsync(async (req, res) => {
  const result = await ratingService.getRatingsGivenByUser(req.user._id, req.query);
  res.status(200).json({ success: true, data: result });
});

exports.getPendingRatings = catchAsync(async (req, res) => {
  const pending = await ratingService.getPendingRatings(req.user._id);
  res.status(200).json({ success: true, data: { pending } });
});
