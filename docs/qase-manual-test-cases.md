# BuddBull — Qase TMS Manual Test Case Mapping

> Generated from existing automated test suites (Jest backend + Flutter widget/provider tests).
> Each test case maps 1:1 to an automated test file and follows the Qase UI schema.

---

## Suite: Backend — Authentication & RBAC

### Basic
- **Title:** Verify Firebase auth sync, token protection, and RBAC based on test file `auth.test.js`
- **Status:** Actual
- **Description:** Covers Firebase-first authentication via `POST /api/v1/auth/sync`, protected `GET /users/me` access, and role-based access control for admin catalogue routes.
- **Suite:** Backend — Authentication & RBAC
- **Severity:** Critical
- **Priority:** High
- **Type:** Integration
- **Layer:** API
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Backend API running with test MongoDB; Firebase token stub/mapping available; at least one player and one admin test account can be provisioned via `/auth/sync`.
- **Post-conditions:** Remove test users created during sync; clear auth tokens from client.
- **Tags:** `auth.test.js`, `backend`, `firebase`, `rbac`, `api-v1`

### Test Case Steps (Classic)
1. **Step Action:** Call `POST /api/v1/auth/sync` with a valid Firebase bearer token and new user profile (username, email, role `player`).
   **Expected Result:** HTTP 200; `success: true`; Mongo user profile created with matching `firebaseUid`.

2. **Step Action:** Call `POST /api/v1/auth/sync` again for the same `firebaseUid` with updated fields (`firstName`, `lastName`, `role: organizer`).
   **Expected Result:** HTTP 200; existing profile updated idempotently (`lastName`, `role` reflect new values).

3. **Step Action:** Call `POST /api/v1/auth/sync` without a valid Authorization header.
   **Expected Result:** HTTP 401 Unauthorized.

4. **Step Action:** Call `POST /api/v1/auth/sync` with a username violating model constraints (e.g., too short).
   **Expected Result:** HTTP 4xx with validation error.

5. **Step Action:** Call `GET /api/v1/users/me` without Authorization header.
   **Expected Result:** HTTP 401.

6. **Step Action:** Call `GET /api/v1/users/me` with an unregistered/synthetic bearer token.
   **Expected Result:** HTTP 401.

7. **Step Action:** After successful `/auth/sync`, call `GET /api/v1/users/me` with the issued bearer token.
   **Expected Result:** HTTP 200; returned user `_id` and `firebaseUid` match the synced profile.

8. **Step Action:** As a `player` role user, call `GET /api/v1/users/admin/list`.
   **Expected Result:** HTTP 403 Forbidden.

9. **Step Action:** As an `admin` role user, call `GET /api/v1/users/admin/list`.
   **Expected Result:** HTTP 200; `success: true`; admin catalogue returned.

---

## Suite: Backend — User Profile & Social

### Basic
- **Title:** Verify user profile CRUD, username changes, public profiles, and friend flows based on test file `user.test.js`
- **Status:** Actual
- **Description:** Integration tests for `GET/PATCH /users/me`, username updates, public profile visibility, friend request lifecycle, account deletion guard, and user search.
- **Suite:** Backend — User Profile & Social
- **Severity:** Major
- **Priority:** High
- **Type:** Integration
- **Layer:** API
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Two or more authenticated test users onboarded via `/auth/sync`; API reachable.
- **Post-conditions:** Unfriend or delete test friendships; remove test users if applicable.
- **Tags:** `user.test.js`, `backend`, `profile`, `friends`, `api-v1`

### Test Case Steps (Classic)
1. **Step Action:** `GET /api/v1/users/me` with valid bearer token.
   **Expected Result:** HTTP 200; profile returned with email; `password` field absent.

2. **Step Action:** `GET /api/v1/users/me` with unmapped bearer token.
   **Expected Result:** HTTP 401.

3. **Step Action:** `PATCH /api/v1/users/me` with `{ bio, location.city }`.
   **Expected Result:** HTTP 200; updated fields persisted.

4. **Step Action:** `PATCH /api/v1/users/me` attempting `role: admin` alongside legitimate bio update.
   **Expected Result:** HTTP 200; `role` remains `player` (no privilege escalation).

5. **Step Action:** `PATCH /api/v1/users/me` with empty body `{}`.
   **Expected Result:** HTTP 422.

6. **Step Action:** `PATCH /api/v1/users/me` with bio exceeding max length (501 chars).
   **Expected Result:** HTTP 422; `errors` array present.

7. **Step Action:** `PATCH /api/v1/users/me/username` with a unique new username.
   **Expected Result:** HTTP 200; username updated.

8. **Step Action:** User B attempts to change username to User A's existing username.
   **Expected Result:** HTTP 409 Conflict.

9. **Step Action:** `GET /api/v1/users/:username` for another user's public profile.
   **Expected Result:** HTTP 200; username visible; email NOT exposed.

10. **Step Action:** `GET /api/v1/users/doesnotexist999`.
    **Expected Result:** HTTP 404.

11. **Step Action:** User1 `POST /users/:userId/follow` User2; User2 accepts via `POST /friend-requests/:requestId/accept`.
    **Expected Result:** Follow returns `status: pending`; accept returns `isFriend: true`; profile shows `isFriend: true` and `friendsCount >= 1`.

12. **Step Action:** User1 sends duplicate follow request to User2.
    **Expected Result:** HTTP 409.

13. **Step Action:** User attempts to follow themselves.
    **Expected Result:** HTTP 400.

