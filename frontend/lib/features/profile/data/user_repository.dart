import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/core/network/api_endpoints.dart';
import 'package:buddbull/features/auth/data/models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// ── Provider ─────────────────────────────────────────────────────────────────
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(apiClientProvider));
});

// ── UserRepository ────────────────────────────────────────────────────────────
class UserRepository {
  const UserRepository(this._api);
  final ApiClient _api;

  // ── Get current user ──────────────────────────────────────────
  Future<UserModel> getMe() async {
    final body = await _api.get(ApiEndpoints.me);
    final data = body['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  // ── Get public profile ────────────────────────────────────────
  Future<UserModel> getUserProfile(String id) async {
    final body = await _api.get(ApiEndpoints.userProfile(id));
    final data = body['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  // ── Update profile ────────────────────────────────────────────
  Future<UserModel> updateMe(Map<String, dynamic> updates) async {
    final body = await _api.patch(ApiEndpoints.me, data: updates);
    final data = body['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  // ── Update profile picture ────────────────────────────────────
  Future<UserModel> updateProfilePicture(XFile image) async {
    final formData = FormData.fromMap({
      'profilePicture': await MultipartFile.fromFile(
        image.path,
        filename: image.name,
      ),
    });
    final body = await _api.postMultipart(
      ApiEndpoints.updateProfilePicture,
      formData,
    );
    final data = body['data'] as Map<String, dynamic>;
    final userJson = data['user'] as Map<String, dynamic>?;
    if (userJson != null) {
      return UserModel.fromJson(userJson);
    }
    final pic = data['profilePicture'] as String?;
    final me = await getMe();
    if (pic != null) return me.copyWith(profilePicture: pic);
    return me;
  }

  // ── Friends / friend requests ─────────────────────────────────
  Future<String> sendFriendRequest(String id) async {
    final body = await _api.post(ApiEndpoints.followUser(id));
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return data['requestId']?.toString() ?? '';
  }

  Future<int?> acceptFriendRequest(String requestId) async {
    final body = await _api.post(ApiEndpoints.acceptFriendRequest(requestId));
    final data = body['data'] as Map<String, dynamic>?;
    return (data?['friendsCount'] as num?)?.toInt();
  }

  Future<void> declineFriendRequest(String requestId) =>
      _api.post(ApiEndpoints.declineFriendRequest(requestId));

  Future<void> unfriend(String id) =>
      _api.delete(ApiEndpoints.unfollowUser(id));

  Future<List<UserModel>> getFriends() async {
    final body = await _api.get(ApiEndpoints.myFriends);
    final data = body['data'] as Map<String, dynamic>;
    final list = data['friends'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList();
  }

  // ── Search users ──────────────────────────────────────────────
  Future<List<UserModel>> searchUsers({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    try {
      return await _fetchUserSearchResults(
        queryParams: {'q': trimmed, 'page': page, 'limit': limit},
      );
    } catch (_) {
      // Fallback when full-text search is unavailable — match by city name.
      return _fetchUserSearchResults(
        queryParams: {'city': trimmed, 'page': page, 'limit': limit},
      );
    }
  }

  Future<List<UserModel>> _fetchUserSearchResults({
    required Map<String, dynamic> queryParams,
  }) async {
    final body = await _api.get(
      ApiEndpoints.searchUsers,
      queryParams: queryParams,
    );
    final list = (body['users'] as List<dynamic>?) ??
        ((body['data'] as Map<String, dynamic>?)?['users'] as List<dynamic>?) ??
        const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList();
  }

  // ── Get followers / following ─────────────────────────────────
  Future<List<UserModel>> getFollowers(String userId) async {
    final body = await _api.get(ApiEndpoints.userFollowers(userId));
    final data = body['data'] as Map<String, dynamic>;
    final list = data['followers'] as List<dynamic>;
    return list
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserModel>> getFollowing(String userId) async {
    final body = await _api.get(ApiEndpoints.userFollowing(userId));
    final data = body['data'] as Map<String, dynamic>;
    final list = data['following'] as List<dynamic>;
    return list
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Delete account ────────────────────────────────────────────
  Future<void> deleteAccount() => _api.delete(ApiEndpoints.me);
}
