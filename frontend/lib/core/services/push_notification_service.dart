import 'dart:async';

import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/core/network/api_endpoints.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Must match backend FCM `android.notification.channel_id`
/// (`backend/src/services/notification.service.js`).
const String kBuddbullAndroidNotificationChannelId = 'buddbull_default';

/// Channel registered from [PushNotificationService] **and** from
/// [firebaseMessagingBackgroundHandler] so FCM can target this id in a cold /
/// background isolate before the main app runs.
///
/// `AndroidNotificationChannel` has no `Priority` field; use
/// [kBuddbullAndroidHeadsUpDetails] when calling `show()`. FCM heads-up uses
/// channel importance plus server `android.notification` priority.
const AndroidNotificationChannel kBuddbullAndroidNotificationChannel =
    AndroidNotificationChannel(
  kBuddbullAndroidNotificationChannelId,
  'General',
  description: 'BuddBull heads-up alerts',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  enableLights: true,
  ledColor: Color(0xFF1565C0),
);

/// Per-notification template if you later show local notifications from Dart.
const AndroidNotificationDetails kBuddbullAndroidHeadsUpDetails =
    AndroidNotificationDetails(
  kBuddbullAndroidNotificationChannelId,
  'General',
  channelDescription: 'BuddBull heads-up alerts',
  importance: Importance.max,
  priority: Priority.high,
  playSound: true,
  enableVibration: true,
  enableLights: true,
  ledColor: Color(0xFF1565C0),
);

/// Must be registered in `main()` via [FirebaseMessaging.onBackgroundMessage]
/// before `runApp` (separate isolate entry-point).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (defaultTargetPlatform == TargetPlatform.android) {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(kBuddbullAndroidNotificationChannel);
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(ref);
  ref.onDispose(service.dispose);
  return service;
});

/// FCM + local notification channel registration.
///
/// Foreground [FirebaseMessaging.onMessage] does **not** show a second banner:
/// Socket.io already delivers `notification:new` for the inbox.
class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  bool _started = false;
  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> ensureInitialized() async {
    if (_started || kIsWeb) return;
    _started = true;

    await _initLocalNotifications();
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
      (_) => unawaited(syncTokenIfAuthenticated()),
    );

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigateFromPushData(initial.data);
      });
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _local.initialize(settings: initSettings);

    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      kBuddbullAndroidNotificationChannel,
    );
    if (defaultTargetPlatform == TargetPlatform.android) {
      await androidPlugin?.requestNotificationsPermission();
    }
    if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
      assert(kBuddbullAndroidHeadsUpDetails.priority == Priority.high);
      assert(kBuddbullAndroidHeadsUpDetails.importance == Importance.max);
    }
  }

  Future<void> syncTokenIfAuthenticated() async {
    if (kIsWeb) return;
    final auth = _ref.read(authProvider);
    if (auth.status != AuthStatus.authenticated) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      final platform = switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'ios',
        TargetPlatform.android => 'android',
        _ => 'web',
      };

      await _ref.read(apiClientProvider).post(
            ApiEndpoints.pushToken,
            data: {'token': token, 'platform': platform},
          );
    } catch (e, st) {
      debugPrint('⚠️ Push token sync failed: $e\n$st');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint(
        '[FCM foreground] id=${message.messageId} title=${message.notification?.title}',
      );
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    navigateFromPushData(message.data);
  }

  /// Maps FCM `data` (string values from the server) to a GoRouter path.
  @visibleForTesting
  String pathForPushData(Map<String, dynamic> raw) {
    final data = {
      for (final e in raw.entries) e.key: e.value?.toString() ?? '',
    };
    final type = data['type'] ?? '';

    final chatId = data['chatId'];
    if (type == 'new_message' && chatId != null && chatId.isNotEmpty) {
      return Routes.chatRoom(chatId);
    }

    final gameId = data['gameId'];
    if (gameId != null && gameId.isNotEmpty) {
      return Routes.gameDetail(gameId);
    }

    final userId = data['userId'];
    if (userId != null && userId.isNotEmpty) {
      return Routes.publicProfile(userId);
    }

    return Routes.notifications;
  }

  void navigateFromPushData(Map<String, dynamic> data) {
    final path = pathForPushData(data);

    void go() {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null) return;
      GoRouter.of(ctx).push(path);
    }

    if (rootNavigatorKey.currentContext != null) {
      go();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => go());
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }
}
