import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/core/network/api_endpoints.dart';
import 'package:buddbull/features/auth/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Provider ─────────────────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
  );
});

// ── AuthRepository ────────────────────────────────────────────────────────────
class AuthRepository {
  const AuthRepository(this._api);

  final ApiClient _api;

  // ── Sync user profile (Mongo) ─────────────────────────────────
  Future<UserModel> syncUserProfile({
    required String firstName,
    required String lastName,
    required String username,
    required String role,
  }) async {
    final body = await _api.post(
      '/auth/sync',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'role': role,
      },
    );

    final data = body['data'] as Map<String, dynamic>? ?? {};
    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(userJson);
  }

  // ── Fetch current user ────────────────────────────────────────
  Future<UserModel> getMe() async {
    final body = await _api.get(ApiEndpoints.me);
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(userJson);
  }

  // ── Check Firebase session ────────────────────────────────────
  Future<UserModel?> tryRestoreSession() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) return null;
    return getMe();
  }
}