14. **Step Action:** `POST /users/not-a-valid-objectid/follow`.
    **Expected Result:** HTTP 400.

15. **Step Action:** After becoming friends, User1 `DELETE /users/:userId/follow` User2.
    **Expected Result:** HTTP 200; friendship removed.

16. **Step Action:** User1 unfollows User2 without prior friendship.
    **Expected Result:** HTTP 200; idempotent success.

17. **Step Action:** `DELETE /api/v1/users/me` with password field.
    **Expected Result:** HTTP 501 with SSO-managed message.

18. **Step Action:** `DELETE /api/v1/users/me` without password field.
    **Expected Result:** HTTP 400.

19. **Step Action:** `GET /api/v1/users/search?page=1&limit=5`.
    **Expected Result:** HTTP 200; pagination object and users array returned.

20. **Step Action:** `GET /api/v1/users/search?q=goalkeeper`.
    **Expected Result:** HTTP 200 or 500 (environment-dependent); if 200, users array returned.

---

## Suite: Backend — Games & Matchmaking

### Basic
- **Title:** Verify game creation, search, join/leave, invites, kicks, cancel, complete, and merge based on test file `game.test.js`
- **Status:** Actual
- **Description:** Full game lifecycle integration tests including matchmaking rules, schedule conflicts, approval flows, roster management, and game merging.
- **Suite:** Backend — Games & Matchmaking
- **Severity:** Critical
- **Priority:** High
- **Type:** Integration
- **Layer:** API
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Organizer and player test accounts; future-dated game fixture data (title, sport, location with coordinates, maxPlayers).
- **Post-conditions:** Cancel or delete test games; clear player rosters.
- **Tags:** `game.test.js`, `backend`, `games`, `matchmaking`, `api-v1`

### Test Case Steps (Classic)
1. **Step Action:** Organizer `POST /api/v1/games` with valid future `scheduledAt`.
   **Expected Result:** HTTP 201; game `status: open`; title matches payload.

2. **Step Action:** Player role user creates a game.
   **Expected Result:** HTTP 201 (player role permitted).

3. **Step Action:** Create game with past `scheduledAt`.
   **Expected Result:** HTTP 422 validation error.

4. **Step Action:** After creation, verify organizer appears in `players` with `status: approved`.
   **Expected Result:** Organizer slot present and approved.

5. **Step Action:** Create game with `location.placeId` and GeoJSON coordinates.
   **Expected Result:** HTTP 201; `placeId` and `Point` coordinates persisted.

6. **Step Action:** `POST /api/v1/games` without authentication.
   **Expected Result:** HTTP 401.

7. **Step Action:** `GET /api/v1/games/:id` for existing game.
   **Expected Result:** HTTP 200; correct game ID.

8. **Step Action:** `GET /api/v1/games/507f1f77bcf86cd799439011` (non-existent).
   **Expected Result:** HTTP 404.

9. **Step Action:** `GET /api/v1/games?sport=football&status=open` after creating football and basketball games.
   **Expected Result:** HTTP 200; all results are football; pagination present.

10. **Step Action:** `GET /api/v1/games?city=london` after games in London and New York.
    **Expected Result:** HTTP 200; all results have city containing "london" (case-insensitive).

11. **Step Action:** Player joins open game via `POST /games/:id/join`.
    **Expected Result:** HTTP 200; `status: approved`.

12. **Step Action:** Same player joins same game twice.
    **Expected Result:** HTTP 409.

13. **Step Action:** Third player attempts join when `maxPlayers: 2` and game is full.
    **Expected Result:** HTTP 400; message mentions "full".

14. **Step Action:** Player joins Game A at time T, then attempts join overlapping Game B at same time.
    **Expected Result:** HTTP 409; message mentions "conflict".

15. **Step Action:** Join with unregistered bearer token.
    **Expected Result:** HTTP 401.

16. **Step Action:** Joined player `DELETE /games/:id/leave`.
    **Expected Result:** HTTP 200.

17. **Step Action:** Organizer attempts to leave own game.
    **Expected Result:** HTTP 400; message suggests cancel instead.

18. **Step Action:** Organizer invites player, then revokes invite via `DELETE /games/:id/invite/:userId`.
    **Expected Result:** Invite created; revoke removes player slot; second revoke is idempotent (200).

19. **Step Action:** On `requiresApproval: true` game: organizer invites player; player joins.
    **Expected Result:** Join returns `status: approved` immediately (invite path); redundant approve returns 400.

20. **Step Action:** Invited player joins with `?acceptInvite=true` on approval-required game.
    **Expected Result:** HTTP 200; `status: approved`.

21. **Step Action:** Non-organizer attempts `PATCH /games/:id/players/:userId/approve`.
    **Expected Result:** HTTP 403.

22. **Step Action:** Organizer kicks approved player with reason.
    **Expected Result:** HTTP 200; player slot `status: kicked`.

23. **Step Action:** Non-organizer attempts kick.
    **Expected Result:** HTTP 403.

24. **Step Action:** Kicked player re-joins public game.
    **Expected Result:** HTTP 200; single player slot; `status: approved`.

25. **Step Action:** Player with pending status on private game calls `GET /games/me`.
    **Expected Result:** Game NOT listed for pending-only participant.

26. **Step Action:** Kicked player re-joins private game.
    **Expected Result:** HTTP 200; slot returns to `status: pending`.

