# Hebrew & RTL Support — Design

Date: 2026-10-07
Status: Draft, awaiting review

## Goal

Make the BuddBull Flutter app usable in Hebrew with correct right-to-left (RTL) layout, alongside the existing English UI.

## Decisions (agreed)

- **Language selection:** follow the device language by default (Hebrew device → Hebrew + RTL; any other → English). A manual switch in the Profile screen overrides the device language and is persisted.
- **Scope:** all user-facing screens (auth, onboarding, home, games, chat, profile, search, notifications, performance, rating, reports). **Out of scope:** admin screens (stay English), backend error messages, push notification text.
- **Mechanism:** Flutter's built-in `gen_l10n` with ARB files.

## Current state

- Flutter app, 116 Dart files (56 UI). Riverpod, go_router, `shared_preferences`, `intl` (dependency only).
- Text is mostly hardcoded in widgets (~170 `Text('…')` literals, ~145 label/hint/title literals); `AppStrings` holds 98 constants used by 18 files.
- `lib/l10n/` exists but is empty; no `l10n.yaml`; `MaterialApp.router` in `lib/app.dart` has no locale configuration.
- Font is Inter (`app_theme.dart`), which has no Hebrew glyphs.
- 34 directional usages in 23 files (`EdgeInsets.only(left/right)`, `Alignment.centerLeft/Right`, `Positioned`, `TextAlign.left/right`).

## Design

### 1. Infrastructure

- `pubspec.yaml`: add `flutter_localizations` (sdk: flutter); set `flutter: generate: true`.
- `l10n.yaml`: `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`, `nullable-getter: false`.
- `lib/l10n/app_en.arb` (template) and `lib/l10n/app_he.arb`.
- Extension `context.l10n` → `AppLocalizations.of(context)`.
- `localeProvider`: Riverpod `StateNotifier<Locale?>` backed by `shared_preferences` (key `app_locale`). `null` = follow device.
- `MaterialApp.router`: `locale` from provider, `localizationsDelegates` (`AppLocalizations.delegate` + Global Material/Widgets/Cupertino), `supportedLocales: [en, he]`, and a `localeResolutionCallback` that returns `he` only when the device language code is `he` (also accept legacy `iw`), otherwise `en`. Flutter flips `Directionality` for `he` automatically.

### 2. Strings

- Move `AppStrings` values and hardcoded literals in non-admin screens into ARB keys, named by feature (`authLoginTitle`, `gamesJoinButton`, …).
- Parameterized text uses ARB placeholders; counts use ICU plurals with Hebrew plural categories (one/two/other).
- Dynamic values returned by the backend (game titles, names, addresses) are displayed as-is.
- Validators and snackbars are localized where they originate in the UI layer. Messages returned by the API stay as received.
- `AppStrings.appName` stays a constant (brand name).

### 3. RTL correctness

- Replace directional code with directional-aware equivalents: `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, `TextAlign.start/end`.
- Review custom icons/chevrons and set `matchTextDirection` where an icon implies direction (back/forward arrows, send button in chat).
- Pay specific attention to: chat message bubbles, bottom navigation, game detail (map preview and player rows), `table_calendar`, charts (`fl_chart` axes stay LTR numerically), search bars.

### 4. Typography and formats

- `AppTheme` becomes locale-aware: Inter for `en`, Heebo (via `google_fonts`) for `he`.
- `DateFormat`/number formatting receive the active locale explicitly; `table_calendar` gets the locale.

### 5. Language switch UI

- New "Language" tile in `profile_screen.dart` opening a bottom sheet with: Device default / English / עברית. Selection updates `localeProvider` and applies immediately, no restart.

### 6. Testing

- Unit: `localeProvider` persistence and device fallback.
- Script/test: `app_en.arb` and `app_he.arb` have identical key sets and matching placeholders.
- Widget: key screens pumped with `Locale('he')` assert `TextDirection.rtl` and no overflow.
- Manual: Hebrew pass on an emulator for each stage.

## Delivery stages

1. Infrastructure, `localeProvider`, Profile language switch, Hebrew font.
2. Auth and onboarding.
3. Home, games, search.
4. Chat, notifications, profile, performance, rating, reports.
5. RTL audit of remaining directional code and polish.

Each stage leaves the app runnable; untranslated strings fall back to English until their stage lands (ARB keys are added per stage, so the key-parity test covers keys that exist).

## Risks / notes

- `google_fonts` fetches fonts at runtime unless bundled; Heebo should be bundled as an asset for offline reliability (decide in the plan).
- Mixed Hebrew/English text (names, addresses) relies on Unicode bidi; verify visually in chat and game lists.
- `flutter pub get` regenerates `pubspec.lock`, which already has uncommitted changes in the working tree.
