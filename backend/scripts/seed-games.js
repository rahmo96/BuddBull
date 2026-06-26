#!/usr/bin/env node
/**
 * Seed sample games into the BuddBull MongoDB database.
 *
 * Creates 20 games across multiple sports, cities, and skill levels.
 * Each game gets an organizer (from existing users), an approved organizer
 * player slot, and a linked group chat — matching normal API behaviour.
 *
 * Usage (from backend/):
 * node scripts/seed-games.js
 * node scripts/seed-games.js --count 20
 * node scripts/seed-games.js --dry-run
 *
 * Environment:
 * MONGO_URI  MongoDB connection string (reads backend/.env via dotenv)
 *
 * Prerequisites:
 * At least one user document in the `users` collection.
 */

const path = require('path');

require('dotenv').config({ path: path.join(__dirname, '../.env') });

const mongoose = require('mongoose');
const Game = require('../src/models/Game.model');
const Chat = require('../src/models/Chat.model');
const User = require('../src/models/User.model');

const DEFAULT_COUNT = 20;

const SPORTS = [
  'football',
  'basketball',
  'tennis',
  'volleyball',
  'cricket',
  'running',
  'cycling',
  'swimming',
];

const SKILL_LEVELS = ['any', 'beginner', 'intermediate', 'advanced', 'professional'];

const VENUES = [
  {
    venueName: 'מגרש קט-רגל - מכללת סמי שמעון (SCE)',
    neighborhood: 'רובע ב',
    city: 'Ashdod',
    state: 'South District',
    country: 'IL',
    formattedAddress: 'Bialik St 56, Ashdod, Israel',
    coordinates: [34.6465, 31.8054],
  },
  {
    venueName: 'אצטדיון סלה',
    neighborhood: 'רמת אשכול',
    city: 'Ashkelon',
    state: 'South District',
    country: 'IL',
    formattedAddress: 'Sela Stadium, Ashkelon, Israel',
    coordinates: [34.5775, 31.6667],
  },
  {
    venueName: 'פארק אשדוד ים',
    neighborhood: 'רובע יא',
    city: 'Ashdod',
    state: 'South District',
    country: 'IL',
    formattedAddress: 'Sderot Moshe Dayan, Ashdod, Israel',
    coordinates: [34.6318, 31.7891],
  },
  {
    venueName: 'פארק אגמים',
    neighborhood: 'אגמים',
    city: 'Ashkelon',
    state: 'South District',
    country: 'IL',
    formattedAddress: 'Agamim, Ashkelon, Israel',
    coordinates: [34.5822, 31.6483],
  },
  {
    venueName: 'ספורטק אשדוד',
    neighborhood: 'רובע יג',
    city: 'Ashdod',
    state: 'South District',
    country: 'IL',
    formattedAddress: 'Bne Brit Blvd, Ashdod, Israel',
    coordinates: [34.6541, 31.7772],
  }
];

const TITLE_PREFIX = {
  football: 'Sunday Football',
  basketball: 'Hoops Night',
  tennis: 'Tennis Doubles',
  volleyball: 'Beach Volleyball',
  cricket: 'Cricket Match',
  running: 'Group Run',
  cycling: 'Weekend Ride',
  swimming: 'Open Water Swim',
};

const DURATIONS = [60, 75, 90, 120];
const MAX_PLAYERS = [6, 8, 10, 12, 14, 16, 20];

const parseArgs = () => {
  const args = process.argv.slice(2);
  let count = DEFAULT_COUNT;
  let dryRun = false;

  for (let i = 0; i < args.length; i += 1) {
    if (args[i] === '--count' && args[i + 1]) {
      count = Math.max(1, parseInt(args[i + 1], 10) || DEFAULT_COUNT);
      i += 1;
    } else if (args[i] === '--dry-run') {
      dryRun = true;
    }
  }

  return { count, dryRun };
};

const daysFromNow = (days, hour = 18, minute = 0) => {
  const d = new Date();
  d.setDate(d.getDate() + days);
  d.setHours(hour, minute, 0, 0);
  return d;
};

const organizerSlot = (userId) => ({
  user: userId,
  status: 'approved',
  role: 'co-organizer',
  joinedAt: new Date(),
});

