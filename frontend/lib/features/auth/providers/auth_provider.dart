import 'package:buddbull/core/storage/secure_storage.dart';
import 'package:buddbull/features/auth/data/auth_repository.dart';
import 'package:buddbull/features/auth/data/models/user_model.dart';
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
    ref.watch(secureStorageProvider),
  ),
);

// ── Notifier ─────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo, this._storage) : super(const AuthState()) {
    _bootstrap();
  }

  final AuthRepository _repo;
  final SecureStorage _storage;

  /// A [ChangeNotifier] that go_router listens to for redirects.
  final routeListenable = _AuthListenable();

  // ── Bootstrap ─────────────────────────────────────────────────
  Future<void> _bootstrap() async {
    final user = await _repo.tryRestoreSession();
    if (user != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
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
      final result = await _repo.register(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
        role: role,
      );
      await _persist(result.accessToken, result.refreshToken, result.user.id);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      );
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
      final result = await _repo.login(email: email, password: password);
      await _persist(result.accessToken, result.refreshToken, result.user.id);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      );
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
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
    routeListenable.notify();
  }

  // ── Forgot password ───────────────────────────────────────────
  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _repo.forgotPassword(email);
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
  Future<void> _persist(String access, String refresh, String userId) async {
    await Future.wait([
      _storage.saveAccessToken(access),
      _storage.saveRefreshToken(refresh),
      _storage.saveUserId(userId),
    ]);
  }

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
