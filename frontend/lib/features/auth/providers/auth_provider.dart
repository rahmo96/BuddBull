import 'package:buddbull/features/auth/data/auth_repository.dart';
import 'package:buddbull/features/auth/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  ),
);

// ── Notifier ─────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState()) {
    _bootstrap();
  }

  final AuthRepository _repo;

  /// A [ChangeNotifier] that go_router listens to for redirects.
  final routeListenable = _AuthListenable();

  // ── Bootstrap ─────────────────────────────────────────────────
  Future<void> _bootstrap() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      routeListenable.notify();
      return;
    }

    try {
      final user = await _repo.getMe();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      // Firebase user exists but backend profile fetch failed.
      state = state.copyWith(status: AuthStatus.authenticated);
    }
    routeListenable.notify();
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
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // CRITICAL: create/sync MongoDB profile after Firebase registration
      final user = await _repo.syncUserProfile(
        firstName: firstName,
        lastName: lastName,
        username: username,
        role: role,
      );

      state = AuthState(status: AuthStatus.authenticated, user: user);
      routeListenable.notify();
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: _extractMessage(e),
      );
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
    await FirebaseAuth.instance.signOut();
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
