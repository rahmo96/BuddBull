import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:buddbull/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:buddbull/features/auth/presentation/screens/login_screen.dart';
import 'package:buddbull/features/auth/presentation/screens/register_screen.dart';
import 'package:buddbull/features/auth/presentation/screens/splash_screen.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:buddbull/features/chat/presentation/screens/chat_screen.dart';
import 'package:buddbull/features/games/presentation/screens/calendar_screen.dart';
import 'package:buddbull/features/games/presentation/screens/create_game_screen.dart';
import 'package:buddbull/features/games/presentation/screens/edit_game_screen.dart';
import 'package:buddbull/features/games/presentation/screens/game_detail_screen.dart';
import 'package:buddbull/features/games/presentation/screens/games_screen.dart';
import 'package:buddbull/features/home/home_scaffold.dart';
import 'package:buddbull/features/home/presentation/home_screen.dart';
import 'package:buddbull/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:buddbull/features/onboarding/data/onboarding_prefs.dart';
import 'package:buddbull/features/onboarding/presentation/screens/onboarding_location_screen.dart';
import 'package:buddbull/features/onboarding/presentation/screens/onboarding_profile_screen.dart';
import 'package:buddbull/features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import 'package:buddbull/features/onboarding/providers/onboarding_redirect_listen.dart';
import 'package:buddbull/features/performance/presentation/screens/create_log_screen.dart';
import 'package:buddbull/features/performance/presentation/screens/performance_screen.dart';
import 'package:buddbull/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:buddbull/features/profile/presentation/screens/friends_list_screen.dart';
import 'package:buddbull/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Root [NavigatorState] for FCM / local-notification taps (no [BuildContext]
/// from a widget at cold start).
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

// ── Route path constants ──────────────────────────────────────────────────────
abstract class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  /// Post-registration introduction (Riverpod onboarding draft persists here).
  static const String onboardingWelcome = '/onboarding/welcome';
  static const String onboardingLocation = '/onboarding/location';
  static const String onboardingProfile = '/onboarding/profile';

  // Shell tabs
  static const String home = '/home';
  static const String games = '/games';
  static const String createGame = '/games/create';
  static const String calendar = '/games/calendar';
  static String gameDetail(String id) => '/games/$id';
  static const String chats = '/chats';
  static String chatRoom(String id) => '/chats/$id';
  static const String newChat = '/chats/new';
  static const String adminDashboard = '/admin';
  static const String performance = '/performance';
  static const String createLog = '/performance/log/create';
  static const String profile = '/profile';
  static const String friends = '/profile/friends';
  static const String editProfile = '/profile/edit';
  static String publicProfile(String id) => '/profile/$id';
  static const String notifications = '/notifications';

  Routes._();
}

