#!/usr/bin/env node
/**
 * Remove games whose sport is not in the BuddBull allowed list.
 *
 * Usage (from backend/):
 *   node scripts/cleanup-invalid-sports.js --dry-run
 *   node scripts/cleanup-invalid-sports.js
 */

const path = require('path');

require('dotenv').config({ path: path.join(__dirname, '../.env') });

const mongoose = require('mongoose');
const Game = require('../src/models/Game.model');
const Chat = require('../src/models/Chat.model');
const Message = require('../src/models/Message.model');
const Rating = require('../src/models/Rating.model');
const RatingDismissal = require('../src/models/RatingDismissal.model');
const PerformanceLog = require('../src/models/PerformanceLog.model');
const Notification = require('../src/models/Notification.model');

const ALLOWED_SPORTS = [
  'football',
  'basketball',
  'tennis',
  'swimming',
  'cycling',
  'running',
  'cricket',
  'volleyball',
];

const parseArgs = () => ({
  dryRun: process.argv.includes('--dry-run'),
});

const main = async () => {
  const { dryRun } = parseArgs();
  const mongoUri = process.env.MONGO_URI;

  if (!mongoUri) {
    console.error('MONGO_URI is not set. Add it to backend/.env or export it in your shell.');
    process.exit(1);
  }

  await mongoose.connect(mongoUri);
  console.log(`Connected to MongoDB (${mongoose.connection.name})`);
  console.log(`Allowed sports: ${ALLOWED_SPORTS.join(', ')}`);
  if (dryRun) console.log('DRY RUN — no documents will be deleted.\n');

  const invalidGames = await Game.find({
    sport: { $nin: ALLOWED_SPORTS },
  })
    .select('_id title sport status groupChat')
    .lean();

  if (invalidGames.length === 0) {
    console.log('No games with disallowed sports found.');
    await mongoose.disconnect();
    return;
  }

  const gameIds = invalidGames.map((g) => g._id);
  const chatIds = invalidGames.map((g) => g.groupChat).filter(Boolean);

  const sportCounts = invalidGames.reduce((acc, g) => {
    acc[g.sport] = (acc[g.sport] || 0) + 1;
    return acc;
  }, {});

  console.log(`Found ${invalidGames.length} game(s) to remove:`);
  Object.entries(sportCounts)
    .sort((a, b) => b[1] - a[1])
    .forEach(([sport, count]) => console.log(`  - ${sport}: ${count}`));

  const [chatCount, messageCount, ratingCount, dismissalCount, logCount, notificationCount] =
    await Promise.all([
      Chat.countDocuments({ $or: [{ game: { $in: gameIds } }, { _id: { $in: chatIds } }] }),
      chatIds.length > 0 ? Message.countDocuments({ chat: { $in: chatIds } }) : 0,
      Rating.countDocuments({ game: { $in: gameIds } }),
      RatingDismissal.countDocuments({ game: { $in: gameIds } }),
      PerformanceLog.countDocuments({ game: { $in: gameIds } }),
      Notification.countDocuments({ 'data.gameId': { $in: gameIds.map(String) } }),
    ]);

  console.log('\nRelated documents:');
  console.log(`  chats: ${chatCount}`);
  console.log(`  messages: ${messageCount}`);
  console.log(`  ratings: ${ratingCount}`);
  console.log(`  rating dismissals: ${dismissalCount}`);
  console.log(`  performance logs: ${logCount}`);
  console.log(`  notifications: ${notificationCount}`);

  if (dryRun) {
    console.log('\nSample games:');
    invalidGames.slice(0, 10).forEach((g) => {
      console.log(`  ${g._id} — ${g.title} [${g.sport}] (${g.status})`);
    });
    if (invalidGames.length > 10) {
      console.log(`  ... and ${invalidGames.length - 10} more`);
    }
    await mongoose.disconnect();
    return;
  }

  if (chatIds.length > 0) {
    await Message.deleteMany({ chat: { $in: chatIds } });
  }
  await Chat.deleteMany({ $or: [{ game: { $in: gameIds } }, { _id: { $in: chatIds } }] });
  await Rating.deleteMany({ game: { $in: gameIds } });
  await RatingDismissal.deleteMany({ game: { $in: gameIds } });
  await PerformanceLog.deleteMany({ game: { $in: gameIds } });
  await Notification.deleteMany({ 'data.gameId': { $in: gameIds.map(String) } });
  const gameResult = await Game.deleteMany({ _id: { $in: gameIds } });

  console.log(`\nDeleted ${gameResult.deletedCount} game(s) and related data.`);

  const remaining = await Game.aggregate([
    { $group: { _id: '$sport', count: { $sum: 1 } } },
    { $sort: { _id: 1 } },
  ]);
  console.log('\nRemaining games by sport:');
  remaining.forEach((row) => console.log(`  ${row._id}: ${row.count}`));

  await mongoose.disconnect();
};

main().catch((err) => {
  console.error(err);
  mongoose.disconnect().finally(() => process.exit(1));
});
