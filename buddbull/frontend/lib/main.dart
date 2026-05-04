import 'package:buddbull/app.dart';
import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bulletproof Firebase init for cold start + Hot Restart.
///
/// `Firebase.apps` can disagree with the native Firebase SDK after Hot Restart;
/// always pair the early return with a `duplicate-app` catch.
Future<void> _ensureFirebaseInitialized() async {
  if (Firebase.apps.isNotEmpty) {
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      return;
    }
    rethrow;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _ensureFirebaseInitialized();

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
          return ApiClient(
            onSessionExpired: () =>
                ref.read(authProvider.notifier).setSessionExpired(),
          );
        }),
      ],
      child: const BuddBullApp(),
    ),
  );
}
