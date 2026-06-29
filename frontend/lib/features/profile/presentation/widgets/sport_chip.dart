import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/constants/skill_level_labels.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/features/auth/data/models/user_model.dart';
import 'package:flutter/material.dart';

/// A coloured chip showing a user's sport and skill level.
class SportChip extends StatelessWidget {
  const SportChip({super.key, required this.interest, this.onDelete});

  final SportInterest interest;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _colorForSport(interest.sport);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _emojiForSport(interest.sport),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _sportDisplayName(context, interest.sport),
                style: AppTextStyles.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                skillLevelDisplayName(context, interest.skillLevel),
                style: AppTextStyles.labelSmall.copyWith(color: color),
              ),
            ],
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.close_rounded, size: 16, color: color),
            ),
          ],
        ],
      ),
    );
  }

  Color _colorForSport(String sport) {
    return switch (sport.toLowerCase()) {
      'football' || 'soccer' => AppColors.footballBadge,
      'basketball' => AppColors.basketballBadge,
      'tennis' => AppColors.tennisBadge,
      'running' => AppColors.runningBadge,
      _ => AppColors.defaultBadge,
    };
  }

  String _emojiForSport(String sport) {
    return switch (sport.toLowerCase()) {
      'football' || 'soccer' => '⚽',
      'basketball' => '🏀',
      'tennis' => '🎾',
      'running' => '🏃',
      'swimming' => '🏊',
      'cycling' => '🚴',
      'volleyball' => '🏐',
      'cricket' => '🏏',
      _ => '🏅',
    };
  }
}

String _sportDisplayName(BuildContext context, String sport) {
  final l10n = context.l10n;
  final key = sport.isEmpty
      ? sport
      : sport[0].toUpperCase() + sport.substring(1).toLowerCase();
  return switch (key) {
    'Football' => l10n.sportFootball,
    'Basketball' => l10n.sportBasketball,
    'Tennis' => l10n.sportTennis,
    'Running' => l10n.sportRunning,
    'Swimming' => l10n.sportSwimming,
    'Cycling' => l10n.sportCycling,
    'Volleyball' => l10n.sportVolleyball,
    'Cricket' => l10n.sportCricket,
    _ => sport,
  };
}
