# BuddBull — Post-signup onboarding (introduction flow)

This document describes the **introduction screens shown immediately after account creation**, what was implemented in the Flutter app, and sensible **next stages** for product and engineering.

---

## User flow

1. **Registration** succeeds (Firebase user + MongoDB profile sync via `AuthNotifier.register`).
2. The app marks **onboarding pending** in `SharedPreferences` under the key [`bb_onboarding_pending`](../frontend/lib/features/onboarding/data/onboarding_prefs.dart).
3. `GoRouter` **redirects** any authenticated session with pending onboarding to **`/onboarding/welcome`** (see [`app_router.dart`](../frontend/lib/core/router/app_router.dart)).
4. **Step 1 — Welcome & interests**: headline, multi-select sport chips (mock catalogue), **Next** continues to profile step, **Skip** clears pending state and navigates **Home**.
5. **Step 2 — Profile setup**: optional **gallery upload** (`image_picker`) or tap a **preset “avatar” tile** (emoji on coloured squares — pure mock UI, no bundled raster assets required). **Get started** runs a mock submit then clears pending and opens **Home**; **Skip** does the same without requiring a photo.
6. While the user completes the steps, **Riverpod** holds a single [`OnboardingDraft`](../frontend/lib/features/onboarding/providers/onboarding_draft_provider.dart) (sport ids, optional file path, optional avatar id) so selections can be **submitted together** on the final action.

Logout clears `bb_onboarding_pending` so a half-finished flow does not trap the next sign-in incorrectly.

---

## What we implemented (summarised)

| Area | Details |
|------|--------|
| **Routing** | New routes `Routes.onboardingWelcome` and `Routes.onboardingProfile`; redirect merge with auth via `Listenable.merge` + [`onboardingRedirectListenProvider`](../frontend/lib/features/onboarding/providers/onboarding_redirect_listen.dart). |
| **Persistence gate** | [`sharedPreferencesProvider`](../frontend/lib/core/storage/shared_preferences_provider.dart) hydrated in [`main.dart`](../frontend/lib/main.dart); pending flag set in [`AuthNotifier.register`](../frontend/lib/features/auth/providers/auth_provider.dart). |
| **State** | [`onboardingDraftProvider`](../frontend/lib/features/onboarding/providers/onboarding_draft_provider.dart) for in-flow selections; [`mockSubmitOnboardingProfile`](../frontend/lib/features/onboarding/onboarding_completion.dart) logs/debug-prints aggregated payload until the API exists. |
| **Mock content** | [`OnboardingMockData`](../frontend/lib/features/onboarding/data/onboarding_mock_data.dart): sports labels/emojis/colours and emoji “avatars”. |
| **UI** | [`OnboardingWelcomeScreen`](../frontend/lib/features/onboarding/presentation/screens/onboarding_welcome_screen.dart), [`OnboardingProfileScreen`](../frontend/lib/features/onboarding/presentation/screens/onboarding_profile_screen.dart), shared [`OnboardingProgressHeader`](../frontend/lib/features/onboarding/presentation/widgets/onboarding_progress_header.dart). |
| **Strings** | Centralised under `AppStrings.onboarding*` in [`app_strings.dart`](../frontend/lib/core/constants/app_strings.dart). |

---

## Next stages (recommended)

1. **Backend contract** — Add PATCH (or dedicated onboarding) endpoints to persist preferred sports and avatar/profile image URL against the authenticated user document; mirror models with `profile_service` / `auth_repository`.
2. **Replace mocks** — Wire `mockSubmitOnboardingProfile` to real API calls with loading/error UX; handle upload via signed URL or multipart as your stack requires.
3. **Server-driven onboarding** — Store `profile_onboarding_completed` (or inferred from missing fields) so **login on a new device** still resumes or skips onboarding correctly instead of trusting only local prefs.
4. **Assets** — Optional swap emoji tiles for illustrator-made avatar PNGs/WebP kept under [`assets/`](../frontend/pubspec.yaml) with responsive density variants.
5. **Analytics** — Funnel events (signup → step1 → step2 → complete / skip) and drop-off checkpoints.
6. **Accessibility / i18n** — Semantic labels on chips and avatar grid; move strings into ARB/gen-l10n when you internationalise.

---

## Local development notes

- **Tests**: Widget coverage for the welcome screen lives in [`introduction_screen_test.dart`](../frontend/test/screens/introduction_screen_test.dart); the root [`widget_test.dart`](../frontend/test/widget_test.dart) smoke-tests onboarding without initializing Firebase (full-app widget tests still need Firebase test harness if preferred).
- **Web**: Custom photo preview uses `dart:io` `File`; the profile screen skips `Image.file` on web (`kIsWeb`) until a `Image.memory`/bytes pipeline is added if you ship Flutter web.
