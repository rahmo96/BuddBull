import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/core/network/api_endpoints.dart';
import 'package:buddbull/core/storage/secure_storage.dart';
import 'package:buddbull/features/auth/data/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Provider ─────────────────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

// ── AuthRepository ────────────────────────────────────────────────────────────
class AuthRepository {
  const AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final SecureStorage _storage;

  // ── Register ──────────────────────────────────────────────────
  Future<({UserModel user, String accessToken, String refreshToken})>
      register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final body = await _api.post(
      ApiEndpoints.register,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      },
    );
    return _extractTokensAndUser(body);
  }

  // ── Login ─────────────────────────────────────────────────────
  Future<({UserModel user, String accessToken, String refreshToken})>
      login({
    required String email,
    required String password,
  }) async {
    final body = await _api.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return _extractTokensAndUser(body);
  }

  // ── Logout ────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _api.post(
          ApiEndpoints.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } finally {
      await _storage.clearTokens();
    }
  }

  // ── Forgot password ───────────────────────────────────────────
  Future<void> forgotPassword(String email) async {
    await _api.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  // ── Reset password ────────────────────────────────────────────
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _api.post(
      ApiEndpoints.resetPassword,
      data: {'token': token, 'password': password},
    );
  }

  // ── Fetch current user ────────────────────────────────────────
  Future<UserModel> getMe() async {
    final body = await _api.get(ApiEndpoints.me);
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(userJson);
  }

  // ── Check stored session ──────────────────────────────────────
  Future<UserModel?> tryRestoreSession() async {
    final hasTokens = await _storage.hasTokens();
    if (!hasTokens) return null;
    try {
      return await getMe();
    } catch (_) {
      await _storage.clearTokens();
      return null;
    }
  }

  // ── Internal helper ───────────────────────────────────────────
  ({UserModel user, String accessToken, String refreshToken})
      _extractTokensAndUser(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final accessToken = data['accessToken'] as String? ?? '';
    final refreshToken = data['refreshToken'] as String? ?? '';
    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    return (
      user: UserModel.fromJson(userJson),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
