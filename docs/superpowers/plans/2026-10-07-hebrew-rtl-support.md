# Hebrew & RTL Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the BuddBull Flutter app usable in Hebrew with correct RTL layout, following the device language by default with a manual override in the Profile screen.

**Architecture:** Flutter `gen_l10n` (ARB files `app_en.arb` / `app_he.arb`, generated `AppLocalizations`). A Riverpod `localeProvider` (persisted in `shared_preferences`, `null` = follow device) feeds `MaterialApp.router`, whose `localeResolutionCallback` maps any Hebrew device language (`he`/`iw`) to `he` and everything else to `en`. RTL comes from Flutter's automatic `Directionality`; directional code is converted to start/end-aware equivalents. Hebrew glyphs come from a bundled Heebo font added as a `fontFamilyFallback` to the existing text styles.

**Tech Stack:** Flutter 3.41.9 / Dart 3.11.5, `flutter_localizations`, `intl ^0.20.2`, `flutter_riverpod ^2.6.1`, `go_router ^14.6.1`, `shared_preferences`, `fonttools` (one-off, to cut static font weights).

**Spec:** `docs/superpowers/specs/2026-10-07-hebrew-rtl-support-design.md`

**Deviation from spec §4 (typography):** the spec proposed a locale-aware `AppTheme` (Inter for en, Heebo for he). `AppTextStyles` hardcodes `fontFamily: 'Inter'` in every const style (`lib/core/constants/app_text_styles.dart`), so a theme-level switch would not reach them. This plan instead adds `fontFamilyFallback: ['Heebo']` to those styles and the theme. Inter has no Hebrew glyphs, so Hebrew (and Hebrew names inside English UI) falls back per-glyph to Heebo. Heebo is **bundled** as an asset (resolves the spec's open question about offline use).

## Global Constraints

- Supported locales: exactly `en` and `he`. Device language `iw` (legacy Hebrew) must resolve to `he`; any other language resolves to `en`.
- Persisted preference key: `app_locale`; stored value is the language code (`en` or `he`); absent = follow device.
- Out of scope, stays English: all admin screens (`lib/features/admin/**`), backend error messages, push notification text.
- `AppStrings.appName` ('BuddBull') stays a constant, untranslated.
- ARB key naming: `<feature><Thing>` camelCase (e.g. `authLoginTitle`, `gamesJoinButton`). `app_en.arb` is the template; `app_he.arb` must have an identical key set and identical placeholders.
- Language names in the picker are shown in their own language and are never translated: `English`, `עברית`.
- Backend-provided dynamic values (names, game titles, addresses) are displayed as received.
- Use `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, `TextAlign.start/end` for any directional layout.
- No unrelated refactoring. Don't touch the pre-existing uncommitted changes in the working tree (`backend/load/*`, `socket_service.dart`, `game_model.dart` edits, etc.). Stage files **explicitly by path**, never `git add -A`. `pubspec.lock` already has uncommitted changes; the lock diff is committed with Task 1 and should be reviewed (`git diff frontend/pubspec.lock`) before staging.
- Every task ends with `flutter analyze` clean for touched files and `flutter test` green.

## Review Focus

1. **Legacy/other device languages:** device locale `iw`, `fr`, `ar`, or `null` must resolve to `he`, `en`, `en`, `en`. (Task 2 tests.)
2. **Corrupt stored preference:** prefs containing `app_locale = 'fr'` (or an empty string) must behave as "follow device" and must not crash startup. (Task 2 tests.)
3. **Stale formatted dates after switching language:** date text on a screen must change language when the user switches locale; call sites with a `BuildContext` pass `context.l10n.localeName` explicitly so they depend on `Localizations`. (Task 3 test, Task 8 call sites.)
4. **Long Hebrew strings / large text scale:** key screens at 320 px width and text scale 1.2 in Hebrew must not overflow. (Task 11 tests.)
5. **Hebrew plurals / placeholders:** count-dependent strings must read correctly for 0/1/2/many in Hebrew, and `en`/`he` ARB placeholders must match. (Task 6 parity test; Task 10 plural test.)

---

## Migration Procedure (used by Tasks 7–10)

Each migration task converts one group of files from hardcoded English to `AppLocalizations`. Read this whole section before starting any of them.

1. **Inventory.** For each file in the task, list user-visible literals: `Text('…')`, `labelText`, `hintText`, `helperText`, `errorText`, `title`, `subtitle`, `label`, `tooltip`, `semanticLabel`, `content` (snackbars/dialogs), button labels, validator return strings, and `AppStrings.*` usages. Run the guard test first (Step 1 of each task) — it prints the offending `file:line` list.
2. **Add keys.** For every distinct string add a key to `lib/l10n/app_en.arb` (with `@key` description only when meaning is not obvious, always with `placeholders` for interpolations) and the Hebrew translation to `lib/l10n/app_he.arb`. Reuse an existing key when the English text and meaning are identical (e.g. a shared `commonCancel`). Counts use ICU plurals with explicit `=0`, `=1`, `=2`, `other` branches so Hebrew reads correctly.
3. **Replace usages.** `Text('Sign In')` → `Text(context.l10n.authLoginButton)`. Add `import 'package:buddbull/l10n/l10n.dart';`. Strings built inside `const` widget trees lose their `const`; remove `const` only on the enclosing widgets that now contain a runtime value. Strings needed where there is no `BuildContext` (validators, notifiers, models): pass an `AppLocalizations l10n` parameter from the widget (`validator: (v) => validateEmail(v, context.l10n)`), do not read a global.
4. **Regenerate.** `flutter gen-l10n` (also runs on `flutter run`/`flutter test`). Fix any ARB errors it reports.
5. **Tests.** Existing tests that `find.text(AppStrings.x)` for a migrated string must switch to `enL10n.<key>` (helper from Task 3) and pump the app via `l10nRouterApp` / `l10nMaterialApp` so delegates are present. Do not delete assertions.
6. **Guard.** Append the task's directories/files to `migratedPaths` in `test/l10n/no_hardcoded_strings_test.dart`. The test must pass. A literal that is intentionally not translatable (a brand name, a format pattern, a debug string) gets a trailing `// l10n-ignore: <reason>` comment on that line.
7. **Hebrew style guide.** Use this glossary so terms stay consistent across tasks: game = משחק, player = שחקן/ית (use the neutral plural שחקנים in lists; for buttons use infinitive/imperative-neutral forms like "הצטרפות" rather than gendered imperatives), organizer = מארגן/ת, join = הצטרפות, leave = עזיבה, sign in = התחברות, sign up / create account = יצירת חשבון, password = סיסמה, email = אימייל, profile = פרופיל, friends = חברים, chat = צ'אט, notifications = התראות, settings = הגדרות, search = חיפוש, cancel = ביטול, save = שמירה, delete = מחיקה, confirm = אישור, rating = דירוג, report = דיווח, sport = ענף ספורט, neighborhood = שכונה, city = עיר, radius = רדיוס. Prefer gender-neutral phrasing. Keep sentence punctuation in the Hebrew convention (period at end only where English has one).
8. **Verify.** `flutter analyze`, `flutter test`, then switch the app to Hebrew on an emulator (Profile → Language) and walk the migrated screens: text shows Hebrew, layout is mirrored, nothing overflows or clips. State what was and wasn't checked.
9. **Commit** the ARB files, generated files if tracked, edited sources, edited tests, and the guard test — by explicit path.

---

## File Structure

| Path | Responsibility |
|------|----------------|
| `frontend/l10n.yaml` (new) | `gen_l10n` config |
| `frontend/lib/l10n/app_en.arb`, `app_he.arb` (new) | Source strings |
| `frontend/lib/l10n/app_localizations*.dart` (generated) | Typed accessors; produced by `flutter gen-l10n` |
| `frontend/lib/l10n/l10n.dart` (new) | `context.l10n` extension + re-export |
| `frontend/lib/core/localization/locale_provider.dart` (new) | `LocaleNotifier`, `localeProvider`, `resolveAppLocale` |
| `frontend/lib/app.dart` (modify) | Wire locale, delegates, resolution, `Intl.defaultLocale` |
| `frontend/lib/features/profile/presentation/widgets/language_sheet.dart` (new) | Language picker bottom sheet |
| `frontend/lib/features/profile/presentation/screens/profile_screen.dart` (modify) | Language tile |
| `frontend/assets/fonts/Heebo-*.ttf` (new) | Bundled Hebrew font |
| `frontend/lib/core/constants/app_text_styles.dart`, `core/theme/app_theme.dart` (modify) | Heebo fallback |
| `frontend/test/helpers/l10n_app.dart` (new) | `l10nMaterialApp`, `l10nRouterApp`, `enL10n`, `heL10n` |
| `frontend/test/l10n/*.dart` (new) | Locale, parity, guard, RTL tests |

All commands below run from `frontend/` unless stated.

---

### Task 0: Baseline

**Files:** none changed.

- [ ] **Step 1: Record the baseline test result**

Run: `flutter pub get && flutter analyze && flutter test`
Expected: note exactly which tests (if any) already fail and any analyzer issues. Save the list in your task notes. Later tasks must not add failures beyond this baseline.

- [ ] **Step 2: Create an isolated branch**

Run: `git switch -c feature/hebrew-rtl`
Expected: switched to the new branch (working-tree changes carry over untouched).

---

### Task 1: Localization infrastructure (gen_l10n, ARB seed, `context.l10n`)

**Files:**
- Modify: `pubspec.yaml`
- Create: `l10n.yaml`, `lib/l10n/app_en.arb`, `lib/l10n/app_he.arb`, `lib/l10n/l10n.dart`
- Test: `test/l10n/l10n_extension_test.dart`

**Interfaces:**
- Produces: `AppLocalizations` (generated, `package:buddbull/l10n/app_localizations.dart`) with `AppLocalizations.localizationsDelegates`, `AppLocalizations.supportedLocales`, `localeName`, and keys `languageTitle`, `languageDeviceDefault`, `languageEnglish`, `languageHebrew`; `BuildContext.l10n` (`AppLocalizations`) from `package:buddbull/l10n/l10n.dart`; top-level `lookupAppLocalizations(Locale)`.

- [ ] **Step 1: Write the failing test**

`test/l10n/l10n_extension_test.dart`:

```dart
import 'package:buddbull/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('context.l10n resolves English and Hebrew strings', (tester) async {
    late String en;
    late String he;

    Future<void> pumpWith(Locale locale, void Function(String) sink) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              sink(context.l10n.languageTitle);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpWith(const Locale('en'), (s) => en = s);
    await pumpWith(const Locale('he'), (s) => he = s);

    expect(en, 'Language');
    expect(he, 'שפה');
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/l10n/l10n_extension_test.dart`
Expected: FAIL — `package:buddbull/l10n/l10n.dart` does not exist.

- [ ] **Step 3: Configure gen_l10n**

In `pubspec.yaml` under `dependencies:` add (after `flutter: sdk: flutter`):

```yaml
  flutter_localizations:
    sdk: flutter
```

and under the `flutter:` section add `generate: true` (next to `uses-material-design: true`):

```yaml
flutter:
  uses-material-design: true
  generate: true
```

`l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false
```

`lib/l10n/app_en.arb`:

```json
{
  "@@locale": "en",
  "languageTitle": "Language",
  "languageDeviceDefault": "Device default",
  "languageEnglish": "English",
  "languageHebrew": "עברית",
  "commonCancel": "Cancel"
}
```

`lib/l10n/app_he.arb`:

```json
{
  "@@locale": "he",
  "languageTitle": "שפה",
  "languageDeviceDefault": "ברירת המחדל של המכשיר",
  "languageEnglish": "English",
  "languageHebrew": "עברית",
  "commonCancel": "ביטול"
}
```

`lib/l10n/l10n.dart`:

```dart
import 'package:buddbull/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:buddbull/l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

- [ ] **Step 4: Generate and run the test**

Run: `flutter pub get && flutter gen-l10n && flutter test test/l10n/l10n_extension_test.dart`
Expected: generation succeeds (files appear in `lib/l10n/`), test PASSES. If the generated `app_localizations*.dart` files are git-ignored in this repo, leave them ignored; if not, commit them.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock l10n.yaml lib/l10n test/l10n/l10n_extension_test.dart
git commit -m "Add gen_l10n infrastructure with English and Hebrew ARB seeds.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

(Run `git status` first; add generated `lib/l10n/app_localizations*.dart` only if they show as untracked-not-ignored.)

---

### Task 2: `localeProvider` and locale resolution

**Files:**
- Create: `lib/core/localization/locale_provider.dart`
- Test: `test/l10n/locale_provider_test.dart`

**Interfaces:**
- Consumes: `sharedPreferencesProvider` (`lib/core/storage/shared_preferences_provider.dart`).
- Produces:
  - `const String kAppLocalePrefKey = 'app_locale';`
  - `Locale resolveAppLocale(Locale? requested)` — `he`/`iw` → `Locale('he')`, anything else (including `null`) → `Locale('en')`.
  - `class LocaleNotifier extends StateNotifier<Locale?>` with `Future<void> setLocale(Locale? locale)` (`null` clears the override).
  - `final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>`.

- [ ] **Step 1: Write the failing tests**

`test/l10n/locale_provider_test.dart`:

```dart
import 'package:buddbull/core/localization/locale_provider.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('resolveAppLocale', () {
    test('maps he and legacy iw to Hebrew', () {
      expect(resolveAppLocale(const Locale('he')), const Locale('he'));
      expect(resolveAppLocale(const Locale('he', 'IL')), const Locale('he'));
      expect(resolveAppLocale(const Locale('iw')), const Locale('he'));
    });

    test('maps everything else, including null, to English', () {
      expect(resolveAppLocale(const Locale('en')), const Locale('en'));
      expect(resolveAppLocale(const Locale('fr')), const Locale('en'));
      expect(resolveAppLocale(const Locale('ar')), const Locale('en'));
      expect(resolveAppLocale(null), const Locale('en'));
    });
  });

  group('localeProvider', () {
    test('defaults to null (follow device) when nothing is stored', () async {
      final c = await _container({});
      expect(c.read(localeProvider), isNull);
    });

    test('restores a stored language', () async {
      final c = await _container({kAppLocalePrefKey: 'he'});
      expect(c.read(localeProvider), const Locale('he'));
    });

    test('treats an unknown stored value as follow-device', () async {
      for (final bad in ['fr', '', 'HE ']) {
        final c = await _container({kAppLocalePrefKey: bad});
        expect(c.read(localeProvider), isNull, reason: 'stored "$bad"');
      }
    });

    test('setLocale persists and null clears', () async {
      final c = await _container({});
      final notifier = c.read(localeProvider.notifier);
      final prefs = c.read(sharedPreferencesProvider);

      await notifier.setLocale(const Locale('he'));
      expect(c.read(localeProvider), const Locale('he'));
      expect(prefs.getString(kAppLocalePrefKey), 'he');

      await notifier.setLocale(null);
      expect(c.read(localeProvider), isNull);
      expect(prefs.containsKey(kAppLocalePrefKey), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/l10n/locale_provider_test.dart`
Expected: FAIL — `locale_provider.dart` not found.

- [ ] **Step 3: Implement**

`lib/core/localization/locale_provider.dart`:

```dart
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kAppLocalePrefKey = 'app_locale';

const Locale _en = Locale('en');
const Locale _he = Locale('he');

/// Maps any requested/device locale to a supported one.
/// Hebrew (`he`, or the legacy Android code `iw`) → Hebrew; everything else → English.
Locale resolveAppLocale(Locale? requested) {
  final code = requested?.languageCode;
  return (code == 'he' || code == 'iw') ? _he : _en;
}

/// `null` state means "follow the device language".
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static Locale? _read(SharedPreferences prefs) {
    switch (prefs.getString(kAppLocalePrefKey)) {
      case 'en':
        return _en;
      case 'he':
        return _he;
      default:
        return null;
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await _prefs.remove(kAppLocalePrefKey);
    } else {
      await _prefs.setString(kAppLocalePrefKey, locale.languageCode);
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref.watch(sharedPreferencesProvider));
});
```

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/l10n/locale_provider_test.dart`
Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/localization/locale_provider.dart test/l10n/locale_provider_test.dart
git commit -m "Add persisted locale provider and Hebrew-aware locale resolution.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Wire the app + localized test helpers

**Files:**
- Modify: `lib/app.dart`
- Create: `test/helpers/l10n_app.dart`
- Test: `test/l10n/app_locale_wiring_test.dart`

**Interfaces:**
- Consumes: `localeProvider`, `resolveAppLocale` (Task 2); `AppLocalizations` (Task 1).
- Produces (test helpers, `test/helpers/l10n_app.dart`):
  - `final AppLocalizations enL10n`, `final AppLocalizations heL10n` (via `lookupAppLocalizations`).
  - `Widget l10nMaterialApp({Locale locale = const Locale('en'), Widget? home})`.
  - `Widget l10nRouterApp(RouterConfig<Object> router, {Locale locale = const Locale('en')})`.

- [ ] **Step 1: Write the helpers and the failing test**

`test/helpers/l10n_app.dart`:

```dart
import 'package:buddbull/core/localization/locale_provider.dart';
import 'package:buddbull/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final AppLocalizations enL10n = lookupAppLocalizations(const Locale('en'));
final AppLocalizations heL10n = lookupAppLocalizations(const Locale('he'));

Widget l10nMaterialApp({Locale locale = const Locale('en'), Widget? home}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    localeResolutionCallback: (device, _) => resolveAppLocale(device),
    builder: (context, child) {
      Intl.defaultLocale = Localizations.localeOf(context).languageCode;
      return child ?? const SizedBox.shrink();
    },
    home: home,
  );
}

Widget l10nRouterApp(
  RouterConfig<Object> router, {
  Locale locale = const Locale('en'),
}) {
  return MaterialApp.router(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    localeResolutionCallback: (device, _) => resolveAppLocale(device),
    routerConfig: router,
    builder: (context, child) {
      Intl.defaultLocale = Localizations.localeOf(context).languageCode;
      return child ?? const SizedBox.shrink();
    },
  );
}
```

`test/l10n/app_locale_wiring_test.dart`:

```dart
import 'package:buddbull/core/localization/locale_provider.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/l10n_app.dart';

void main() {
  testWidgets('Hebrew locale yields RTL and Hebrew dates; switching back updates both',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    TextDirection? dir;
    String? date;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            final locale = ref.watch(localeProvider) ?? const Locale('en');
            return MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) {
                Intl.defaultLocale = Localizations.localeOf(context).languageCode;
                return child!;
              },
              home: Builder(
                builder: (context) {
                  dir = Directionality.of(context);
                  // Call sites with a context pass the locale explicitly.
                  date = DateFormat('EEEE', context.l10n.localeName)
                      .format(DateTime(2026, 10, 7));
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(dir, TextDirection.ltr);
    expect(date, 'Wednesday');

    await container.read(localeProvider.notifier).setLocale(const Locale('he'));
    await tester.pumpAndSettle();
    expect(dir, TextDirection.rtl);
    expect(date, 'יום רביעי');
    expect(Intl.defaultLocale, 'he');

    await container.read(localeProvider.notifier).setLocale(const Locale('en'));
    await tester.pumpAndSettle();
    expect(dir, TextDirection.ltr);
    expect(date, 'Wednesday');
  });
}
```

(2026-10-07 is a Wednesday.)

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/l10n/app_locale_wiring_test.dart`
Expected: initially PASS or FAIL depending on helper compile; the purpose is to pin the locale/RTL/date behavior the real app must replicate. If it fails on `Intl.defaultLocale` being null in the builder, keep the assignment in `builder` as written and re-run; if Hebrew date symbols are not initialised (`LocaleDataException`), see Step 4's note.

- [ ] **Step 3: Wire `lib/app.dart`**

Add imports:

```dart
import 'package:buddbull/core/localization/locale_provider.dart';
import 'package:buddbull/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
```

In `build`, after `final router = ref.watch(routerProvider);` add `final locale = ref.watch(localeProvider);` and change the `MaterialApp.router(...)`:

```dart
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (device, _) => resolveAppLocale(device),
      builder: (context, child) {
        // Models without a BuildContext (e.g. GameModel.formattedDate) read this.
        Intl.defaultLocale = Localizations.localeOf(context).languageCode;
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
```

- [ ] **Step 4: Run all tests**

Run: `flutter analyze && flutter test`
Expected: wiring test PASSES; no new failures vs. the Task 0 baseline. (Note: `GlobalMaterialLocalizations` initialises Hebrew date symbols when its delegate loads, which happens before the child builds. If a `LocaleDataException` still appears, call `await initializeDateFormatting('he')` in `main()` before `runApp`, with `import 'package:intl/date_symbol_data_local.dart';`.)

- [ ] **Step 5: Commit**

```bash
git add lib/app.dart test/helpers/l10n_app.dart test/l10n/app_locale_wiring_test.dart
git commit -m "Wire locale, delegates and RTL into MaterialApp.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Bundle Heebo and add it as a font fallback

**Files:**
- Create: `assets/fonts/Heebo-Regular.ttf`, `Heebo-Medium.ttf`, `Heebo-SemiBold.ttf`, `Heebo-Bold.ttf`, `Heebo-ExtraBold.ttf`
- Modify: `pubspec.yaml`, `lib/core/constants/app_text_styles.dart`, `lib/core/theme/app_theme.dart`
- Test: `test/l10n/font_fallback_test.dart`

**Interfaces:**
- Produces: font family `Heebo` (weights 400/500/600/700/800) declared in `pubspec.yaml`; `AppTextStyles._fontFallback` used by all styles.

- [ ] **Step 1: Write the failing test**

`test/l10n/font_fallback_test.dart`:

```dart
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every AppTextStyles style falls back to Heebo for Hebrew glyphs', () {
    final styles = [
      AppTextStyles.displayLarge,
      AppTextStyles.titleLarge,
      AppTextStyles.bodyMedium,
      AppTextStyles.bodySmall,
      AppTextStyles.button,
      AppTextStyles.labelSmall,
    ];
    for (final s in styles) {
      expect(s.fontFamilyFallback, contains('Heebo'));
    }
  });
}
```

(If any style name above doesn't exist in `app_text_styles.dart`, replace it with an existing one — read the file first; the test must cover at least five distinct styles.)

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/l10n/font_fallback_test.dart`
Expected: FAIL (`fontFamilyFallback` is null).

- [ ] **Step 3: Cut and bundle the fonts**

Run from `frontend/`:

```bash
mkdir -p assets/fonts ../.tmp-heebo
curl -L -o ../.tmp-heebo/Heebo-VF.ttf "https://github.com/google/fonts/raw/main/ofl/heebo/Heebo%5Bwght%5D.ttf"
for w in 400:Regular 500:Medium 600:SemiBold 700:Bold 800:ExtraBold; do
  python -m fontTools varLib.instancer ../.tmp-heebo/Heebo-VF.ttf wght=${w%%:*} -o assets/fonts/Heebo-${w##*:}.ttf
done
rm -rf ../.tmp-heebo
ls -la assets/fonts
```

Expected: five `.ttf` files. (Heebo is licensed under the SIL Open Font License; add `assets/fonts/OFL.txt` with the licence text from the Google Fonts repo if the project ships a licences page.)

In `pubspec.yaml`, under the existing `flutter:` section, add after `assets:`:

```yaml
  fonts:
    - family: Heebo
      fonts:
        - asset: assets/fonts/Heebo-Regular.ttf
          weight: 400
        - asset: assets/fonts/Heebo-Medium.ttf
          weight: 500
        - asset: assets/fonts/Heebo-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Heebo-Bold.ttf
          weight: 700
        - asset: assets/fonts/Heebo-ExtraBold.ttf
          weight: 800
```

- [ ] **Step 4: Add the fallback**

In `lib/core/constants/app_text_styles.dart`, next to `static const String _fontFamily = 'Inter';` add:

```dart
  /// Inter has no Hebrew glyphs; Heebo covers them per-glyph.
  static const List<String> _fontFallback = ['Heebo'];
```

and add `fontFamilyFallback: _fontFallback,` to **every** `TextStyle(` in the file, directly under each `fontFamily: _fontFamily,`.

In `lib/core/theme/app_theme.dart`, change the theme to:

```dart
      fontFamily: GoogleFonts.inter().fontFamily,
      fontFamilyFallback: const ['Heebo'],
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme)
          .apply(fontFamilyFallback: const ['Heebo']),
```

- [ ] **Step 5: Run tests, then visual check**

Run: `flutter pub get && flutter analyze && flutter test`
Expected: font test PASSES, no new failures.
Manual check (record the result in your notes): `flutter run`, open any screen that shows a Hebrew string (e.g. type Hebrew in the search field) — glyphs render in Heebo, and bold/semibold Hebrew visibly differs from regular.

- [ ] **Step 6: Commit**

```bash
git add assets/fonts pubspec.yaml pubspec.lock lib/core/constants/app_text_styles.dart lib/core/theme/app_theme.dart test/l10n/font_fallback_test.dart
git commit -m "Bundle Heebo as Hebrew fallback font for all text styles.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Language switch in Profile

**Files:**
- Create: `lib/features/profile/presentation/widgets/language_sheet.dart`
- Modify: `lib/features/profile/presentation/screens/profile_screen.dart` (insert a tile after the Friends row that ends near line 175)
- Test: `test/features/profile/language_sheet_test.dart`

**Interfaces:**
- Consumes: `localeProvider` (Task 2); keys `languageTitle`, `languageDeviceDefault`, `languageEnglish`, `languageHebrew` (Task 1); `l10nMaterialApp`, `enL10n` (Task 3).
- Produces: `Future<void> showLanguageSheet(BuildContext context)`; `class LanguageTile extends ConsumerWidget` (a tile showing the current language that opens the sheet).

- [ ] **Step 1: Write the failing test**

`test/features/profile/language_sheet_test.dart`:

```dart
import 'package:buddbull/core/localization/locale_provider.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/profile/presentation/widgets/language_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_app.dart';

void main() {
  testWidgets('choosing עברית persists Hebrew; Device default clears it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: l10nMaterialApp(
          home: const Scaffold(body: LanguageTile()),
        ),
      ),
    );

    await tester.tap(find.text(enL10n.languageTitle));
    await tester.pumpAndSettle();
    expect(find.text(enL10n.languageDeviceDefault), findsOneWidget);
    expect(find.text('English'), findsWidgets);

    await tester.tap(find.text('עברית'));
    await tester.pumpAndSettle();
    expect(container.read(localeProvider), const Locale('he'));
    expect(prefs.getString(kAppLocalePrefKey), 'he');

    await tester.tap(find.text(enL10n.languageTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(enL10n.languageDeviceDefault));
    await tester.pumpAndSettle();
    expect(container.read(localeProvider), isNull);
    expect(prefs.containsKey(kAppLocalePrefKey), isFalse);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/profile/language_sheet_test.dart`
Expected: FAIL — `language_sheet.dart` not found.

- [ ] **Step 3: Implement the sheet and tile**

`lib/features/profile/presentation/widgets/language_sheet.dart`:

```dart
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/localization/locale_provider.dart';
import 'package:buddbull/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _currentLabel(BuildContext context, Locale? locale) {
  switch (locale?.languageCode) {
    case 'en':
      return context.l10n.languageEnglish;
    case 'he':
      return context.l10n.languageHebrew;
    default:
      return context.l10n.languageDeviceDefault;
  }
}

class LanguageTile extends ConsumerWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return ListTile(
      leading: const Icon(Icons.language_rounded, color: AppColors.primary),
      title: Text(
        context.l10n.languageTitle,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _currentLabel(context, locale),
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
      ),
      onTap: () => showLanguageSheet(context),
    );
  }
}

Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final current = ref.watch(localeProvider);
        final notifier = ref.read(localeProvider.notifier);

        Widget option(String label, Locale? value) {
          final selected = current?.languageCode == value?.languageCode;
          return ListTile(
            title: Text(label),
            trailing: selected
                ? const Icon(Icons.check_rounded, color: AppColors.primary)
                : null,
            onTap: () async {
              await notifier.setLocale(value);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              option(context.l10n.languageDeviceDefault, null),
              option(context.l10n.languageEnglish, const Locale('en')),
              option(context.l10n.languageHebrew, const Locale('he')),
            ],
          ),
        );
      },
    ),
  );
}
```

In `profile_screen.dart`, add `import 'package:buddbull/features/profile/presentation/widgets/language_sheet.dart';` and, in the sliver list directly after the Friends row's closing `SliverToBoxAdapter` (the block starting `// ── Friends row`), add:

```dart
            // ── Language ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
                child: Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.grey200),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const LanguageTile(),
                ),
              ),
            ),
```

- [ ] **Step 4: Run tests**

Run: `flutter analyze && flutter test`
Expected: new test PASSES; `test/screens/profile_screen_test.dart` still passes (if it fails because the profile screen now needs localization delegates in its pump, switch that test's `MaterialApp(.router)` to `l10nMaterialApp`/`l10nRouterApp` — it needs them from here on).

- [ ] **Step 5: Manual verification**

`flutter run`, Profile → Language → עברית: UI flips to RTL immediately, Material strings (e.g. date pickers) are Hebrew; kill and relaunch — Hebrew persists; choose Device default — reverts.

- [ ] **Step 6: Commit**

```bash
git add lib/features/profile/presentation/widgets/language_sheet.dart lib/features/profile/presentation/screens/profile_screen.dart test/features/profile/language_sheet_test.dart test/screens/profile_screen_test.dart
git commit -m "Add language picker to the Profile screen.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 6: ARB parity test and hardcoded-string guard

**Files:**
- Create: `test/l10n/arb_parity_test.dart`, `test/l10n/no_hardcoded_strings_test.dart`

**Interfaces:**
- Produces: `migratedPaths` list in `no_hardcoded_strings_test.dart` that Tasks 7–10 append to.

- [ ] **Step 1: Write the parity test**

`test/l10n/arb_parity_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _load(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map<String, dynamic>;

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

Set<String> _placeholders(String message) => RegExp(r'\{(\w+)')
    .allMatches(message)
    .map((m) => m.group(1)!)
    .where((p) => !const {'plural', 'select'}.contains(p))
    .toSet();

void main() {
  final en = _load('app_en.arb');
  final he = _load('app_he.arb');

  test('en and he define exactly the same message keys', () {
    final enKeys = _messageKeys(en)..remove('@@locale');
    final heKeys = _messageKeys(he)..remove('@@locale');
    expect(heKeys.difference(enKeys), isEmpty, reason: 'keys only in he');
    expect(enKeys.difference(heKeys), isEmpty, reason: 'keys only in en');
  });

  test('en and he use the same placeholders for every message', () {
    for (final key in _messageKeys(en).where((k) => !k.startsWith('@@'))) {
      final enPh = _placeholders(en[key] as String);
      final hePh = _placeholders((he[key] ?? '') as String);
      expect(hePh, enPh, reason: 'placeholder mismatch for "$key"');
    }
  });

  test('no Hebrew message is left empty or identical-by-accident placeholder text', () {
    for (final key in _messageKeys(he).where((k) => !k.startsWith('@@'))) {
      expect((he[key] as String).trim(), isNotEmpty, reason: key);
    }
  });
}
```

- [ ] **Step 2: Write the guard test**

`test/l10n/no_hardcoded_strings_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files/directories (relative to `frontend/`) whose user-visible text must
/// come from AppLocalizations. Migration tasks append to this list.
const List<String> migratedPaths = <String>[
  'lib/features/profile/presentation/widgets/language_sheet.dart',
];

final List<RegExp> _patterns = <RegExp>[
  // Text('Foo'), Text("Foo"), Text(const 'Foo')
  RegExp(r'''Text\(\s*(const\s+)?['"][^'"]*[A-Za-z֐-׿]'''),
  // labelText: 'Foo', hintText: 'Foo', title: 'Foo', content: Text('Foo') etc.
  RegExp(
    r'''\b(labelText|hintText|helperText|errorText|tooltip|semanticLabel|label|title|subtitle|content|message)\s*:\s*(const\s+)?['"][^'"$]*[A-Za-z֐-׿]''',
  ),
];

Iterable<File> _dartFiles(String path) {
  final type = FileSystemEntity.typeSync(path);
  if (type == FileSystemEntityType.file) return [File(path)];
  if (type == FileSystemEntityType.directory) {
    return Directory(path)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
  }
  return const [];
}

void main() {
  test('migrated files contain no hardcoded user-visible strings', () {
    final offenders = <String>[];
    for (final path in migratedPaths) {
      for (final file in _dartFiles(path)) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains('l10n-ignore')) continue;
          if (line.trimLeft().startsWith('//')) continue;
          if (_patterns.any((p) => p.hasMatch(line))) {
            offenders.add('${file.path}:${i + 1}: ${line.trim()}');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Hardcoded strings:\n${offenders.join('\n')}');
  });
}
```

- [ ] **Step 3: Run**

Run: `flutter test test/l10n`
Expected: all PASS (only `language_sheet.dart` is registered, and it has no literals; `languageHebrew` is read from ARB).

- [ ] **Step 4: Prove the guard bites (then revert)**

Temporarily add `Text('Oops')` to `language_sheet.dart`, run `flutter test test/l10n/no_hardcoded_strings_test.dart`, confirm it FAILS naming that line, then remove the line and re-run to confirm PASS.

- [ ] **Step 5: Commit**

```bash
git add test/l10n/arb_parity_test.dart test/l10n/no_hardcoded_strings_test.dart
git commit -m "Add ARB parity and hardcoded-string guard tests.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Stage 2 — Auth and onboarding

**Files (modify):**
- `lib/features/auth/presentation/screens/login_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart`, `lib/features/auth/presentation/widgets/password_strength_indicator.dart`
- `lib/features/onboarding/presentation/screens/onboarding_welcome_screen.dart`, `onboarding_location_screen.dart`, `onboarding_profile_screen.dart`, `lib/features/onboarding/presentation/widgets/onboarding_progress_header.dart`
- Shared widgets used by these screens if they contain literals: `lib/shared/widgets/bb_button.dart`, `bb_text_field.dart`, `error_view.dart`, `loading_overlay.dart`
- Validators/constants used by auth forms (find with `grep -rn "validator" lib/features/auth lib/features/onboarding`)
- `lib/core/constants/app_strings.dart` (remove entries whose last usage you migrated)
- Tests: `test/screens/login_screen_test.dart`, `register_screen_test.dart`, `introduction_screen_test.dart`, `test/helpers/auth_router.dart` if it builds the `MaterialApp`

**Interfaces:**
- Consumes: Migration Procedure; `l10nRouterApp`/`enL10n` (Task 3); `migratedPaths` (Task 6).
- Produces: ARB keys prefixed `auth…`, `onboarding…`, plus shared `common…` keys (`commonCancel` already exists). Shared widgets' strings use `common…`.

- [ ] **Step 1: Run the guard against the target files to get the worklist**

Append the paths above (except `app_strings.dart` and tests) to `migratedPaths`, then run `flutter test test/l10n/no_hardcoded_strings_test.dart`.
Expected: FAIL, listing every hardcoded `file:line` in scope — this is the worklist.

- [ ] **Step 2: Migrate** per the Migration Procedure steps 1–4 and 7. Worked example for `login_screen.dart` (`AppStrings.welcomeBack`, `loginSubtitle`, `emailLabel`, `emailHint`, `passwordLabel`, `passwordHint`, `forgotPassword`, `loginButton`, `noAccount`, `signUpLink`):

`app_en.arb` additions:

```json
  "authWelcomeBack": "Welcome back!",
  "authLoginSubtitle": "Sign in to your BuddBull account",
  "authEmailLabel": "Email address",
  "authEmailHint": "you@example.com",
  "authPasswordLabel": "Password",
  "authPasswordHint": "Your password",
  "authForgotPassword": "Forgot password?",
  "authLoginButton": "Sign In",
  "authNoAccount": "Don't have an account?",
  "authSignUpLink": "Sign up"
```

`app_he.arb` additions:

```json
  "authWelcomeBack": "ברוכים השבים!",
  "authLoginSubtitle": "התחברו לחשבון BuddBull שלכם",
  "authEmailLabel": "כתובת אימייל",
  "authEmailHint": "you@example.com",
  "authPasswordLabel": "סיסמה",
  "authPasswordHint": "הסיסמה שלך",
  "authForgotPassword": "שכחתם סיסמה?",
  "authLoginButton": "התחברות",
  "authNoAccount": "אין לכם חשבון?",
  "authSignUpLink": "הרשמה"
```

Code: `Text(AppStrings.welcomeBack)` → `Text(context.l10n.authWelcomeBack)`; same pattern for every string. Validators that return `String?` take an `AppLocalizations l10n` argument instead of using constants.

- [ ] **Step 3: Update tests.** In the three screen tests replace `child: MaterialApp.router(routerConfig: router)` with `child: l10nRouterApp(router)` and `find.text(AppStrings.loginButton)` with `find.text(enL10n.authLoginButton)` (same mapping for every migrated constant). Add one Hebrew test per screen, e.g. for login:

```dart
    testWidgets('renders Hebrew copy and RTL when locale is he', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: l10nRouterApp(authTestRouter(), locale: const Locale('he')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(heL10n.authLoginButton), findsOneWidget);
      final ctx = tester.element(find.text(heL10n.authLoginButton));
      expect(Directionality.of(ctx), TextDirection.rtl);
    });
```

- [ ] **Step 4: Verify and commit**

Run: `flutter gen-l10n && flutter analyze && flutter test`
Expected: guard, parity, and all screen tests PASS; no failures beyond baseline. Do the manual Hebrew walkthrough of login → register → forgot password → onboarding (Migration Procedure step 8).

```bash
git add lib/l10n/app_en.arb lib/l10n/app_he.arb lib/features/auth lib/features/onboarding lib/shared/widgets lib/core/constants/app_strings.dart test/screens test/helpers test/l10n/no_hardcoded_strings_test.dart
git commit -m "Localize auth and onboarding to English and Hebrew.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

(Before `git add` on directories, run `git status` and make sure no unrelated pre-existing modifications are inside the staged paths; if so, stage individual files instead.)

---

### Task 8: Stage 3 — Home, games, search (including date formatting)

**Files (modify):**
- `lib/features/home/home_scaffold.dart`, `presentation/home_screen.dart`, `presentation/widgets/collapsing_home_search.dart`, `presentation/widgets/global_add_fab.dart`
- `lib/features/games/presentation/screens/{calendar,create_game,edit_game,games,game_detail}_screen.dart`, `presentation/widgets/{game_card,game_filter_sheet,game_sport_wallpaper,player_slot_row}.dart`
- `lib/features/search/presentation/screens/global_search_screen.dart`, `presentation/widgets/search_transition.dart`
- Bottom-navigation labels in `home_scaffold.dart`; route titles in `lib/core/router/app_router.dart` if any are user-visible
- Date call sites with a context: `create_game_screen.dart:321`, `edit_game_screen.dart:205` (`DateFormat('EEE, d MMM y')`)
- Calendar locale: `calendar_screen.dart` (`TableCalendar(locale: context.l10n.localeName, …)`)
- Tests: `test/screens/home_screen_test.dart`, `main_layout_test.dart`, `test/features/home/collapsing_home_search_test.dart`, `test/features/rating/game_detail_rate_button_test.dart`

**Interfaces:**
- Consumes: Migration Procedure; Task 3 helpers; Task 6 guard.
- Produces: ARB keys prefixed `home…`, `games…`, `search…`, `nav…`. Date text at context-aware call sites uses `DateFormat('EEE, d MMM y', context.l10n.localeName)`. Model getters `GameModel.formattedDate/formattedTime` keep using `Intl.defaultLocale` (set in `app.dart`) — do not add a context to the model.

- [ ] **Step 1: Worklist.** Append the paths above to `migratedPaths`; run `flutter test test/l10n/no_hardcoded_strings_test.dart`; expected FAIL listing the work.

- [ ] **Step 2: Write the failing date test.** `test/features/games/date_locale_test.dart`:

```dart
import 'package:buddbull/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../../helpers/l10n_app.dart';

void main() {
  testWidgets('context-aware date formatting follows the active locale', (tester) async {
    String? out;
    Future<void> pump(Locale l) async {
      await tester.pumpWidget(
        l10nMaterialApp(
          locale: l,
          home: Builder(builder: (context) {
            out = DateFormat('EEE, d MMM y', context.l10n.localeName)
                .format(DateTime(2026, 10, 7));
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pump(const Locale('en'));
    expect(out, 'Wed, 7 Oct 2026');
    await pump(const Locale('he'));
    expect(out, contains('אוק'));
  });
}
```

Run: `flutter test test/features/games/date_locale_test.dart` — expected PASS (this pins the pattern the call sites must use).

- [ ] **Step 3: Migrate** per Migration Procedure steps 1–4, 7. Additionally: convert the two `DateFormat(...)` call sites above to pass `context.l10n.localeName`; set `TableCalendar`'s `locale`; make game status/skill-level display strings (enum → label) go through a `String label(AppLocalizations l10n)` method or an extension in the presentation layer, not the model. Count strings use plurals, e.g.:

```json
"gamesPlayersCount": "{count, plural, =0{No players} =1{1 player} other{{count} players}}",
"@gamesPlayersCount": { "placeholders": { "count": { "type": "int" } } }
```

Hebrew: `"gamesPlayersCount": "{count, plural, =0{אין שחקנים} =1{שחקן אחד} =2{שני שחקנים} other{{count} שחקנים}}"`.

- [ ] **Step 4: Update tests** per Migration Procedure step 5 for the four test files listed.

- [ ] **Step 5: Verify and commit**

Run: `flutter gen-l10n && flutter analyze && flutter test`. Manual Hebrew walkthrough: home → games list → game detail (map area, player rows) → create game (date picker is Hebrew) → calendar → search.

```bash
git add lib/l10n/app_en.arb lib/l10n/app_he.arb lib/features/home lib/features/games lib/features/search lib/core/router/app_router.dart test/screens test/features test/l10n/no_hardcoded_strings_test.dart
git commit -m "Localize home, games and search; make date formatting locale-aware.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

(Again check `git status` first: `lib/features/games/data/models/game_model.dart` has unrelated uncommitted changes and is deliberately **not** in the staged paths.)

---

### Task 9: Stage 4a — Chat and notifications

**Files (modify):**
- `lib/features/chat/presentation/screens/{chat_list,chat}_screen.dart`, `presentation/widgets/{chat_tile,message_bubble,pinned_message_banner}.dart`
- `lib/features/notifications/presentation/screens/notifications_screen.dart`
- Tests: `test/features/notifications/notification_live_test.dart`, `notification_smart_test.dart` (update only if they assert on migrated text)

**Interfaces:** Consumes Migration Procedure, Task 3 helpers, Task 6 guard. Produces keys `chat…`, `notifications…`. Notification *titles/bodies that come from the backend* are shown as received.

- [ ] **Step 1: Worklist** — append the paths to `migratedPaths`; run the guard; expected FAIL with the list.
- [ ] **Step 2: Migrate** per the Migration Procedure. Time stamps in chat (`DateFormat('HH:mm')`, relative "Yesterday"/"Today" text) must use the active locale / ARB keys.
- [ ] **Step 3: Update tests** per Migration Procedure step 5.
- [ ] **Step 4: Verify** — `flutter gen-l10n && flutter analyze && flutter test`; manual Hebrew walkthrough: chat list → open chat (own vs other bubbles sit on the correct sides in RTL, mixed Hebrew/English message text renders correctly) → notifications.
- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_he.arb lib/features/chat lib/features/notifications test/features test/l10n/no_hardcoded_strings_test.dart
git commit -m "Localize chat and notifications.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Stage 4b — Profile, performance, rating, reports, shared, settings

**Files (modify):**
- `lib/features/profile/presentation/screens/{edit_profile,friends_list,profile}_screen.dart` and every widget in `lib/features/profile/presentation/widgets/` (leave `language_sheet.dart` as is)
- `lib/features/performance/presentation/screens/{create_log,performance}_screen.dart`, `presentation/widgets/{activity_heatmap,log_card,progress_chart,streak_banner}.dart`, `lib/features/performance/data/models/performance_model.dart` (the `DateFormat('EEE, d MMM y')` at line ~42 stays model-level, relying on `Intl.defaultLocale`)
- `lib/features/rating/presentation/widgets/{rate_player_sheet,rating_stars}.dart`
- `lib/features/reports/presentation/widgets/report_flow.dart`
- `lib/shared/widgets/*.dart`, `lib/screens/main/settings_screen.dart`
- Remaining `AppStrings` constants → delete unused ones (keep `appName`)
- Tests: `test/screens/profile_screen_test.dart`, `test/features/rating/*`

**Interfaces:** Consumes Migration Procedure, Task 3 helpers, Task 6 guard. Produces keys `profile…`, `performance…`, `rating…`, `reports…`, `settings…`.

- [ ] **Step 1: Write the failing plural test** (Review Focus 5). `test/l10n/plurals_test.dart`:

```dart
import 'package:buddbull/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('friend-count text reads correctly in English and Hebrew', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final he = lookupAppLocalizations(const Locale('he'));

    expect(en.profileMutualConnections(1), '1 mutual connection');
    expect(en.profileMutualConnections(3), '3 mutual connections');

    expect(he.profileMutualConnections(0), isNot(contains('0 ')));
    expect(he.profileMutualConnections(1), 'חבר משותף אחד');
    expect(he.profileMutualConnections(2), 'שני חברים משותפים');
    expect(he.profileMutualConnections(7), '7 חברים משותפים');
  });
}
```

Run: `flutter test test/l10n/plurals_test.dart` — expected FAIL (`profileMutualConnections` undefined).

- [ ] **Step 2: Add the key** (replacing the inline ternary in `profile_screen.dart` near line 160):

`app_en.arb`:

```json
  "profileMutualConnections": "{count, plural, =0{No mutual connections} =1{1 mutual connection} other{{count} mutual connections}}",
  "@profileMutualConnections": { "placeholders": { "count": { "type": "int" } } }
```

`app_he.arb`:

```json
  "profileMutualConnections": "{count, plural, =0{אין חברים משותפים} =1{חבר משותף אחד} =2{שני חברים משותפים} other{{count} חברים משותפים}}"
```

Use: `Text(context.l10n.profileMutualConnections(user.friendsCount))`. Run `flutter gen-l10n && flutter test test/l10n/plurals_test.dart` — expected PASS.

- [ ] **Step 3: Worklist and migrate.** Append all paths above (except `performance_model.dart`, which has no widget text) to `migratedPaths`; run the guard; migrate per the Migration Procedure. Charts: axis labels/legends via ARB; numeric values stay LTR. Autocomplete fields (`city_autocomplete_field.dart`, `neighborhood_autocomplete_field.dart`) show Google-provided text as received; only their hints/labels migrate.

- [ ] **Step 4: Clean up `AppStrings`.** Run `grep -rn "AppStrings\." lib test`; delete every constant with no remaining usages (and the file's "future i18n" doc comment), keeping `appName`. Run `flutter analyze` — no unused/undefined references.

- [ ] **Step 5: Update tests** per Migration Procedure step 5, then run `flutter gen-l10n && flutter analyze && flutter test`. Manual Hebrew walkthrough: profile → edit profile (city/neighborhood autocomplete with Hebrew input) → friends → performance (chart, heatmap, create log) → rate a player → report flow → settings.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_he.arb lib/features/profile lib/features/performance lib/features/rating lib/features/reports lib/shared lib/screens lib/core/constants/app_strings.dart test/screens test/features test/l10n
git commit -m "Localize profile, performance, rating, reports and shared widgets.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 11: Stage 5 — RTL audit and final verification

**Files (modify):** every file with directional code outside `lib/features/admin/**` — find with:

```bash
grep -rnE "EdgeInsets\.only\(|EdgeInsets\.fromLTRB|Alignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)|Positioned\(|TextAlign\.(left|right)|BorderRadius\.only\(|Radius\.circular.*(topLeft|topRight)" lib --include=*.dart | grep -v "features/admin"
```

- Test: `test/l10n/rtl_layout_test.dart`, `test/l10n/directional_icons_test.dart`

**Interfaces:** Consumes everything above. Produces no new API.

- [ ] **Step 1: Write the failing icon test.** `test/l10n/directional_icons_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('directional icons used in the app mirror in RTL', () {
    for (final icon in [
      Icons.chevron_right_rounded,
      Icons.chevron_left_rounded,
      Icons.arrow_back_rounded,
      Icons.arrow_forward_rounded,
      Icons.arrow_back_ios_new_rounded,
      Icons.send_rounded,
    ]) {
      expect(icon.matchTextDirection, isTrue, reason: '$icon should mirror');
    }
  });
}
```

Run it. For any icon where it fails (the framework is the source of truth), find its usages (`grep -rn "<icon name>" lib`) and wrap them: `Transform.flip(flipX: Directionality.of(context) == TextDirection.rtl, child: Icon(...))`, then remove that icon from the test list with a comment explaining it is handled manually. Re-run until green.

- [ ] **Step 2: Convert directional code** using this mapping, file by file from the grep above (symmetric values like `EdgeInsets.only(top: 8, bottom: 8)` or `fromLTRB(16, 12, 16, 0)` where left==right need no change):

| Before | After |
|--------|-------|
| `EdgeInsets.only(left: a, right: b, top: t, bottom: m)` | `EdgeInsetsDirectional.only(start: a, end: b, top: t, bottom: m)` |
| `EdgeInsets.fromLTRB(l, t, r, b)` with `l != r` | `EdgeInsetsDirectional.fromSTEB(l, t, r, b)` |
| `Alignment.centerLeft` / `centerRight` | `AlignmentDirectional.centerStart` / `centerEnd` |
| `Alignment.topLeft` / `topRight` / `bottomLeft` / `bottomRight` | `AlignmentDirectional.topStart` / `topEnd` / `bottomStart` / `bottomEnd` |
| `Positioned(left: x, …)` / `right: x` | `PositionedDirectional(start: x, …)` / `end: x` |
| `TextAlign.left` / `TextAlign.right` | `TextAlign.start` / `TextAlign.end` |
| `BorderRadius.only(topLeft:, topRight:, …)` (asymmetric) | `BorderRadiusDirectional.only(topStart:, topEnd:, …)` |
| `Border(left: …)` / `Border(right: …)` | `BorderDirectional(start: …)` / `BorderDirectional(end: …)` |

Painted-by-coordinates widgets (`pitch_pattern_painter.dart`, charts, heatmap) draw geometry, not text — leave them LTR unless they place labels; if they do, mirror positions with `Directionality.of(context)`.

- [ ] **Step 3: Write the RTL layout tests.** `test/l10n/rtl_layout_test.dart` — reuse the login/register pumping from `test/screens/*_screen_test.dart`:

```dart
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/auth_router.dart';
import '../helpers/l10n_app.dart';
import '../helpers/test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await initTestFirebaseAndBinding();
  });

  testWidgets('auth screens do not overflow in Hebrew at 320px and 1.2x text',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.2)),
          child: l10nRouterApp(authTestRouter(), locale: const Locale('he')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(heL10n.authLoginButton), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');

    final ctx = tester.element(find.text(heL10n.authLoginButton));
    expect(Directionality.of(ctx), TextDirection.rtl);
  });
}
```

Add equivalent overflow checks for the register screen (navigate with the router as the existing `register_screen_test.dart` does) and for `GameCard`/`MessageBubble` with a long Hebrew string (≥ 80 chars, no spaces in one word of 30 chars) in a 320 px-wide `l10nMaterialApp` — each asserting `tester.takeException()` is null. If a widget overflows, fix it (wrap in `Flexible`/`Expanded`, `maxLines` + `overflow: TextOverflow.ellipsis`) and keep the test.

- [ ] **Step 4: Full verification**

Run: `flutter gen-l10n && flutter analyze && flutter test`
Expected: everything green, no failures beyond the Task 0 baseline. Re-run the directional grep from the Files section; every remaining hit must be symmetric or a deliberate exception.

Manual Hebrew pass on an emulator, screen by screen (auth, onboarding, home, games list/detail/create/calendar, search, chat, notifications, profile/edit/friends, performance, rate, report, settings): text Hebrew, layout mirrored, back/forward arrows point the right way, nothing clipped or overflowing, mixed Hebrew/English names display sensibly. Then switch to English and confirm nothing regressed. Report precisely what was and was not checked, including that admin screens remain English by design.

- [ ] **Step 5: Commit**

```bash
git add lib test
git commit -m "RTL audit: directional-aware layout and Hebrew overflow tests.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

(Before `git add lib test`, run `git status`; unstage or avoid the unrelated pre-existing modifications (`socket_service.dart`, `game_model.dart`) unless this task legitimately touched them — if it did, say so in the commit body.)

---

## Self-Review Notes

- **Spec coverage:** §1 infrastructure → Tasks 1–3; §2 strings → Tasks 7–10 (+ guard Task 6); §3 RTL → Task 11 (+ per-screen walkthroughs); §4 typography/formats → Task 4 (deviation documented), Task 3 + 8 (dates, calendar); §5 language switch → Task 5; §6 testing → Tasks 2, 3, 5, 6, 10, 11; staged delivery → Tasks 1–5 (stage 1), 7 (2), 8 (3), 9–10 (4), 11 (5).
- **Type consistency:** `localeProvider`/`LocaleNotifier.setLocale(Locale?)`/`resolveAppLocale(Locale?)`/`kAppLocalePrefKey` are defined in Task 2 and used identically in Tasks 3, 5; `enL10n`/`heL10n`/`l10nMaterialApp`/`l10nRouterApp` from Task 3 are used in Tasks 5, 7, 8, 11; `LanguageTile`/`showLanguageSheet` from Task 5.
- **Known limitation:** Tasks 7–10 are procedure-driven because the exact string inventory (≈300 literals) is derived from the code while migrating; the guard test enforces completeness and the parity test enforces Hebrew coverage.