// ── Router provider ──────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  final authListenable = authNotifier.routeListenable;
  final onboardingRefresh = ref.watch(onboardingRedirectListenProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: Listenable.merge([authListenable, onboardingRefresh]),
    redirect: (BuildContext context, GoRouterState state) {
      final authStatus = ref.read(authProvider).status;
      final loc = state.matchedLocation;

      // Splash is not "on auth" — we must leave it when we know auth state
      final isOnAuthPage = loc == Routes.login ||
          loc == Routes.register ||
          loc == Routes.forgotPassword;
      final isOnSplash = loc == Routes.splash;

      final onboardingPending = ref
              .read(sharedPreferencesProvider)
              .getBool(OnboardingPrefs.pendingKey) ??
          false;
      final isOnOnboarding = loc == Routes.onboardingWelcome ||
          loc == Routes.onboardingLocation ||
          loc == Routes.onboardingProfile;

      if (authStatus == AuthStatus.loading) return null;

      if (authStatus == AuthStatus.unauthenticated &&
          (!isOnAuthPage || isOnSplash)) {
        return Routes.login;
      }

      if (authStatus == AuthStatus.authenticated) {
        if (onboardingPending) {
          if (!isOnOnboarding) {
            return Routes.onboardingWelcome;
          }
          return null;
        }
        if (isOnOnboarding) {
          return Routes.home;
        }
        if (isOnAuthPage || isOnSplash) {
          return Routes.home;
        }
      }
      return null;
    },
    routes: [
      // ── Public / auth routes ──────────────────────────────
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        name: 'login',
        pageBuilder: (_, s) =>
            _fade(s, const LoginScreen()),
      ),
      GoRoute(
        path: Routes.register,
        name: 'register',
        pageBuilder: (_, s) =>
            _slide(s, const RegisterScreen()),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        name: 'forgotPassword',
        pageBuilder: (_, s) =>
            _slide(s, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: Routes.onboardingWelcome,
        name: 'onboardingWelcome',
        pageBuilder: (_, s) =>
            _slide(s, const OnboardingWelcomeScreen()),
      ),
      GoRoute(
        path: Routes.onboardingLocation,
        name: 'onboardingLocation',
        pageBuilder: (_, s) =>
            _slide(s, const OnboardingLocationScreen()),
      ),
      GoRoute(
        path: Routes.onboardingProfile,
        name: 'onboardingProfile',
        pageBuilder: (_, s) =>
            _slide(s, const OnboardingProfileScreen()),
      ),

      // ── Shell (bottom nav) ────────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            HomeScaffold(child: child),
        routes: [
          // Home
          GoRoute(
            path: Routes.home,
            name: 'home',
            builder: (_, __) => const HomeScreen(),
          ),

          // Games — specific routes BEFORE /:id parameter
          GoRoute(
            path: Routes.games,
            name: 'games',
            builder: (_, __) => const GamesScreen(),
          ),

          // Chat list tab
          GoRoute(
            path: Routes.chats,
            name: 'chats',
            builder: (_, __) => const ChatListScreen(),
          ),

          // Performance
          GoRoute(
            path: Routes.performance,
            name: 'performance',
            builder: (_, __) => const PerformanceScreen(),
          ),

          // Profile
          GoRoute(
            path: Routes.profile,
            name: 'profile',
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'friends',
                name: 'friends',
                pageBuilder: (_, s) =>
                    _slide(s, const FriendsListScreen()),
              ),
              GoRoute(
                path: 'edit',
                name: 'editProfile',
                pageBuilder: (_, s) =>
                    _slide(s, const EditProfileScreen()),
              ),
            ],
          ),
        ],
      ),

      // ── Full-screen routes (outside shell) ────────────────
      GoRoute(
        path: Routes.createGame,
        name: 'createGame',
        pageBuilder: (_, s) =>
            _slide(s, const CreateGameScreen()),
      ),
      GoRoute(
        path: Routes.calendar,
        name: 'calendar',
        pageBuilder: (_, s) =>
            _slide(s, const CalendarScreen()),
      ),
      GoRoute(
        path: '/games/:id',
        name: 'gameDetail',
        pageBuilder: (_, s) => _slide(
          s,
          GameDetailScreen(gameId: s.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/games/:id/edit',
        name: 'editGame',
        pageBuilder: (_, s) => _slide(
          s,
          EditGameScreen(gameId: s.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: Routes.createLog,
        name: 'createLog',
        pageBuilder: (_, s) =>
            _slide(s, const CreateLogScreen()),
      ),
      GoRoute(
        path: '/profile/:id',
        name: 'publicProfile',
        pageBuilder: (_, s) => _slide(
          s,
          ProfileScreen(userId: s.pathParameters['id']),
        ),
      ),
      // ── Chat room (full screen — hides bottom nav) ────────────
      GoRoute(
        path: '/chats/:id',
        name: 'chatRoom',
        pageBuilder: (_, s) => _slide(
          s,
          ChatScreen(chatId: s.pathParameters['id']!),
        ),
      ),
      // ── Admin dashboard (admin role only) ─────────────────────
      GoRoute(
        path: Routes.adminDashboard,
        name: 'adminDashboard',
        pageBuilder: (_, s) => _slide(s, const AdminDashboardScreen()),
      ),
      // ── Notifications inbox (full screen — hides bottom nav) ──
      GoRoute(
        path: Routes.notifications,
        name: 'notifications',
        pageBuilder: (_, s) => _slide(s, const NotificationsScreen()),
      ),
    ],
    errorBuilder: (context, state) =>
        _ErrorPage(error: state.error),
  );
});

// ── Transitions ───────────────────────────────────────────────────────────────
CustomTransitionPage<void> _fade(GoRouterState s, Widget child) =>
    CustomTransitionPage<void>(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );

CustomTransitionPage<void> _slide(GoRouterState s, Widget child) =>
    CustomTransitionPage<void>(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: anim.drive(
          Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        ),
        child: child,
      ),
    );

// ── 404 ───────────────────────────────────────────────────────────────────────
class _ErrorPage extends StatelessWidget {
  const _ErrorPage({required this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('Page not found'),
            if (error != null)
              Text(error.toString(),
                  style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
