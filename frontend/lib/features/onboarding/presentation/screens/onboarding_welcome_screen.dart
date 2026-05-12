import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_strings.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/constants/skill_level_labels.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/onboarding/data/onboarding_mock_data.dart';
import 'package:buddbull/features/onboarding/onboarding_completion.dart';
import 'package:buddbull/features/onboarding/presentation/widgets/onboarding_progress_header.dart';
import 'package:buddbull/features/onboarding/providers/onboarding_draft_provider.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// First onboarding step: welcome copy + favourite sports chips.
class OnboardingWelcomeScreen extends ConsumerWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final width = MediaQuery.sizeOf(context).width;

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
            constraints: BoxConstraints(maxWidth: width > 600 ? 560 : double.infinity),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OnboardingProgressHeader(step: 1, totalSteps: 2),
                  Text(
                    AppStrings.onboardingWelcomeMessage,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    AppStrings.onboardingSportsSection,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final sport in OnboardingMockData.sports)
                        _SportChoiceChip(
                          key: ValueKey<String>('onboarding_sport_${sport.id}'),
                          option: sport,
                          selected:
                              draft.sportSkillLevels.containsKey(sport.id),
                          onTap: () => ref
                              .read(onboardingDraftProvider.notifier)
                              .toggleSport(sport.id),
                        ),
                    ],
                  ),
                  if (draft.sportSkillLevels.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      AppStrings.onboardingSkillPerSport,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...draft.sportSkillLevels.keys.map((sportId) {
                      final sport = OnboardingMockData.sportById(sportId);
                      if (sport == null) return const SizedBox.shrink();
                      final level = draft.sportSkillLevels[sportId]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SportSkillPanel(
                          key: ValueKey<String>('onboarding_skill_$sportId'),
                          option: sport,
                          skillLevel: level,
                          onSkillSelected: (s) => ref
                              .read(onboardingDraftProvider.notifier)
                              .setSportSkill(sportId, s),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: BbButton(
                          label: AppStrings.onboardingSkip,
                          onPressed: () async {
                            await completePostSignupOnboarding(ref);
                            if (context.mounted) {
                              context.go(Routes.home);
                            }
                          },
                          variant: BbButtonVariant.outlined,
                          height: 50,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: BbButton(
                          label: AppStrings.onboardingNext,
                          onPressed: () =>
                              context.push(Routes.onboardingProfile),
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

class _SportSkillPanel extends StatelessWidget {
  const _SportSkillPanel({
    super.key,
    required this.option,
    required this.skillLevel,
    required this.onSkillSelected,
  });

  final OnboardingSportOption option;
  final String skillLevel;
  final ValueChanged<String> onSkillSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(option.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                option.label,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final level in OnboardingMockData.skillLevelsOrdered)
                ChoiceChip(
                  label: Text(skillLevelDisplayName(level)),
                  selected: skillLevel == level,
                  onSelected: (_) => onSkillSelected(level),
                  selectedColor: option.accent.withValues(alpha: 0.2),
                  labelStyle: AppTextStyles.labelMedium.copyWith(
                    color: skillLevel == level
                        ? option.accent
                        : AppColors.textPrimary,
                    fontWeight:
                        skillLevel == level ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: skillLevel == level
                        ? option.accent
                        : AppColors.grey300,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SportChoiceChip extends StatelessWidget {
  const _SportChoiceChip({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final OnboardingSportOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? option.accent : AppColors.grey300;
    final bg =
        selected ? option.accent.withValues(alpha: 0.12) : AppColors.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: option.accent.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(option.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                option.label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: selected ? option.accent : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_rounded, size: 18, color: option.accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