27. **Step Action:** Organizer cancels game with reason.
    **Expected Result:** HTTP 200; `status: cancelled`.

28. **Step Action:** Cancel without reason payload.
    **Expected Result:** HTTP 422.

29. **Step Action:** Non-organizer attempts cancel on another's game.
    **Expected Result:** HTTP 403.

30. **Step Action:** Organizer `PATCH /games/:id/complete` with score and winner.
    **Expected Result:** HTTP 200; `status: completed`; `gamesPlayed` incremented for organizer and participants.

31. **Step Action:** Merge two under-capacity games via `POST /games/:sourceId/merge/:targetId` with `expandCapacity: false`.
    **Expected Result:** HTTP 200; survivor is target game; `isMerged: true`.

32. **Step Action:** Merge when combined roster exceeds `maxPlayers` without `expandCapacity`.
    **Expected Result:** HTTP 400; capacity/exceeding message.

33. **Step Action:** Merge overcrowded rosters with `expandCapacity: true`.
    **Expected Result:** HTTP 200; `maxPlayers` increased beyond original cap.

---

## Suite: Backend — Game Lifecycle (Auto-Complete)

### Basic
- **Title:** Verify stale game auto-completion sweep based on test file `game.autoComplete.test.js`
- **Status:** Actual
- **Description:** Tests the hourly PRD sweep (`GameService.autoCompleteStaleGames`) that completes games scheduled more than 4 hours ago, increments player stats, and emits completion notifications.
- **Suite:** Backend — Game Lifecycle (Auto-Complete)
- **Severity:** Major
- **Priority:** Medium
- **Type:** Functional
- **Layer:** API
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Game with approved participants exists; ability to backdate `scheduledAt` in database or via admin tooling; auto-complete job can be triggered manually.
- **Post-conditions:** Revert or delete auto-completed test games.
- **Tags:** `game.autoComplete.test.js`, `backend`, `cron`, `games`, `api-v1`

### Test Case Steps (Classic)
1. **Step Action:** Create game with organizer and one joined player; backdate `scheduledAt` to 5+ hours ago; set status `full`; trigger `autoCompleteStaleGames`.
   **Expected Result:** `summary.scanned: 1`; game ID in `completed`; `status: completed`; `result.winnerDescription: Auto-completed`; `gamesPlayed` incremented for organizer and participant; `gameCompleted` notifications in both inboxes.

2. **Step Action:** Create game backdated only 2 hours; trigger auto-complete sweep.
   **Expected Result:** Game NOT in `completed` array; `status` remains `open`.

---

## Suite: Backend — Private Games & Join Requests

### Basic
- **Title:** Verify private game creation, pending join flow, and join-request decisions based on test file `private.games.test.js`
- **Status:** Actual
- **Description:** Phase 4 private games: `isPrivate` flag persistence, pending join status, organizer approve/reject via `PATCH /games/:id/join-request/:userId`, and downstream notifications.
- **Suite:** Backend — Private Games & Join Requests
- **Severity:** Major
- **Priority:** High
- **Type:** Integration
- **Layer:** API
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Organizer and requester test accounts; notification inbox accessible for both users.
- **Post-conditions:** Clear pending join requests; delete test private games.
- **Tags:** `private.games.test.js`, `backend`, `private-games`, `join-request`, `api-v1`

### Test Case Steps (Classic)
1. **Step Action:** Organizer creates game with `isPrivate: true`.
   **Expected Result:** HTTP 201; `isPrivate: true` in response.

2. **Step Action:** Requester joins private game.
   **Expected Result:** HTTP 200; join `status: pending`; organizer receives `gameJoinRequest` notification.

3. **Step Action:** Organizer `PATCH /games/:id/join-request/:userId` with `{ decision: approve }`.
   **Expected Result:** HTTP 200; player slot `status: approved`; requester receives `gameApproved` notification with `gameId`.

4. **Step Action:** Organizer rejects pending request with `{ decision: reject, reason }`.
   **Expected Result:** HTTP 200; slot `status: rejected`; requester receives `gameJoinRequestDenied` with title "Join Request Denied".

5. **Step Action:** After approving a request, organizer sends second decision (reject) on same slot.
   **Expected Result:** HTTP 409 (stale request rejected).

6. **Step Action:** Organizer sends `{ decision: maybe }` (invalid).
   **Expected Result:** HTTP 422.

---

## Suite: Backend — Player Ratings

### Basic
- **Title:** Verify peer rating submission, stats rollup, pending queue, dismiss, and migration based on test file `rating.test.js`
- **Status:** Actual
- **Description:** Comprehensive rating system tests: `POST /ratings`, User.stats aggregation, `recalculateAllUserStats` migration, edge cases (self-rate, dedup), and pending/dismiss endpoints.
- **Suite:** Backend — Player Ratings
- **Severity:** Critical
- **Priority:** High
- **Type:** Integration
- **Layer:** API
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Completed 3-player game fixture; authenticated raters and ratees; rating API enabled.
- **Post-conditions:** Remove test ratings and dismissals; reset user stats if needed.
- **Tags:** `rating.test.js`, `backend`, `ratings`, `api-v1`

### Test Case Steps (Classic)
1. **Step Action:** After completed game, Player2 `POST /api/v1/ratings` rating Player3 (reliability 5, behavior 4, comment).
   **Expected Result:** HTTP 201; `compositeScore ≈ 4.5`; Rating doc persisted; ratee `totalRatings: 1`, `averageRating ≈ 4.5`.

