/**
 * BuddBull — seed 20 games (mongosh / MongoDB Compass script)
 *
 * Run with mongosh:
 *   mongosh "mongodb://127.0.0.1:27017/buddbull" --file docs/seed-games.mongodb.js
 *
 * Or paste into MongoDB Compass → Mongosh tab.
 *
 * Prerequisites:
 *   At least one document in the `users` collection (used as organizer).
 *
 * Note: This inserts directly into `games` without creating linked `chats`
 * documents. Prefer `backend/scripts/seed-games.js` for full app parity.
 */

const organizers = db.users.find({ deletedAt: null }, { _id: 1 }).limit(20).toArray();

if (organizers.length === 0) {
  print('ERROR: No users found. Register at least one user before seeding games.');
  quit(1);
}

const sports = [
  'football', 'soccer', 'basketball', 'tennis', 'volleyball',
  'cricket', 'badminton', 'rugby', 'running', 'cycling',
  'swimming', 'yoga', 'boxing', 'golf', 'hockey',
  'martial arts', 'table tennis', 'baseball', 'gym', 'other',
];

const venues = [
  { neighborhood: 'Upper East Side', city: 'New York', state: 'NY', country: 'US', lng: -73.9654, lat: 40.7829 },
  { neighborhood: 'Venice', city: 'Los Angeles', state: 'CA', country: 'US', lng: -118.4695, lat: 33.985 },
  { neighborhood: 'Loop', city: 'Chicago', state: 'IL', country: 'US', lng: -87.6197, lat: 41.8826 },
  { neighborhood: 'Hyde Park', city: 'London', state: 'England', country: 'GB', lng: -0.1657, lat: 51.5073 },
  { neighborhood: 'Heaton Park', city: 'Manchester', state: 'England', country: 'GB', lng: -2.2494, lat: 53.5314 },
  { neighborhood: 'Zilker', city: 'Austin', state: 'TX', country: 'US', lng: -97.7713, lat: 30.2669 },
  { neighborhood: 'Wallingford', city: 'Seattle', state: 'WA', country: 'US', lng: -122.3348, lat: 47.6456 },
  { neighborhood: 'Downtown', city: 'Boston', state: 'MA', country: 'US', lng: -71.0636, lat: 42.3554 },
  { neighborhood: 'Downtown', city: 'Miami', state: 'FL', country: 'US', lng: -80.1859, lat: 25.7753 },
  { neighborhood: 'Capitol Hill', city: 'Denver', state: 'CO', country: 'US', lng: -104.9719, lat: 39.7392 },
];

const skillLevels = ['any', 'beginner', 'intermediate', 'advanced', 'professional'];
const now = new Date();

const games = sports.map((sport, i) => {
  const venue = venues[i % venues.length];
  const organizer = organizers[i % organizers.length]._id;
  const scheduledAt = new Date(now);
  scheduledAt.setDate(scheduledAt.getDate() + 1 + (i % 28));
  scheduledAt.setHours(7 + (i % 12), (i * 15) % 60, 0, 0);

  const maxPlayers = [6, 8, 10, 12, 14, 16, 20][i % 7];

  return {
    title: `${sport.charAt(0).toUpperCase() + sport.slice(1)} Pickup #${i + 1}`,
    description: `Seed ${sport} game in ${venue.city}.`,
    sport,
    tags: [sport.replace(/\s+/g, '-'), venue.city.toLowerCase(), 'pickup'],
    organizer,
    scheduledAt,
    durationMinutes: [60, 75, 90, 120][i % 4],
    location: {
      venueName: `${venue.city} Community Field`,
      neighborhood: venue.neighborhood,
      city: venue.city,
      state: venue.state,
      country: venue.country,
      formattedAddress: `${venue.neighborhood}, ${venue.city}`,
      placeId: `seed-place-${i + 1}`,
      coordinates: {
        type: 'Point',
        coordinates: [venue.lng, venue.lat],
      },
    },
    maxPlayers,
    minPlayersToStart: Math.min(4, maxPlayers),
    players: [
      {
        user: organizer,
        status: 'approved',
        role: 'co-organizer',
        joinedAt: now,
      },
    ],
    requiredSkillLevel: skillLevels[i % skillLevels.length],
    status: i % 10 === 0 ? 'draft' : 'open',
    isPrivate: i % 9 === 0,
    requiresApproval: i % 7 === 0,
    allowSpectators: i % 5 !== 0,
    isMerged: false,
    mergedWith: [],
    mergedInto: null,
    deletedAt: null,
    createdAt: now,
    updatedAt: now,
  };
});

const result = db.games.insertMany(games);
print(`Inserted ${result.insertedIds ? Object.keys(result.insertedIds).length : games.length} games.`);
