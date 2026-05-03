import 'package:flutter/material.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';

/// Interactive or static star rating widget.
class RatingStars extends StatelessWidget {
  final double rating;
  final int maxStars;
  final double size;
  final Color? activeColor;
  final bool interactive;
  final ValueChanged<int>? onChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.size = 24,
    this.activeColor,
    this.interactive = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? const Color(0xFFF59E0B); // amber

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (i) {
        final starValue = i + 1;
        IconData icon;
        if (starValue <= rating) {
          icon = Icons.star;
        } else if (starValue - 0.5 <= rating) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }

        final star = Icon(icon, color: color, size: size);

        if (interactive) {
          return GestureDetector(
            onTap: () => onChanged?.call(starValue),
            child: star,
          );
        }
        return star;
      }),
    );
  }
}

/// Labeled score row: "Reliability" [★★★★☆] "4.0"
class ScoreRow extends StatelessWidget {
  final String label;
  final double score;
  final double starSize;

  const ScoreRow({super.key, required this.label, required this.score, this.starSize = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ),
        RatingStars(rating: score, size: starSize),
        const SizedBox(width: 6),
        Text(
          score.toStringAsFixed(1),
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
