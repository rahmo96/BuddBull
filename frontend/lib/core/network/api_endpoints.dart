/// All backend API endpoint paths.
/// Set [baseUrl] via `--dart-define=API_BASE_URL=https://api.example.com`
/// or fall back to the Docker-compose local address.
abstract class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api/v1',
  );

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
  static String unfollowUser(String id) => '/users/$id/unfollow';
  static const String updateProfilePicture = '/users/me/profile-picture';
  static const String pushToken = '/users/me/push-token';

  // ── Games ─────────────────────────────────────────────────────
  static const String games = '/games';
  /// Search/list games: GET /games with query params (not /games/search).
  static const String searchGames = '/games';
  static const String myGames = '/games/my-games';
  static const String calendar = '/games/calendar';
  static String game(String id) => '/games/$id';
  static String joinGame(String id) => '/games/$id/join';
  static String leaveGame(String id) => '/games/$id/leave';
  static String invitePlayer(String id) => '/games/$id/invite';
  static String approvePlayer(String id) => '/games/$id/approve';
  static String kickPlayer(String id) => '/games/$id/kick';
  static String cancelGame(String id) => '/games/$id/cancel';
  static String completeGame(String id) => '/games/$id/complete';
  static String mergeGroups(String id) => '/games/$id/merge';
  static String gamePendingRequests(String id) => '/games/$id/pending';

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
  static const String receivedRatings = '/ratings/received';
  static const String givenRatings = '/ratings/given';
  static String ratingSummary(String userId) => '/ratings/summary/$userId';

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
