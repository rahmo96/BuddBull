import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Gamified streak tracker with linear progress and warming-up state.
class StreakBanner extends StatelessWidget {
  const StreakBanner({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    this.weeklyGoal = 7,
  });

  final int currentStreak;
  final int longestStreak;
  final int weeklyGoal;

  @override
  Widget build(BuildContext context) {
    final isActive = currentStreak > 0;
    final isWarmingUp = !isActive;
    final progress = (currentStreak / weeklyGoal).clamp(0.0, 1.0);
    final goalLabel = weeklyGoal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isWarmingUp ? AppColors.metricStreakBg : null,
        gradient: isActive ? AppColors.brandGradient : null,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isWarmingUp)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          isWarmingUp ? 'Warming up' : 'Active streak',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isActive
                                ? Colors.white.withValues(alpha: 0.9)
                                : AppColors.metricStreakAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$currentStreak',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: isActive
                                ? Colors.white
                                : AppColors.textPrimary,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 6, bottom: 6),
                          child: Text(
                            currentStreak == 1 ? 'day' : 'days',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isActive
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Personal best',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.75)
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$longestStreak d',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: isWarmingUp ? 0.08 : progress,
              minHeight: 8,
              backgroundColor: isActive
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(
                isActive ? Colors.white : AppColors.metricStreakAccent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isWarmingUp
                ? 'Log a session today to start your streak'
                : '$currentStreak of $goalLabel-day goal · Keep it going!',
            style: AppTextStyles.bodySmall.copyWith(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.8)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
