import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/onboarding/presentation/widgets/onboarding_progress_header.dart';
import 'package:buddbull/features/onboarding/providers/onboarding_draft_provider.dart';
import 'package:buddbull/features/profile/presentation/widgets/city_autocomplete_field.dart';
import 'package:buddbull/features/profile/presentation/widgets/neighborhood_autocomplete_field.dart';
import 'package:buddbull/features/profile/presentation/widgets/travel_radius_slider.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Second onboarding step: where the user lives (required).
class OnboardingLocationScreen extends ConsumerWidget {
  const OnboardingLocationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final draft = ref.watch(onboardingDraftProvider);
    final width = MediaQuery.sizeOf(context).width;
    final canContinue = draft.hasRequiredLocation;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width > 600 ? 560 : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OnboardingProgressHeader(step: 2, totalSteps: 3),
                  Text(
                    l10n.onboardingLocationTitle,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.onboardingLocationSubtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  CityAutocompleteField(
                    selectedCity: draft.city,
                    label: l10n.cityLabel,
                    hint: l10n.onboardingLocationCityHint,
                    onCitySelected: (city) => ref
                        .read(onboardingDraftProvider.notifier)
                        .setCity(city),
                  ),
                  const SizedBox(height: 16),
                  NeighborhoodAutocompleteField(
                    key: ValueKey(draft.city ?? ''),
                    selectedCity: draft.city,
                    selectedNeighborhood: draft.neighborhood,
                    label: l10n.neighborhoodLabel,
                    hint: l10n.onboardingLocationNeighborhoodHint,
                    onNeighborhoodSelected: (neighborhood) => ref
                        .read(onboardingDraftProvider.notifier)
                        .setNeighborhood(neighborhood),
                  ),
                  const SizedBox(height: 16),
                  TravelRadiusSlider(
                    value: draft.radiusKm,
                    onChanged: (v) => ref
                        .read(onboardingDraftProvider.notifier)
                        .setRadiusKm(v),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: BbButton(
                          label: l10n.onboardingBack,
                          onPressed: () => context.pop(),
                          variant: BbButtonVariant.outlined,
                          height: 50,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: BbButton(
                          label: l10n.onboardingNext,
                          onPressed: canContinue
                              ? () => context.push(Routes.onboardingProfile)
                              : null,
                          height: 50,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
