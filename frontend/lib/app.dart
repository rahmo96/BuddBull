import 'dart:async';

import 'package:buddbull/core/constants/app_strings.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/core/services/push_notification_service.dart';
import 'package:buddbull/core/theme/app_theme.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root application widget.
/// [ProviderScope] is injected by main.dart, so this widget only needs
/// to consume the router and theme.
class BuddBullApp extends ConsumerStatefulWidget {
  const BuddBullApp({super.key});

  @override
  ConsumerState<BuddBullApp> createState() => _BuddBullAppState();
}

class _BuddBullAppState extends ConsumerState<BuddBullApp> with WidgetsBindingObserver {
  bool _scheduledPushBootstrap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(pushNotificationServiceProvider).recordActivityHeartbeat());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_scheduledPushBootstrap) {
      _scheduledPushBootstrap = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(ref.read(pushNotificationServiceProvider).ensureInitialized());
      });
    }

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(ref.read(pushNotificationServiceProvider).syncTokenIfAuthenticated());
        });
      }
    });

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        // Enforce minimum text scale factor to prevent layout breakage
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(
              mediaQuery.textScaler.scale(1.0).clamp(0.85, 1.2),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
