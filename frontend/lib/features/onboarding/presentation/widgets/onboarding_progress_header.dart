import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Thin progress strip for the two-step post-signup flow.
class OnboardingProgressHeader extends StatelessWidget {
  const OnboardingProgressHeader({
    super.key,
    required this.step,
    required this.totalSteps,
  });

  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.onboardingStepOf(step, totalSteps),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: step / totalSteps,
              minHeight: 6,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(
                t.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