const buildGamePayload = (index, organizerId, extraPlayerIds = []) => {
  const sport = SPORTS[index % SPORTS.length];
  const venue = VENUES[index % VENUES.length];
  const dayOffset = 1 + (index % 28);
  const hour = 7 + (index % 12);
  const maxPlayers = MAX_PLAYERS[index % MAX_PLAYERS.length];
  const status = index % 10 === 0 ? 'draft' : 'open';

  const players = [organizerSlot(organizerId)];

  extraPlayerIds.slice(0, maxPlayers - 1).forEach((userId) => {
    players.push({
      user: userId,
      status: 'approved',
      role: 'player',
      joinedAt: new Date(),
    });
  });

  const approvedCount = players.filter((p) => p.status === 'approved').length;
  const resolvedStatus =
    status === 'open' && approvedCount >= maxPlayers ? 'full' : status;

  return {
    title: `${TITLE_PREFIX[sport] || 'Community Game'} #${index + 1}`,
    description: `Seed game for ${sport} in ${venue.city}. All skill levels welcome — bring water and good vibes.`,
    sport,
    tags: [sport.replace(/\s+/g, '-'), venue.city.toLowerCase(), 'pickup'],
    organizer: organizerId,
    scheduledAt: daysFromNow(dayOffset, hour, (index * 15) % 60),
    durationMinutes: DURATIONS[index % DURATIONS.length],
    location: {
      venueName: venue.venueName,
      address: venue.formattedAddress,
      formattedAddress: venue.formattedAddress,
      placeId: `seed-place-${index + 1}`,
      neighborhood: venue.neighborhood,
      city: venue.city,
      state: venue.state,
      country: venue.country,
      coordinates: {
        type: 'Point',
        coordinates: venue.coordinates,
      },
    },
    maxPlayers,
    minPlayersToStart: Math.min(4, maxPlayers),
    players,
    requiredSkillLevel: SKILL_LEVELS[index % SKILL_LEVELS.length],
    status: resolvedStatus,
    isPrivate: index % 9 === 0,
    requiresApproval: index % 7 === 0,
    allowSpectators: index % 5 !== 0,
  };
};

const createGameWithChat = async (payload) => {
  const game = new Game(payload);
  await game.save();

  const chat = await Chat.create({
    type: 'group',
    name: `${payload.title} — Chat`,
    game: game._id,
    participants: [{ user: payload.organizer, isAdmin: true }],
  });

  game.groupChat = chat._id;
  await game.save();

  await User.findByIdAndUpdate(payload.organizer, { $inc: { 'stats.gamesOrganized': 1 } });

  return game;
};

const main = async () => {
  const { count, dryRun } = parseArgs();
  const mongoUri = process.env.MONGO_URI;

  if (!mongoUri) {
    console.error('MONGO_URI is not set. Add it to backend/.env or export it in your shell.');
    process.exit(1);
  }

  await mongoose.connect(mongoUri);
  console.log(`Connected to MongoDB (${mongoose.connection.name})`);

  const users = await User.find({ deletedAt: null }).select('_id firstName lastName').limit(50).lean();

  if (users.length === 0) {
    console.error('No users found. Register at least one user in the app before seeding games.');
    await mongoose.disconnect();
    process.exit(1);
  }

  console.log(`Using ${users.length} user(s) as organizers`);
  if (dryRun) {
    console.log(`Dry run — would create ${count} game(s):`);
    for (let i = 0; i < count; i += 1) {
      const organizer = users[i % users.length];
      const extras = users.filter((u) => u._id.toString() !== organizer._id.toString()).slice(0, 3);
      const payload = buildGamePayload(
        i,
        organizer._id,
        extras.map((u) => u._id),
      );
      console.log(`  ${i + 1}. ${payload.title} (${payload.sport}, ${payload.location.city}, ${payload.status})`);
    }
    await mongoose.disconnect();
    return;
  }

  const created = [];

  for (let i = 0; i < count; i += 1) {
    const organizer = users[i % users.length];
    const extras = users.filter((u) => u._id.toString() !== organizer._id.toString()).slice(0, 3);
    const payload = buildGamePayload(
      i,
      organizer._id,
      extras.map((u) => u._id),
    );

    const game = await createGameWithChat(payload);
    created.push(game);
    console.log(`Created: ${game.title} [${game.sport}] — ${game.location.city} (${game._id})`);
  }

  console.log(`\nDone. Inserted ${created.length} game(s) into the games collection.`);
  await mongoose.disconnect();
};

main().catch(async (err) => {
  console.error('Seed failed:', err.message);

  if (err.code === 'ECONNREFUSED' && err.syscall === 'querySrv') {
    console.error(`
DNS SRV lookup failed for your mongodb+srv:// URI (common on Windows / some routers).
Fix: In Atlas → Connect → Drivers, copy the "Standard connection string" and set MONGO_URI in backend/.env.
It should look like:
  mongodb://<user>:<pass>@host1:27017,host2:27017,host3:27017/buddbull?ssl=true&replicaSet=...&authSource=admin
Or switch your PC DNS to 1.1.1.1 / 8.8.8.8 and retry the SRV URI.`);
  }

  await mongoose.disconnect().catch(() => { });
  process.exit(1);
});