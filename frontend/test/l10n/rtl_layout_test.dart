import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/chat/data/models/chat_model.dart';
import 'package:buddbull/features/chat/presentation/widgets/message_bubble.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/games/presentation/widgets/game_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/auth_router.dart';
import '../helpers/l10n_app.dart';
import '../helpers/test_bootstrap.dart';

const _longHebrew =
    'זהו טקסט ארוך מאוד בעברית שנועד לבדוק גלישה בשורות צרות במכשירים קטנים '
    'ובגודל גופן מוגדל לצורך בדיקה יסודית';
const _longWord = 'אאאאאאאאאאבבבבבבבבבבגגגגגגגגגג'; // 30 chars, no spaces

Future<void> _setNarrowScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(320 * 3, 640 * 3);
  tester.view.devicePixelRatio = 3.0;
  tester.platformDispatcher.textScaleFactorTestValue = 1.2;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  setUpAll(() async {
    await initTestFirebaseAndBinding();
  });

  Future<void> pumpAuth(WidgetTester tester, String location) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _setNarrowScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: l10nRouterApp(
          authTestRouter(initialLocation: location),
          locale: const Locale('he'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('login does not overflow in Hebrew at 320px and 1.2x text',
      (tester) async {
    await pumpAuth(tester, Routes.login);

    expect(find.text(heL10n.authLoginButton), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');
    final ctx = tester.element(find.text(heL10n.authLoginButton));
    expect(Directionality.of(ctx), TextDirection.rtl);
  });

  testWidgets('register does not overflow in Hebrew at 320px and 1.2x text',
      (tester) async {
    await pumpAuth(tester, Routes.register);

    expect(find.text(heL10n.authRegisterButton), findsWidgets);
    expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');
  });

  testWidgets('GameCard survives long Hebrew text at 320px', (tester) async {
    await _setNarrowScreen(tester);
    final game = GameModel(
      id: 'g1',
      title: '$_longHebrew $_longWord',
      sport: 'football',
      organizer: const GameOrganizer(
        id: 'o1',
        username: 'org',
        firstName: 'מארגן',
        lastName: _longWord,
      ),
      scheduledAt: DateTime(2026, 10, 7, 18),
      durationMinutes: 90,
      location: const GameLocation(
        city: 'תל אביב',
        neighborhood: _longWord,
        formattedAddress: _longHebrew,
      ),
      maxPlayers: 10,
      requiredSkillLevel: 'any',
      status: 'open',
      players: const [],
    );

    await tester.pumpWidget(
      l10nMaterialApp(
        locale: const Locale('he'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: GameCard(game: game, onTap: () {}),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');
  });

  testWidgets('MessageBubble survives long Hebrew text at 320px, own and other',
      (tester) async {
    await _setNarrowScreen(tester);
    final message = MessageModel(
      id: 'm1',
      chatId: 'c1',
      sender: const {'_id': 'u2', 'firstName': 'דנה', 'lastName': 'לוי'},
      type: 'text',
      content: '$_longHebrew $_longWord',
      sentAt: DateTime(2026, 10, 7, 18, 30),
    );

    await tester.pumpWidget(
      l10nMaterialApp(
        locale: const Locale('he'),
        home: Scaffold(
          body: ListView(
            children: [
              MessageBubble(message: message, isMe: true),
              MessageBubble(
                message: message,
                isMe: false,
                showSenderName: true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');
  });
}