2. **Step Action:** Submit rating and verify `Rating.recalculateUserStats` invoked once for ratee.
   **Expected Result:** Stats rollup triggered exactly once per submission.

3. **Step Action:** Two different raters rate same player; verify average.
   **Expected Result:** `totalRatings: 2`; `averageRating` correctly averaged (e.g., 4.0).

4. **Step Action:** Asymmetric scores (5/5 and 2/3) averaged without rounding drift.
   **Expected Result:** `averageRating ≈ 3.75`.

5. **Step Action:** One rater rates two different players; verify independent stats.
   **Expected Result:** Each ratee has correct stats; rater's own stats remain zero.

6. **Step Action:** Run `recalculateAllStats` on legacy rows missing `compositeScore`.
   **Expected Result:** `compositeBackfilled` count matches legacy rows; User.stats synced.

7. **Step Action:** Run migration twice.
   **Expected Result:** Second pass `compositeBackfilled: 0` (idempotent).

8. **Step Action:** Soft-delete all ratings; run migration.
   **Expected Result:** Affected users' stats reset to zero.

9. **Step Action:** Player attempts to rate themselves.
   **Expected Result:** HTTP 400; message mentions "yourself".

10. **Step Action:** Rate player on non-completed game.
    **Expected Result:** HTTP 404.

11. **Step Action:** Submit two ratings for same (rater, ratee, game) tuple.
    **Expected Result:** Single row on disk; stats reflect latest score only.

12. **Step Action:** Attempt parallel duplicate insert at DB level.
    **Expected Result:** Duplicate key error (E11000).

13. **Step Action:** `GET /api/v1/ratings/pending` for player who hasn't rated opponents.
    **Expected Result:** HTTP 200; one pending game; opponents listed excluding self.

14. **Step Action:** Rate all opponents; re-fetch pending.
    **Expected Result:** Empty pending array.

15. **Step Action:** `POST /api/v1/ratings/dismiss` with `gameId`; call twice.
    **Expected Result:** HTTP 200 both times; single RatingDismissal row; pending queue empty after dismiss.

---

## Suite: Backend — Training Streaks

### Basic
- **Title:** Verify 48-hour rolling training streak rules based on test file `streak.test.js`
- **Status:** Actual
- **Description:** Unit tests for `User#updateStreak` covering first activity, increment within 48h, reset after lapse, longest streak high-water mark, retroactive ignore, and UTC persistence.
- **Suite:** Backend — Training Streaks
- **Severity:** Normal
- **Priority:** Medium
- **Type:** Functional
- **Layer:** Database
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** User document with `stats.currentStreak`, `stats.longestStreak`, `stats.lastActivityDate` fields; ability to record activity timestamps.
- **Post-conditions:** Reset test user streak stats.
- **Tags:** `streak.test.js`, `backend`, `streaks`, `user-model`

### Test Case Steps (Classic)
1. **Step Action:** Record first-ever activity at T0.
   **Expected Result:** `currentStreak: 1`, `longestStreak: 1`, `lastActivityDate: T0`.

2. **Step Action:** Record activity at T0 + 47 hours.
   **Expected Result:** `currentStreak: 2`, `longestStreak: 2`.

3. **Step Action:** Record activity at exactly T0 + 48 hours.
   **Expected Result:** `currentStreak: 2` (boundary still increments).

4. **Step Action:** Record activity at T0 + 49 hours after prior streak of 1.
   **Expected Result:** `currentStreak: 1` (reset); `longestStreak` unchanged at previous high.

5. **Step Action:** Build streak to 3, then break with 200h gap.
   **Expected Result:** `currentStreak: 1`; `longestStreak: 3` preserved.

6. **Step Action:** After activity at T0, record retroactive timestamp T0 − 5h.
   **Expected Result:** Streak unchanged; `lastActivityDate` remains T0.

7. **Step Action:** Save user with activity timestamp `2026-03-15T22:30:45.123Z`; reload from DB.
   **Expected Result:** UTC timestamp persisted exactly; `currentStreak: 1`.

---

## Suite: Backend — Chat Presence

### Basic
- **Title:** Verify chat slot side effects on leave, kick, and re-join based on test file `chat.presence.test.js`
- **Status:** Actual
- **Description:** Tests chat presence contract: `leftAt` marking, `chat:left` / `chat:kicked` socket events, room force-leave, and slot re-activation on re-join.
- **Suite:** Backend — Chat Presence
- **Severity:** Major
- **Priority:** High
- **Type:** Integration
- **Layer:** API
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Game with chat room created; player joined and connected to socket; WebSocket/Socket.io monitoring available.
- **Post-conditions:** Player leaves or is removed; chat room cleaned up.
- **Tags:** `chat.presence.test.js`, `backend`, `chat`, `socket`, `api-v1`

### Test Case Steps (Classic)
1. **Step Action:** Player joins game, connects socket to chat room, then `DELETE /games/:id/leave`.
   **Expected Result:** HTTP 200; chat participant `leftAt` set; `chat:left` emitted to player's room with `chatId` and `gameId`; socket force-leaves chat room.

2. **Step Action:** Organizer kicks player with reason via `DELETE /games/:id/players/:userId`.
   **Expected Result:** HTTP 200; chat slot `leftAt` set; `chat:kicked` emitted with reason in payload; socket force-leaves room.

3. **Step Action:** Player joins, leaves, then re-joins same game.
   **Expected Result:** Single chat participant slot; `leftAt` cleared (re-activated); no duplicate participants.

