#!/usr/bin/env node
/**
 * Seed rich performance history for a single demo user.
 *
 * Powers the Performance Center: heatmap, weekly charts, streak banner,
 * sport breakdown, personal bests, and profile session counts.
 *
 * Usage (from backend/):
 *   node scripts/seed-demo-activity.js --user <mongoId|email>
 *   node scripts/seed-demo-activity.js --user <id> --days 90
 *   node scripts/seed-demo-activity.js --user <id> --clear
 *   node scripts/seed-demo-activity.js --user <id> --dry-run
 *
 * Environment:
 *   MONGO_URI  MongoDB connection string (reads backend/.env via dotenv)
 */

const path = require('path');

require('dotenv').config({ path: path.join(__dirname, '../.env') });

const mongoose = require('mongoose');
const PerformanceLog = require('../src/models/PerformanceLog.model');
const User = require('../src/models/User.model');

const DEFAULT_DAYS = 90;

const SPORTS = [
  'football',
  'basketball',
  'tennis',
  'volleyball',
  'running',
  'cycling',
  'swimming',
];

const MOODS = ['good', 'excellent', 'neutral', 'good', 'excellent'];

const SPORT_STATS = {
  football: [
    { key: 'goals', unit: 'goals' },
    { key: 'assists', unit: 'assists' },
  ],
  basketball: [
    { key: 'points', unit: 'pts' },
    { key: 'rebounds', unit: 'reb' },
  ],
  tennis: [{ key: 'aces', unit: 'aces' }],
  volleyball: [{ key: 'spikes', unit: 'spikes' }],
  running: [{ key: 'distanceKm', unit: 'km' }],
  cycling: [{ key: 'distanceKm', unit: 'km' }],
  swimming: [{ key: 'laps', unit: 'laps' }],
};

const parseArgs = () => {
  const args = process.argv.slice(2);
  let user = null;
  let days = DEFAULT_DAYS;
  let dryRun = false;
  let clear = false;

  for (let i = 0; i < args.length; i += 1) {
    if (args[i] === '--user' && args[i + 1]) {
      user = args[i + 1];
      i += 1;
    } else if (args[i] === '--days' && args[i + 1]) {
      days = Math.max(7, parseInt(args[i + 1], 10) || DEFAULT_DAYS);
      i += 1;
    } else if (args[i] === '--dry-run') {
      dryRun = true;
    } else if (args[i] === '--clear') {
      clear = true;
    }
  }

  return { user, days, dryRun, clear };
};

const resolveUser = async (identifier) => {
  if (mongoose.Types.ObjectId.isValid(identifier)) {
    return User.findById(identifier).where({ deletedAt: null });
  }
  return User.findOne({ email: identifier.toLowerCase(), deletedAt: null });
};

const startOfDay = (date) => {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
};

const atTime = (day, hour, minute = 0) => {
  const d = startOfDay(day);
  d.setHours(hour, minute, 0, 0);
  return d;
};

const pick = (arr, index) => arr[index % arr.length];

const shouldBeActiveDay = (dayIndex, totalDays) => {
  // Keep the last 45 days fully active for a strong streak + heatmap.
  if (dayIndex >= totalDays - 45) return true;
  // Earlier history: ~85% active days for a realistic but busy account.
  return dayIndex % 7 !== 3 && dayIndex % 11 !== 5;
};

const buildSession = (userId, loggedAt, sessionIndex) => {
  const sport = pick(SPORTS, sessionIndex);
  const typeRoll = sessionIndex % 10;
  const type = typeRoll < 5 ? 'match' : typeRoll < 8 ? 'training' : 'fitness';

  const durationMinutes = 45 + (sessionIndex % 6) * 15;
  const statDefs = SPORT_STATS[sport] || [{ key: 'sessions', unit: 'count' }];
  const stats = statDefs.map((def, i) => ({
    key: def.key,
    unit: def.unit,
    value: 1 + ((sessionIndex + i * 3) % 5),
  }));

  const matchOutcome =
    type === 'match'
      ? sessionIndex % 10 < 6
        ? 'win'
        : sessionIndex % 10 < 9
          ? 'loss'
          : 'draw'
      : undefined;

  const distanceKm =
    sport === 'running' || sport === 'cycling'
      ? Number((3 + (sessionIndex % 12) * 0.75).toFixed(1))
      : undefined;

  const newPersonalBests = [];
  if (sessionIndex > 0 && sessionIndex % 17 === 0) {
    const pbStat = stats[0];
    newPersonalBests.push({
      metric: pbStat.key,
      value: pbStat.value,
      unit: pbStat.unit,
      achievedAt: loggedAt,
    });
  }

  return {
    user: userId,
    game: null,
    type,
    sport,
    loggedAt,
    matchOutcome,
    opponentDescription: type === 'match' ? 'Local pickup squad' : undefined,
    durationMinutes,
    stats,
    physicalMetrics: {
      caloriesBurned: 280 + (sessionIndex % 8) * 70,
      averageHeartRate: 118 + (sessionIndex % 5) * 8,
      ...(distanceKm ? { distanceKm } : {}),
      perceivedExertion: 4 + (sessionIndex % 5),
    },
    mood: pick(MOODS, sessionIndex),
    selfRating: 3 + (sessionIndex % 3),
    notes: 'Seeded demo session',
    newPersonalBests,
    isPublic: sessionIndex % 4 === 0,
    deletedAt: null,
  };
};

