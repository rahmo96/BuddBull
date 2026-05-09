import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:buddbull/features/auth/presentation/screens/login_screen.dart';
import 'package:buddbull/features/auth/presentation/screens/register_screen.dart';
import 'package:buddbull/shared/widgets/bb_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Minimal router for exercising auth-screen navigation inside widget tests.
GoRouter authTestRouter({String initialLocation = Routes.login}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
    ],
  );
}

/// Locates [TextFormField] under [BbTextField] by its visible label.
Finder textFieldBelowLabel(String label) {
  return find.descendant(
    of: find.ancestor(
      of: find.text(label),
      matching: find.byType(BbTextField),
    ),
    matching: find.byType(TextFormField),
  );
}
