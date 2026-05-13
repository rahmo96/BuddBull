/**
 * Training streak rule (v2)
 *
 * Pins the new 48-hour rolling window:
 *   first activity     → 1
 *   ≤ 48h since last   → +1
 *   > 48h since last   → reset to 1
 *   retroactive (now < last) → unchanged (no penalty)
 *
 * The method runs in memory, so we exercise it directly against an
 * unsaved `User` document instead of paying for the full mongo round
 * trip every assertion.
 */

const testDb = require('./helpers/testDb');
const User = require('../src/models/User.model');

beforeAll(testDb.connect);
afterEach(testDb.clearAll);
afterAll(testDb.disconnect);

const HOUR = 60 * 60 * 1000;

const makeUser = () =>
  new User({
    firebaseUid: `uid-${Math.random().toString(36).slice(2)}`,
    email: `u-${Date.now()}@x.com`,
    username: `u${Date.now()}`,
    firstName: 'Streak',
    lastName: 'Tester',
  });

describe('User#updateStreak — 48h window', () => {
  it('seeds the streak to 1 on the first ever activity', () => {
    const user = makeUser();
    user.updateStreak(new Date('2026-01-01T10:00:00.000Z'));

    expect(user.stats.currentStreak).toBe(1);
    expect(user.stats.longestStreak).toBe(1);
    expect(user.stats.lastActivityDate.toISOString()).toBe('2026-01-01T10:00:00.000Z');
  });

  it('increments when the next activity lands within 48h', () => {
    const user = makeUser();
    const t0 = new Date('2026-01-01T10:00:00.000Z');
    user.updateStreak(t0);
    user.updateStreak(new Date(t0.getTime() + 47 * HOUR));

    expect(user.stats.currentStreak).toBe(2);
    expect(user.stats.longestStreak).toBe(2);
  });

  it('still increments at the exact 48h boundary', () => {
    const user = makeUser();
    const t0 = new Date('2026-01-01T10:00:00.000Z');
    user.updateStreak(t0);
    user.updateStreak(new Date(t0.getTime() + 48 * HOUR));

    expect(user.stats.currentStreak).toBe(2);
  });

  it('resets to 1 once the 48h window lapses', () => {
    const user = makeUser();
    const t0 = new Date('2026-01-01T10:00:00.000Z');
    user.updateStreak(t0);
    user.updateStreak(new Date(t0.getTime() + 49 * HOUR));

    expect(user.stats.currentStreak).toBe(1);
    // Best streak (longestStreak) preserves the previous high-water mark.
    expect(user.stats.longestStreak).toBe(1);
  });

  it('keeps longestStreak as a high-water mark across resets', () => {
    const user = makeUser();
    const t0 = new Date('2026-01-01T10:00:00.000Z');
    user.updateStreak(t0);
    user.updateStreak(new Date(t0.getTime() + 24 * HOUR));
    user.updateStreak(new Date(t0.getTime() + 47 * HOUR));
    // Streak so far: 3
    expect(user.stats.currentStreak).toBe(3);
    expect(user.stats.longestStreak).toBe(3);

    // Now break the chain.
    user.updateStreak(new Date(t0.getTime() + 200 * HOUR));
    expect(user.stats.currentStreak).toBe(1);
    expect(user.stats.longestStreak).toBe(3);
  });

  it('ignores retroactive completions (timestamp before lastActivityDate)', () => {
    const user = makeUser();
    const t0 = new Date('2026-01-01T10:00:00.000Z');
    user.updateStreak(t0);
    user.updateStreak(new Date(t0.getTime() - 5 * HOUR));

    expect(user.stats.currentStreak).toBe(1);
    expect(user.stats.lastActivityDate.toISOString()).toBe(t0.toISOString());
  });

  it('persists the UTC timestamp on the document', async () => {
    const user = makeUser();
    user.updateStreak(new Date('2026-03-15T22:30:45.123Z'));
    await user.save({ validateBeforeSave: false });

    const fresh = await User.findById(user._id).lean();
    expect(new Date(fresh.stats.lastActivityDate).toISOString()).toBe(
      '2026-03-15T22:30:45.123Z',
    );
    expect(fresh.stats.currentStreak).toBe(1);
  });
});