---

## Suite: Backend — Notification Producers

### Basic
- **Title:** Verify game-lifecycle notification inbox writes based on test file `notification.producers.test.js`
- **Status:** Actual
- **Description:** Pins the contract between `game.service.notify(...)` and the Notification collection for invites, join requests, approvals, kicks, cancellations, and completions.
- **Suite:** Backend — Notification Producers
- **Severity:** Major
- **Priority:** High
- **Type:** Integration
- **Layer:** API
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Organizer, players, and invitee test accounts; notification inbox queryable per user.
- **Post-conditions:** Mark notifications read or clear test inbox rows.
- **Tags:** `notification.producers.test.js`, `backend`, `notifications`, `api-v1`

### Test Case Steps (Classic)
1. **Step Action:** Organizer invites player to game.
   **Expected Result:** Invitee inbox has one `gameInvite` (unread); title "Game Invite"; body mentions organizer; `data.gameId` set; organizer inbox empty.

2. **Step Action:** Player requests join on `requiresApproval: true` game.
   **Expected Result:** Organizer inbox has `gameJoinRequest` with `gameId` and `requesterId`.

3. **Step Action:** Player auto-joins open game (no approval required).
   **Expected Result:** Organizer receives `gamePlayerJoined`; joiner inbox empty.

4. **Step Action:** Organizer approves pending join request.
   **Expected Result:** Requester receives `gameApproved` ("You are in the game!").

5. **Step Action:** Organizer kicks player with reason.
   **Expected Result:** Kicked player receives `gameKicked` with reason in body.

6. **Step Action:** Organizer cancels game with reason; multiple approved players joined.
   **Expected Result:** Each approved player (not organizer) receives `gameCancelled` with game title and reason.

7. **Step Action:** Organizer completes game with score.
   **Expected Result:** All approved players (including organizer) receive `gameCompleted` ("Tap to rate the players.").

---

## Suite: Backend — Notification Socket Emission

### Basic
- **Title:** Verify real-time `notification:new` socket emission based on test file `notification.socket.test.js`
- **Status:** Actual
- **Description:** Tests `notificationInbox.service` emits `notification:new` to recipient socket rooms on create, fans out to multiple recipients, no-ops without io, and survives faulty socket layer.
- **Suite:** Backend — Notification Socket Emission
- **Severity:** Major
- **Priority:** Medium
- **Type:** Integration
- **Layer:** API
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Socket.io server running or mockable; test recipient user IDs; WebSocket client listening on private room.
- **Post-conditions:** Disconnect test sockets; clear injected io spy.
- **Tags:** `notification.socket.test.js`, `backend`, `notifications`, `socket`, `real-time`

### Test Case Steps (Classic)
1. **Step Action:** Call `createForUser(recipient, notificationPayload)` with io wired.
   **Expected Result:** One `notification:new` emit to recipient room; payload matches HTTP response shape (`_id`, `type`, `title`, `body`, `read: false`, `data`, `createdAt`).

2. **Step Action:** Call `createForManyUsers([r1, r2, r3], payload)`.
   **Expected Result:** Three emits, one per recipient room; all events `notification:new`.

3. **Step Action:** Call `createForUser` with `setIo(null)` (no socket server).
   **Expected Result:** DB write succeeds; no socket error thrown.

4. **Step Action:** Call `createForUser` with io that throws on `.to()`.
   **Expected Result:** Promise resolves; notification still persisted (resilient to socket failure).

---

## Suite: Backend — Integration & Security Gaps

### Basic
- **Title:** Verify public catalogue access and banned-account enforcement based on test file `integration.gaps.test.js`
- **Status:** Actual
- **Description:** Edge-case smoke tests: unauthenticated game catalogue access, protected `/games/me`, and 401 for banned accounts with valid Firebase tokens.
- **Suite:** Backend — Integration & Security Gaps
- **Severity:** Critical
- **Priority:** High
- **Type:** Security
- **Layer:** API
- **Is flaky:** No
- **Behavior:** Negative
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Open games exist in catalogue; test user account that can be flagged `isBanned: true` in database.
- **Post-conditions:** Unban test account; restore normal access.
- **Tags:** `integration.gaps.test.js`, `backend`, `security`, `banned`, `api-v1`

### Test Case Steps (Classic)
1. **Step Action:** `GET /api/v1/games?status=open&limit=5` without bearer token.
   **Expected Result:** HTTP 200; games array returned (optionalAuth).

2. **Step Action:** `GET /api/v1/games/me` without authentication.
   **Expected Result:** HTTP 401.

3. **Step Action:** Onboard user via `/auth/sync`; set `isBanned: true` in DB; call `GET /users/me` with valid token.
   **Expected Result:** HTTP 401; message references account/authentication restriction.

---

## Suite: Frontend — Auth (Login Screen)

### Basic
- **Title:** Verify Login screen validation and navigation based on test file `login_screen_test.dart`
- **Status:** Actual
- **Description:** Widget tests for LoginScreen form validation (empty submit, invalid email), navigation to Register, and Forgot Password route.
- **Suite:** Frontend — Auth (Login Screen)
- **Severity:** Major
- **Priority:** High
- **Type:** Functional
- **Layer:** UI
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** App launched on Login route; user logged out; Firebase test binding initialized.
- **Post-conditions:** Navigate back to login or reset navigation stack.
- **Tags:** `login_screen_test.dart`, `frontend`, `auth`, `login`, `flutter`

