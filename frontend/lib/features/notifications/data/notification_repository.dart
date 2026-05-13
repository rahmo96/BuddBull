import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/core/network/api_endpoints.dart';
import 'package:buddbull/features/notifications/data/notification_model.dart';

/// Thin wrapper around the REST surface exposed by
/// `backend/src/routes/notification.routes.js`.
///
/// Stays free of Riverpod / Flutter imports so it can be unit-tested
/// against a stub `ApiClient` without touching the widget tree.
class NotificationRepository {
  const NotificationRepository(this._client);

  final ApiClient _client;

  /// `GET /notifications?page=&limit=` — returns the inbox page plus
  /// the current unread count (used by the bell badge).
  Future<NotificationPage> getNotifications({
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _client.get(
      ApiEndpoints.notifications,
      queryParams: {'page': page, 'limit': limit},
    );
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    return NotificationPage.fromJson(data);
  }

  /// `PATCH /notifications/:id/read` — flips one row to read.
  Future<NotificationModel> markAsRead(String id) async {
    final res = await _client.patch(ApiEndpoints.notificationRead(id));
    final raw = (res['data'] as Map<String, dynamic>?)?['notification']
        as Map<String, dynamic>?;
    if (raw == null) {
      throw StateError('Malformed mark-read response from $id');
    }
    return NotificationModel.fromJson(raw);
  }

  /// `PATCH /notifications/read-all` — clears the unread badge in one
  /// shot. Returns the number of rows actually touched so the UI can
  /// show a friendly toast.
  Future<int> markAllAsRead() async {
    final res = await _client.patch(ApiEndpoints.notificationsReadAll);
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    return (data['modified'] as num?)?.toInt() ?? 0;
  }
}
