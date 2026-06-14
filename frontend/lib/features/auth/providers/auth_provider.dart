import 'dart:async';

import 'package:buddbull/core/error/app_exception.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/core/services/push_notification_service.dart';
import 'package:buddbull/features/auth/data/auth_repository.dart';
import 'package:buddbull/features/auth/data/models/user_model.dart';
import 'package:buddbull/features/onboarding/data/onboarding_prefs.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── State ─────────────────────────────────────────────────────────────────────
enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.loading,
    this.user,
    this.error,
    this.isSubmitting = false,
    this.successMessage,
  });

  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool isSubmitting;
  final String? successMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool clearError = false,
    bool? isSubmitting,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: clearError ? null : error ?? this.error,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(sharedPreferencesProvider),
    onBeforeLogout: () =>
        ref.read(pushNotificationServiceProvider).unregisterTokenIfAuthenticated(),
  ),
);

/// Convenience view onto the currently signed-in user. Feature widgets and
/// their tests depend on this thin provider so tests can override the
/// current user via `overrideWithValue(...)` without constructing a fake
/// [AuthNotifier] (which subscribes to FirebaseAuth in its constructor).
final currentUserProvider = Provider<UserModel?>(
  (ref) => ref.watch(authProvider).user,
);

// ── Notifier ─────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo, this._prefs, {Future<void> Function()? onBeforeLogout})
      : _onBeforeLogout = onBeforeLogout,
        super(const AuthState()) {
    _listenToAuthChanges();
  }

  final AuthRepository _repo;
  final SharedPreferences _prefs;
  final Future<void> Function()? _onBeforeLogout;
  bool _isRegistering = false;

  /// A [ChangeNotifier] that go_router listens to for redirects.
  final routeListenable = _AuthListenable();

  StreamSubscription<User?>? _authSub;

  // ── Firebase auth listener (source of truth) ───────────────────
  void _listenToAuthChanges() {
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.idTokenChanges().listen(
      (fbUser) async {
        if (fbUser == null) {
          state = const AuthState(status: AuthStatus.unauthenticated);
          routeListenable.notify();
          return;
        }

        if (_isRegistering) {
          // Avoid race: idTokenChanges fires immediately after Firebase user creation,
          // before the backend profile sync completes. Registration flow will set the
          // final authenticated+profile state when ready.
          return;
        }

        // Move off splash immediately; hydrate profile in background.
        state = const AuthState(status: AuthStatus.authenticated);
        routeListenable.notify();

        try {
          final user = await _repo.getMe();
          state = AuthState(status: AuthStatus.authenticated, user: user);
        } catch (e) {
          if (e is AppException && e.statusCode == 401) {
            if (_isRegistering) return;
            state = const AuthState(
              status: AuthStatus.unauthenticated,
              error: 'Session expired. Please log in again.',
            );
            routeListenable.notify();
            try {
              await FirebaseAuth.instance.signOut();
            } catch (_) {}
            return;
          }

          // Firebase user exists but backend profile fetch failed.
          state = const AuthState(status: AuthStatus.authenticated);
        }
        routeListenable.notify();
      },
      onError: (_, __) async {
        if (_isRegistering) return;
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          error: 'Session expired. Please log in again.',
        );
        routeListenable.notify();
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
      },
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // ── Register ──────────────────────────────────────────────────
  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    _isRegistering = true;
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = cred.user;
      if (fbUser != null) {
        try {
          await fbUser.sendEmailVerification();
        } catch (_) {}
      }

      // CRITICAL: create/sync MongoDB profile after Firebase registration
      UserModel user;
      try {
        user = await _repo.syncUserProfile(
          firstName: firstName,
          lastName: lastName,
          username: username,
          role: role,
        );
      } catch (e) {
        final statusCode = switch (e) {
          DioException(response: final r) => r?.statusCode,
          AppException(statusCode: final c) => c,
          _ => null,
        };

        if (statusCode == 409) {
          // User already exists in DB. Treat as success and fetch profile.
          user = await _repo.getMe();
        } else {
          rethrow;
        }
      }

      await _prefs.setBool(OnboardingPrefs.pendingKey, true);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      routeListenable.notify();
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Registration failed. Please try again.',
      );
    } finally {
      _isRegistering = false;
    }
  }

  // ── Login ─────────────────────────────────────────────────────
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = await _repo.getMe();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      routeListenable.notify();
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: _extractMessage(e),
      );
    }
  }

  // ── Logout ────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _onBeforeLogout?.call();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
    await _prefs.setBool(OnboardingPrefs.pendingKey, false);
    state = const AuthState(status: AuthStatus.unauthenticated);
    routeListenable.notify();
  }

  // ── Forgot password ───────────────────────────────────────────
  Future<void> forgotPassword(String email) async {
    state = state.copyWith(
        isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Reset link sent! Check your inbox.',
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: _extractMessage(e),
      );
    }
  }

  // ── Update local user ─────────────────────────────────────────
  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  /// Called when refresh fails (401); clears auth state so router redirects to login.
  void setSessionExpired() {
    state = const AuthState(status: AuthStatus.unauthenticated);
    routeListenable.notify();
  }

  // ── Clear error/success ───────────────────────────────────────
  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);

  // ── Helpers ───────────────────────────────────────────────────
  String _extractMessage(Object e) {
    final raw = e.toString();
    // Strip class name prefix added by AppException.toString()
    final match = RegExp(r'\): (.+)$').firstMatch(raw);
    return match?.group(1) ?? raw;
  }
}

// ── Route listenable ─────────────────────────────────────────────────────────
class _AuthListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}
