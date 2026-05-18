import 'package:flutter/foundation.dart';

/// All backend API endpoint paths.
/// Override with `--dart-define=API_BASE_URL=http://host:port/api/v1`
abstract class ApiEndpoints {
  static String get baseUrl {
    const env = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;

    if (kReleaseMode) return 'http://178.105.65.91:8000/api/v1';

    if (kIsWeb) return 'http://127.0.0.1:5000/api/v1';

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api/v1';
    }
    return 'http://127.0.0.1:5000/api/v1';
  }

  /// HTTP origin for Socket.IO (same host/port as REST, without `/api/v1`).
  static String get socketUrl =>
      baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');

  // ── Auth ──────────────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // ── Users ──────────────────────────────────────────────────────
  static const String me = '/users/me';
  static const String searchUsers = '/users/search';
  static String userProfile(String id) => '/users/$id';
  static String userFollowers(String id) => '/users/$id/followers';
  static String userFollowing(String id) => '/users/$id/following';
  static String followUser(String id) => '/users/$id/follow';
  static String unfollowUser(String id) => '/users/$id/follow';
  static const String myFriends = '/users/me/friends';
  static String acceptFriendRequest(String requestId) =>
      '/users/friend-requests/$requestId/accept';
  static String declineFriendRequest(String requestId) =>
      '/users/friend-requests/$requestId/decline';
  static String inviteFriendToGame(String gameId, String friendId) =>
      '/games/$gameId/invite/$friendId?requireFriend=true';
  static const String updateProfilePicture = '/users/me/profile-picture';
  static const String pushToken = '/users/me/push-token';

  // ── Games ─────────────────────────────────────────────────────
  static const String games = '/games';
  /// Search/list games: GET /games with query params (not /games/search).
  static const String searchGames = '/games';
  /// Authenticated user's games: GET /games/me
  static const String myGames = '/games/me';
  static const String calendar = '/games/calendar';
  static String game(String id) => '/games/$id';
  static String joinGame(String id, {bool acceptInvite = false}) =>
      acceptInvite ? '/games/$id/join?acceptInvite=true' : '/games/$id/join';
  static String leaveGame(String id) => '/games/$id/leave';
  static String invitePlayer(String gameId, String userId) =>
      '/games/$gameId/invite/$userId';
  static String cancelGameInvite(String gameId, String userId) =>
      '/games/$gameId/invite/$userId';
  static String approvePlayer(String gameId, String userId) =>
      '/games/$gameId/players/$userId/approve';
  static String kickPlayer(String gameId, String userId) =>
      '/games/$gameId/players/$userId';

  /// PATCH endpoint that approves or rejects a pending join request in a
  /// single call. Body: `{ decision: 'approve' | 'reject', reason? }`.
  /// Drives the Approve/Reject quick actions on `gameJoinRequest`
  /// notifications.
  static String gameJoinRequest(String gameId, String userId) =>
      '/games/$gameId/join-request/$userId';

  static String completeGame(String id) => '/games/$id/complete';
  static String mergeGroups(String id) => '/games/$id/merge';
  static String gamePendingRequests(String id) =>
      '/games/$id/players/pending';

  // ── Maps ──────────────────────────────────────────────────────
  static const String mapsAutocomplete = '/maps/autocomplete';
  static const String mapsPlaceDetails = '/maps/place-details';
  static String mapsStatic({
    required double lat,
    required double lng,
    int zoom = 14,
    int width = 900,
    int height = 360,
  }) =>
      '/maps/static?lat=$lat&lng=$lng&zoom=$zoom&width=$width&height=$height';

  // ── Performance ───────────────────────────────────────────────
  static const String performanceLogs = '/performance';
  static const String performanceStats = '/performance/stats';
  static const String performanceStreak = '/performance/streak';
  static String performanceLeaderboard(String sport) =>
      '/performance/leaderboard/$sport';
  static String performanceLog(String id) => '/performance/$id';
  static String userLogs(String userId) => '/performance/user/$userId';

  // ── Chats ─────────────────────────────────────────────────────
  static const String chats = '/chats';
  static const String createDm = '/chats/dm';
  static const String unreadCounts = '/chats/unread';
  static String chat(String id) => '/chats/$id';
  static String chatMessages(String id) => '/chats/$id/messages';
  static String chatMessage(String chatId, String msgId) =>
      '/chats/$chatId/messages/$msgId';
  static String chatPin(String chatId) => '/chats/$chatId/pin';
  static String chatUnpin(String chatId, String msgId) =>
      '/chats/$chatId/pin/$msgId';

  // ── Ratings ───────────────────────────────────────────────────
  static const String ratings = '/ratings';
  static const String pendingRatings = '/ratings/pending';
  static const String ratingsDismiss = '/ratings/dismiss';
  static const String receivedRatings = '/ratings/received';
  static const String givenRatings = '/ratings/given';
  static String ratingSummary(String userId) => '/ratings/summary/$userId';

  // ── Notifications ─────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';

  // ── Admin ─────────────────────────────────────────────────────
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminGames = '/admin/games';
  static String adminBanUser(String id) => '/admin/users/$id/ban';
  static String adminDeleteUser(String id) => '/admin/users/$id';
  static String adminDeleteGame(String id) => '/admin/games/$id';
  static const String adminBroadcast = '/admin/broadcast';
  static const String adminExportUsers = '/admin/export/users';
  static const String adminExportGames = '/admin/export/games';
  static const String adminSports = '/admin/sports';
  static String adminSport(String id) => '/admin/sports/$id';

  ApiEndpoints._();
}