const buildActivityPlan = (userId, days) => {
  const today = startOfDay(new Date());
  const sessions = [];

  for (let dayOffset = days; dayOffset >= 0; dayOffset -= 1) {
    const dayIndex = days - dayOffset;
    if (!shouldBeActiveDay(dayIndex, days)) continue;

    const day = new Date(today);
    day.setDate(day.getDate() - dayOffset);

    const sessionCount = dayOffset <= 14 && dayOffset % 3 === 0 ? 2 : 1;
    for (let s = 0; s < sessionCount; s += 1) {
      const hour = 7 + ((dayIndex + s * 4) % 12);
      const minute = (dayIndex * 13 + s * 20) % 60;
      sessions.push(buildSession(userId, atTime(day, hour, minute), sessions.length));
    }
  }

  sessions.sort((a, b) => a.loggedAt - b.loggedAt);
  return sessions;
};

const applyStreakSnapshots = (user, sessions) => {
  user.stats = user.stats || {};
  user.stats.currentStreak = 0;
  user.stats.longestStreak = 0;
  user.stats.lastActivityDate = null;

  for (const session of sessions) {
    user.updateStreak(session.loggedAt);
    session.streakAtLog = {
      current: user.stats.currentStreak,
      isStreakDay: true,
    };
  }
};

const summarize = (sessions) => {
  const matchLogs = sessions.filter((s) => s.type === 'match');
  const wins = matchLogs.filter((s) => s.matchOutcome === 'win').length;
  const totalMinutes = sessions.reduce((sum, s) => sum + (s.durationMinutes || 0), 0);
  const sports = [...new Set(sessions.map((s) => s.sport))];

  return {
    totalSessions: sessions.length,
    matchSessions: matchLogs.length,
    wins,
    totalMinutes,
    sports,
    personalBests: sessions.filter((s) => s.newPersonalBests.length > 0).length,
  };
};

const main = async () => {
  const { user: userRef, days, dryRun, clear } = parseArgs();

  if (!userRef) {
    console.error('Missing --user <mongoId|email>');
    console.error('Example: node scripts/seed-demo-activity.js --user 674a1b2c3d4e5f6789012345');
    process.exit(1);
  }

  const mongoUri = process.env.MONGO_URI;
  if (!mongoUri) {
    console.error('MONGO_URI is not set. Add it to backend/.env or export it in your shell.');
    process.exit(1);
  }

  await mongoose.connect(mongoUri);
  console.log(`Connected to MongoDB (${mongoose.connection.name})`);

  const user = await resolveUser(userRef);
  if (!user) {
    console.error(`User not found: ${userRef}`);
    await mongoose.disconnect();
    process.exit(1);
  }

  const sessions = buildActivityPlan(user._id, days);
  applyStreakSnapshots(user, sessions);
  const summary = summarize(sessions);

  console.log(`Target user: ${user.firstName || ''} ${user.lastName || ''} (${user.email || user._id})`);
  console.log(`Plan: ${summary.totalSessions} sessions over ${days} days`);
  console.log(
    `  ${summary.matchSessions} matches (${summary.wins} wins), ${summary.totalMinutes} total minutes, ${summary.sports.length} sports`,
  );
  console.log(
    `  Streak after seed: current=${user.stats.currentStreak}, longest=${user.stats.longestStreak}`,
  );

  if (dryRun) {
    console.log('\nDry run — no database changes made.');
    const first = sessions[0]?.loggedAt?.toISOString().slice(0, 10);
    const last = sessions[sessions.length - 1]?.loggedAt?.toISOString().slice(0, 10);
    console.log(`  Date range: ${first} → ${last}`);
    await mongoose.disconnect();
    return;
  }

  if (clear) {
    const removed = await PerformanceLog.deleteMany({ user: user._id });
    console.log(`Cleared ${removed.deletedCount} existing performance log(s) for this user.`);
  }

  await PerformanceLog.insertMany(sessions);

  user.stats.gamesPlayed = (user.stats.gamesPlayed || 0) + summary.matchSessions;
  user.stats.gamesWon = (user.stats.gamesWon || 0) + summary.wins;
  await user.save({ validateBeforeSave: false });

  console.log(`\nDone. Inserted ${sessions.length} performance log(s).`);
  console.log('Open the Performance tab in the app and pull to refresh.');
  await mongoose.disconnect();
};

main().catch(async (err) => {
  console.error('Seed failed:', err.message);
  await mongoose.disconnect().catch(() => {});
  process.exit(1);
});
