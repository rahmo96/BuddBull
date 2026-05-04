import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
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
                interest.sport,
                style: AppTextStyles.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                interest.skillLevel,
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