### Test Case Steps (Classic)
1. **Step Action:** Open Login screen; tap Login button without entering any fields.
   **Expected Result:** "Field required" validation hints displayed on empty fields.

2. **Step Action:** Enter invalid email (`not-an-email`) and valid password; tap Login.
   **Expected Result:** "Invalid email" error message shown.

3. **Step Action:** Tap "Sign up" link on Login screen.
   **Expected Result:** Register screen displayed with register subtitle visible.

4. **Step Action:** Tap "Forgot password" link on Login screen.
   **Expected Result:** Reset password screen shown with title and subtitle.

---

## Suite: Frontend — Auth (Register Screen)

### Basic
- **Title:** Verify Register screen validation, terms gate, and login shortcut based on test file `register_screen_test.dart`
- **Status:** Actual
- **Description:** Widget tests for RegisterScreen required-field validators, terms acceptance snackbar, and sign-in navigation back to Login.
- **Suite:** Frontend — Auth (Register Screen)
- **Severity:** Major
- **Priority:** High
- **Type:** Functional
- **Layer:** UI
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** App on Register route; user logged out.
- **Post-conditions:** Return to login screen.
- **Tags:** `register_screen_test.dart`, `frontend`, `auth`, `register`, `flutter`

### Test Case Steps (Classic)
1. **Step Action:** Open Register screen; tap Create Account without filling fields.
   **Expected Result:** "Field required" validation messages on required inputs.

2. **Step Action:** Fill all fields with valid data but do NOT accept terms; tap Create Account.
   **Expected Result:** Snackbar/message "Accept terms" displayed; registration blocked.

3. **Step Action:** Tap "Sign in" link on Register screen.
   **Expected Result:** Login screen displayed with Login button visible.

---

## Suite: Frontend — Onboarding

### Basic
- **Title:** Verify post-signup onboarding welcome screen based on test files `introduction_screen_test.dart` and `widget_test.dart`
- **Status:** Actual
- **Description:** Widget tests for OnboardingWelcomeScreen rendering (headline, sport chips, actions) and sport chip toggle selection; includes Firebase-free smoke render.
- **Suite:** Frontend — Onboarding
- **Severity:** Normal
- **Priority:** Medium
- **Type:** Functional
- **Layer:** UI
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Fresh install or cleared onboarding flags; navigate to OnboardingWelcomeScreen.
- **Post-conditions:** Complete or skip onboarding to exit flow.
- **Tags:** `introduction_screen_test.dart`, `widget_test.dart`, `frontend`, `onboarding`, `flutter`

### Test Case Steps (Classic)
1. **Step Action:** Open OnboardingWelcomeScreen.
   **Expected Result:** Welcome headline visible; Football and Basketball sport chips; Next and Skip action buttons present.

2. **Step Action:** Tap Football sport chip.
   **Expected Result:** Chip shows selected state (check icon visible).

3. **Step Action:** Tap Football chip again to deselect.
   **Expected Result:** Selection toggled off.

4. **Step Action:** Pump OnboardingWelcomeScreen widget (smoke, no Firebase).
   **Expected Result:** OnboardingWelcomeScreen widget renders without error.

---

## Suite: Frontend — Home Screen

### Basic
- **Title:** Verify Home screen scaffold and pull-to-refresh based on test file `home_screen_test.dart`
- **Status:** Actual
- **Description:** Widget test ensuring HomeScreen renders with RefreshIndicator and CustomScrollView when providers are stubbed (no network).
- **Suite:** Frontend — Home Screen
- **Severity:** Normal
- **Priority:** Medium
- **Type:** Functional
- **Layer:** UI
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Authenticated user session (or mocked providers); Home tab reachable.
- **Post-conditions:** None.
- **Tags:** `home_screen_test.dart`, `frontend`, `home`, `flutter`

### Test Case Steps (Classic)
1. **Step Action:** Navigate to Home screen with stubbed game, rating, performance, and notification providers.
   **Expected Result:** HomeScreen widget present; at least one RefreshIndicator; CustomScrollView rendered; no exceptions thrown during pump.

---

## Suite: Frontend — Navigation Shell

### Basic
- **Title:** Verify bottom navigation tab switching based on test file `main_layout_test.dart`
- **Status:** Actual
- **Description:** Widget tests for HomeScaffold bottom nav: initial home tab, Profile tab swap, and Games tab swap.
- **Suite:** Frontend — Navigation Shell
- **Severity:** Major
- **Priority:** High
- **Type:** Functional
- **Layer:** UI
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** User logged in; app shell with bottom navigation visible.
- **Post-conditions:** Return to Home tab.
- **Tags:** `main_layout_test.dart`, `frontend`, `navigation`, `shell`, `flutter`

### Test Case Steps (Classic)
1. **Step Action:** Launch app shell on Home route.
   **Expected Result:** Home tab content visible; Home and Profile nav labels present.

2. **Step Action:** Tap Profile tab in bottom navigation.
   **Expected Result:** Profile route content displayed.

3. **Step Action:** Tap Games tab in bottom navigation.
   **Expected Result:** Games route content displayed.

---

## Suite: Frontend — Profile Screen

