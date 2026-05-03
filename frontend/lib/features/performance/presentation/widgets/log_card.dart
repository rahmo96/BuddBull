import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/performance/data/models/performance_model.dart';
import 'package:flutter/material.dart';

/// A card displaying a single performance log entry.
class LogCard extends StatelessWidget {
  const LogCard({
    super.key,
    required this.log,
    this.onTap,
    this.onDelete,
  });

  final PerformanceLogModel log;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Coloured top strip ──────────────────────────
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: _colorForLog(log),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ───────────────────────────────
                  Row(
                    children: [
                      _SportEmoji(sport: log.sport),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.sport,
                              style: AppTextStyles.titleSmall,
                            ),
                            Text(
                              log.formattedDate,
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (log.outcome != null)
                        _OutcomeBadge(outcome: log.outcome!),
                      if (onDelete != null) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.grey500,
                          ),
                          onPressed: onDelete,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  ),

                  // ── Meta row ─────────────────────────────
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _MetaChip(
                        icon: Icons.category_outlined,
                        label: _logTypeLabel(log.logType),
                      ),
                      if (log.durationMinutes != null)
                        _MetaChip(
                          icon: Icons.timer_outlined,
                          label: '${log.durationMinutes}min',
                        ),
                      if (log.selfRating != null)
                        _MetaChip(
                          icon: Icons.star_rounded,
                          label: '${log.selfRating}/10',
                        ),
                      if (log.mood != null)
                        _MetaChip(
                          icon: Icons.mood_rounded,
                          label: log.mood!,
                        ),
                      if (log.streakAtLog > 0)
                        _MetaChip(
                          icon: Icons
                              .local_fire_department_rounded,
                          label: '${log.streakAtLog}d',
                          color: AppColors.error,
                        ),
                    ],
                  ),

                  // ── Personal bests ────────────────────────
                  if (log.newPersonalBests.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight
                            .withOpacity(0.5),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏅',
                              style:
                                  TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            '${log.newPersonalBests.length} new personal best${log.newPersonalBests.length > 1 ? 's' : ''}!',
                            style: AppTextStyles.labelMedium
                                .copyWith(
                              color: AppColors.secondaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Notes ─────────────────────────────────
                  if (log.notes != null &&
                      log.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      log.notes!,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForLog(PerformanceLogModel log) {
    if (log.outcome == 'win') return AppColors.success;
    if (log.outcome == 'loss') return AppColors.error;
    if (log.logType == 'match') return AppColors.info;
    if (log.logType == 'training') return AppColors.primary;
    return AppColors.secondary;
  }

  String _logTypeLabel(String type) => switch (type) {
        'match' => 'Match',
        'training' => 'Training',
        'fitness' => 'Fitness',
        _ => type,
      };
}

class _SportEmoji extends StatelessWidget {
  const _SportEmoji({required this.sport});
  final String sport;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(_emoji(sport),
            style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  String _emoji(String s) => switch (s.toLowerCase()) {
        'football' || 'soccer' => '⚽',
        'basketball' => '🏀',
        'tennis' => '🎾',
        'running' => '🏃',
        'swimming' => '🏊',
        'cycling' => '🚴',
        _ => '🏅',
      };
}

class _OutcomeBadge extends StatelessWidget {
  const _OutcomeBadge({required this.outcome});
  final String outcome;

  @override
  Widget build(BuildContext context) {
    final (color, emoji) = switch (outcome) {
      'win' => (AppColors.success, '🏆 Win'),
      'loss' => (AppColors.error, '❌ Loss'),
      'draw' => (AppColors.warning, '🤝 Draw'),
      _ => (AppColors.grey500, outcome),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        emoji,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.color = AppColors.grey600,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: color),
        ),
      ],
    );
  }
}
