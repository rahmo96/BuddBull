#!/usr/bin/env node
/**
 * Seed sample games into the BuddBull MongoDB database.
 *
 * Creates 20 games across multiple sports, cities, and skill levels.
 * Each game gets an organizer (from existing users), an approved organizer
 * player slot, and a linked group chat — matching normal API behaviour.
 *
 * Usage (from backend/):
 *   node scripts/seed-games.js
 *   node scripts/seed-games.js --count 20
 *   node scripts/seed-games.js --dry-run
 *
 * Environment:
 *   MONGO_URI  MongoDB connection string (reads backend/.env via dotenv)
 *
 * Prerequisites:
 *   At least one user document in the `users` collection.
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
  'soccer',
  'basketball',
  'tennis',
  'volleyball',
  'cricket',
  'badminton',
  'rugby',
  'running',
  'cycling',
  'swimming',
  'yoga',
  'boxing',
  'golf',
  'hockey',
  'martial arts',
  'table tennis',
  'baseball',
  'gym',
  'other',
];

const SKILL_LEVELS = ['any', 'beginner', 'intermediate', 'advanced', 'professional'];

const VENUES = [
  {
    venueName: 'Central Park Great Lawn',
    neighborhood: 'Upper East Side',
    city: 'New York',
    state: 'NY',
    country: 'US',
    formattedAddress: 'Central Park, New York, NY 10024, USA',
    coordinates: [-73.9654, 40.7829],
  },
  {
    venueName: 'Venice Beach Courts',
    neighborhood: 'Venice',
    city: 'Los Angeles',
    state: 'CA',
    country: 'US',
    formattedAddress: '1800 Ocean Front Walk, Venice, CA 90291, USA',
    coordinates: [-118.4695, 33.985],
  },
  {
    venueName: 'Grant Park Fields',
    neighborhood: 'Loop',
    city: 'Chicago',
    state: 'IL',
    country: 'US',
    formattedAddress: '337 E Randolph St, Chicago, IL 60601, USA',
    coordinates: [-87.6197, 41.8826],
  },
  {
    venueName: 'Hyde Park Pitch',
    neighborhood: 'Hyde Park',
    city: 'London',
    state: 'England',
    country: 'GB',
    formattedAddress: 'Hyde Park, London W2 2UH, UK',
    coordinates: [-0.1657, 51.5073],
  },
  {
    venueName: 'Heaton Park',
    neighborhood: 'Heaton Park',
    city: 'Manchester',
    state: 'England',
    country: 'GB',
    formattedAddress: 'Middleton Rd, Manchester M25 2SW, UK',
    coordinates: [-2.2494, 53.5314],
  },
  {
    venueName: 'Zilker Park',
    neighborhood: 'Zilker',
    city: 'Austin',
    state: 'TX',
    country: 'US',
    formattedAddress: '2100 Barton Springs Rd, Austin, TX 78746, USA',
    coordinates: [-97.7713, 30.2669],
  },
  {
    venueName: 'Gas Works Park',
    neighborhood: 'Wallingford',
    city: 'Seattle',
    state: 'WA',
    country: 'US',
    formattedAddress: '2101 N Northlake Way, Seattle, WA 98103, USA',
    coordinates: [-122.3348, 47.6456],
  },
  {
    venueName: 'Boston Common',
    neighborhood: 'Downtown',
    city: 'Boston',
    state: 'MA',
    country: 'US',
    formattedAddress: '139 Tremont St, Boston, MA 02111, USA',
    coordinates: [-71.0636, 42.3554],
  },
  {
    venueName: 'Bayfront Park',
    neighborhood: 'Downtown',
    city: 'Miami',
    state: 'FL',
    country: 'US',
    formattedAddress: '301 N Biscayne Blvd, Miami, FL 33132, USA',
    coordinates: [-80.1859, 25.7753],
  },
  {
    venueName: 'Washington Park',
    neighborhood: 'Capitol Hill',
    city: 'Denver',
    state: 'CO',
    country: 'US',
    formattedAddress: '701 E Colfax Ave, Denver, CO 80203, USA',
    coordinates: [-104.9719, 39.7392],
  },
];

const TITLE_PREFIX = {
  football: 'Sunday Football',
  soccer: 'Pickup Soccer',
  basketball: 'Hoops Night',
  tennis: 'Tennis Doubles',
  volleyball: 'Beach Volleyball',
  cricket: 'Cricket Match',
  badminton: 'Badminton Rally',
  rugby: 'Touch Rugby',
  running: 'Group Run',
  cycling: 'Weekend Ride',
  swimming: 'Open Water Swim',
  yoga: 'Sunrise Yoga',
  boxing: 'Boxing Sparring',
  golf: 'Nine-Hole Golf',
  hockey: 'Street Hockey',
  'martial arts': 'Martial Arts Drills',
  'table tennis': 'Table Tennis Club',
  baseball: 'Softball Game',
  gym: 'CrossFit Session',
  other: 'Community Activity',
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

  await mongoose.disconnect().catch(() => {});
  process.exit(1);
});
