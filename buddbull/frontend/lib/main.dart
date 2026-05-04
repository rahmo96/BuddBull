import 'package:buddbull/app.dart';
import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/core/storage/secure_storage.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWith((ref) {
          final storage = ref.watch(secureStorageProvider);
          return ApiClient(
            storage,
            onSessionExpired: () =>
                ref.read(authProvider.notifier).setSessionExpired(),
          );
        }),
      ],
      child: const BuddBullApp(),
    ),
  );
}
