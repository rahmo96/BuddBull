import 'package:dio/dio.dart';
import 'api_client.dart';

/// Fetches and updates user profile from the backend.
class ProfileService {
  final Dio _dio = ApiClient.instance;

  /// GET /api/users/profile?firebaseUid=xxx
  Future<Map<String, dynamic>> getProfile(String firebaseUid) async {
    final response = await _dio.get(
      '/users/profile',
      queryParameters: {'firebaseUid': firebaseUid},
    );
    return response.data as Map<String, dynamic>;
  }

  /// PUT /api/users/profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> payload) async {
    final response = await _dio.put('/users/profile', data: payload);
    return response.data as Map<String, dynamic>;
  }
}
