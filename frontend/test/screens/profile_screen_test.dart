import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/profile/presentation/screens/profile_screen.dart';
import 'package:buddbull/shared/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await initTestFirebaseAndBinding();
  });

  group('ProfileScreen', () {
    testWidgets(
        'should show loading fallback while profile auth data is hydrating',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(BbLoadingIndicator), findsWidgets);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });
}
