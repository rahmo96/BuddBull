const mongoose = require('mongoose');

/**
 * Records that a user chose not to submit peer ratings for a completed game.
 * Excludes the game from getPendingRatings / calendar "rate me" surfacing for that user.
 */
const ratingDismissalSchema = new mongoose.Schema(
  {
    rater: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    game: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Game',
      required: true,
      index: true,
    },
  },
  { timestamps: true },
);

ratingDismissalSchema.index({ rater: 1, game: 1 }, { unique: true });

module.exports =
  mongoose.models.RatingDismissal || mongoose.model('RatingDismissal', ratingDismissalSchema);