### Basic
- **Title:** Verify Profile screen loading state during auth hydration based on test file `profile_screen_test.dart`
- **Status:** Actual
- **Description:** Widget test confirming ProfileScreen shows loading indicator while profile/auth data is hydrating.
- **Suite:** Frontend — Profile Screen
- **Severity:** Normal
- **Priority:** Medium
- **Type:** Functional
- **Layer:** UI
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Navigate to Profile tab; auth provider in loading/hydrating state.
- **Post-conditions:** Wait for profile to fully load.
- **Tags:** `profile_screen_test.dart`, `frontend`, `profile`, `flutter`

### Test Case Steps (Classic)
1. **Step Action:** Open ProfileScreen immediately after pump (before auth resolves).
   **Expected Result:** `BbLoadingIndicator` visible; ProfileScreen widget mounted; no crash during hydration.

---

## Suite: Frontend — Rating Provider

### Basic
- **Title:** Verify post-game rating provider queue and dismiss logic based on test file `rating_provider_test.dart`
- **Status:** Actual
- **Description:** Riverpod tests for `pendingRatingsProvider`, `RatePlayerNotifier`, and `dismissGameRatingQueue`: queue reflection, invalidation after rate, error handling, and dismiss endpoint invocation.
- **Suite:** Frontend — Rating Provider
- **Severity:** Major
- **Priority:** High
- **Type:** Functional
- **Layer:** UI
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Completed game with pending opponents to rate; rating repository/API available or stubbed.
- **Post-conditions:** Clear pending rating queue.
- **Tags:** `rating_provider_test.dart`, `frontend`, `ratings`, `riverpod`, `flutter`

### Test Case Steps (Classic)
1. **Step Action:** Load `pendingRatingsProvider` when repository returns 2 pending games.
   **Expected Result:** Provider returns 2 items with correct `gameId` values and player counts.

2. **Step Action:** Load pending ratings when queue is empty.
   **Expected Result:** Empty list returned.

3. **Step Action:** Invalidate provider after external queue change (items removed).
   **Expected Result:** Re-fetch occurs; updated empty list returned (not stale cache).

4. **Step Action:** Call `ratePlayer` for one opponent in a 2-player pending queue.
   **Expected Result:** Repository called with correct args; success state set; queue invalidated; rated player removed from pending list.

5. **Step Action:** Rate the last remaining opponent in queue.
   **Expected Result:** Pending queue becomes empty after refresh.

6. **Step Action:** Trigger rate when repository throws error.
   **Expected Result:** `success: false`; error message surfaced in `RatePlayerState`.

7. **Step Action:** Call `dismissGameRatingQueue(ref, gameId)` for game in queue.
   **Expected Result:** Dismiss endpoint invoked; provider invalidated; dismissed game removed from pending list.

---

## Suite: Frontend — Game Detail (Rate Button)

### Basic
- **Title:** Verify Game Detail screen rate/leave affordances and auto-navigation based on test file `game_detail_rate_button_test.dart`
- **Status:** Actual
- **Description:** Widget tests for GameDetailScreen bottom action button visibility by game status and viewer role, status transition from in_progress to completed, and auto-pop when rating queue drains.
- **Suite:** Frontend — Game Detail (Rate Button)
- **Severity:** Critical
- **Priority:** High
- **Type:** Functional
- **Layer:** UI
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Test games in various statuses (completed, in_progress); viewer as approved, kicked, or organizer; pending rating queue configurable.
- **Post-conditions:** Navigate back from game detail.
- **Tags:** `game_detail_rate_button_test.dart`, `frontend`, `games`, `ratings`, `flutter`

### Test Case Steps (Classic)
1. **Step Action:** Open completed game as approved viewer with pending ratings.
   **Expected Result:** "Rate Participants" button visible; "Leave Game" NOT shown.

2. **Step Action:** Open in_progress game as approved viewer.
   **Expected Result:** "Leave Game" button visible; "Rate Participants" NOT shown.

3. **Step Action:** Open completed game with empty pending queue.
   **Expected Result:** "Rate Participants" still visible (picker handles empty edge case).

4. **Step Action:** Open completed game as kicked viewer.
   **Expected Result:** Neither "Rate Participants" nor "Leave Game" shown.

5. **Step Action:** While on in_progress game detail, change game status to completed (simulate organiser completion).
   **Expected Result:** Bottom bar swaps from "Leave Game" to "Rate Participants".

6. **Step Action:** On completed game with pending queue, drain queue (rate/dismiss all opponents); wait 500ms+.
   **Expected Result:** Game detail screen auto-pops back to previous route.

7. **Step Action:** Land on completed game that already has empty pending queue; wait past grace window.
   **Expected Result:** Screen does NOT auto-pop (no false bounce on arrival).

---

## Suite: Frontend — Notifications (Join Request Actions)

### Basic
- **Title:** Verify smart notification join-request approve/reject handling based on test file `notification_smart_test.dart`
- **Status:** Actual
- **Description:** Provider tests for `NotificationsNotifier.handleJoinRequest`: optimistic UI removal, API calls, rollback on failure, and validation of notification type/payload.
- **Suite:** Frontend — Notifications (Join Request Actions)
- **Severity:** Major
- **Priority:** High
- **Type:** Functional
- **Layer:** UI
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Organizer account with `gameJoinRequest` notification in inbox; game and requester IDs in notification payload.
- **Post-conditions:** Restore notification if rolled back; verify join request resolved on server.
- **Tags:** `notification_smart_test.dart`, `frontend`, `notifications`, `join-request`, `flutter`

