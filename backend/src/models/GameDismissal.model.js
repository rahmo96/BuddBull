const mongoose = require('mongoose');

/**
 * Records that a user chose to dismiss/archive a game from their home
 * screen feed without leaving or deleting the underlying game. Used
 * exclusively as a viewer-side filter in `getMyGames` / `getCalendar`
 * so a completed (or otherwise sticky) game can be hidden from a
 * specific user while remaining intact for everyone else.
 *
 * This is intentionally one row per (user, game) — re-dismissing is
 * idempotent and re-surfacing a game means deleting the row.
 */
const gameDismissalSchema = new mongoose.Schema(
  {
    user: {
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

gameDismissalSchema.index({ user: 1, game: 1 }, { unique: true });

module.exports =
  mongoose.models.GameDismissal || mongoose.model('GameDismissal', gameDismissalSchema);