### Test Case Steps (Classic)
1. **Step Action:** Tap Approve on `gameJoinRequest` notification.
   **Expected Result:** Notification row removed optimistically; unread badge decrements; `handleJoinRequest(gameId, userId, approve)` API called.

2. **Step Action:** Tap Reject on `gameJoinRequest` notification.
   **Expected Result:** Row removed; API called with `decision: reject`.

3. **Step Action:** Approve when API/network fails.
   **Expected Result:** Notification row restored; unread count unchanged; error state set.

4. **Step Action:** Attempt `handleJoinRequest` on non-join-request notification (e.g., `gameCompleted`).
   **Expected Result:** Returns false; row stays; no API call.

5. **Step Action:** Attempt approve on `gameJoinRequest` missing `requesterId` in payload.
   **Expected Result:** Returns false; row stays; error contains "Invalid"; no API call.

---

## Suite: Frontend — Notifications (Live Stream)

### Basic
- **Title:** Verify real-time notification inbox updates via socket stream based on test file `notification_live_test.dart`
- **Status:** Actual
- **Description:** Provider tests for `NotificationsNotifier` live stream wiring: prepend on push, newest-first ordering, deduplication, read-flag badge behavior, dispose safety, and null-stream HTTP-only mode.
- **Suite:** Frontend — Notifications (Live Stream)
- **Severity:** Major
- **Priority:** High
- **Type:** Functional
- **Layer:** UI
- **Is flaky:** No
- **Behavior:** Positive
- **Automation status:** Automated (Since a script already exists)

### Conditions & Tags
- **Pre-conditions:** Socket.io connected; notifications provider initialized; empty or seeded inbox.
- **Post-conditions:** Disconnect socket; clear test notifications.
- **Tags:** `notification_live_test.dart`, `frontend`, `notifications`, `socket`, `real-time`, `flutter`

### Test Case Steps (Classic)
1. **Step Action:** Receive `notification:new` socket event for unread notification.
   **Expected Result:** Row prepended to list; unread badge increments by 1.

2. **Step Action:** With existing notification in list, receive newer push.
   **Expected Result:** New notification at top (newest-first); badge increments.

3. **Step Action:** Receive duplicate `notification:new` with same ID twice.
   **Expected Result:** Single row in list; badge count not doubled.

4. **Step Action:** Receive push with `read: true`.
   **Expected Result:** Row appended to list; unread badge does NOT increment.

5. **Step Action:** Dispose notifications provider; push event after dispose.
   **Expected Result:** No crash; no stale state writes.

6. **Step Action:** Initialize provider with null live stream (HTTP-only mode).
   **Expected Result:** `hasLoadedOnce: true`; unread count 0; no socket subscription errors.

---

## Appendix: Suite Index

| # | Suite Name | Test File(s) | Layer |
|---|------------|--------------|-------|
| 1 | Backend — Authentication & RBAC | `backend/tests/auth.test.js` | API |
| 2 | Backend — User Profile & Social | `backend/tests/user.test.js` | API |
| 3 | Backend — Games & Matchmaking | `backend/tests/game.test.js` | API |
| 4 | Backend — Game Lifecycle (Auto-Complete) | `backend/tests/game.autoComplete.test.js` | API |
| 5 | Backend — Private Games & Join Requests | `backend/tests/private.games.test.js` | API |
| 6 | Backend — Player Ratings | `backend/tests/rating.test.js` | API |
| 7 | Backend — Training Streaks | `backend/tests/streak.test.js` | Database |
| 8 | Backend — Chat Presence | `backend/tests/chat.presence.test.js` | API |
| 9 | Backend — Notification Producers | `backend/tests/notification.producers.test.js` | API |
| 10 | Backend — Notification Socket Emission | `backend/tests/notification.socket.test.js` | API |
| 11 | Backend — Integration & Security Gaps | `backend/tests/integration.gaps.test.js` | API |
| 12 | Frontend — Auth (Login Screen) | `frontend/test/screens/login_screen_test.dart` | UI |
| 13 | Frontend — Auth (Register Screen) | `frontend/test/screens/register_screen_test.dart` | UI |
| 14 | Frontend — Onboarding | `introduction_screen_test.dart`, `widget_test.dart` | UI |
| 15 | Frontend — Home Screen | `frontend/test/screens/home_screen_test.dart` | UI |
| 16 | Frontend — Navigation Shell | `frontend/test/screens/main_layout_test.dart` | UI |
| 17 | Frontend — Profile Screen | `frontend/test/screens/profile_screen_test.dart` | UI |
| 18 | Frontend — Rating Provider | `frontend/test/features/rating/rating_provider_test.dart` | UI |
| 19 | Frontend — Game Detail (Rate Button) | `frontend/test/features/rating/game_detail_rate_button_test.dart` | UI |
| 20 | Frontend — Notifications (Join Request Actions) | `frontend/test/features/notifications/notification_smart_test.dart` | UI |
| 21 | Frontend — Notifications (Live Stream) | `frontend/test/features/notifications/notification_live_test.dart` | UI |

**Total: 21 Suites · 22 automated test files · 21 Qase manual test cases**

### Excluded (non-functional / infrastructure)
- `backend/tests/helpers/*` — test utilities
- `backend/tests/__mocks__/firebase-admin.js` — Jest mock
- `frontend/test/helpers/*` — test bootstrap and router helpers
- `frontend/ios/RunnerTests/RunnerTests.swift` — empty Xcode template
- `frontend/macos/RunnerTests/RunnerTests.swift` — empty Xcode template
