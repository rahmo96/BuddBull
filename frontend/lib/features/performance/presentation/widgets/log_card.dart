import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/date_format_utils.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
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
    final l10n = context.l10n;
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
                              _sportDisplayName(context, log.sport),
                              style: AppTextStyles.titleSmall,
                            ),
                            Text(
                              AppDateFormat.mediumDate(context, log.loggedAt),
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (log.outcome != null)
                        _OutcomeBadge(
                          outcome: log.outcome!,
                          label: _outcomeBadgeLabel(context, log.outcome!),
                        ),
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
                        label: _logTypeLabel(context, log.logType),
                      ),
                      if (log.durationMinutes != null)
                        _MetaChip(
                          icon: Icons.timer_outlined,
                          label: l10n.activityDurationMinutes(
                              log.durationMinutes!),
                        ),
                      if (log.selfRating != null)
                        _MetaChip(
                          icon: Icons.star_rounded,
                          label: '${log.selfRating}/5',
                        ),
                      if (log.mood != null)
                        _MetaChip(
                          icon: Icons.mood_rounded,
                          label: _moodLabel(context, log.mood!),
                        ),
                      if (log.streakAtLog > 0)
                        _MetaChip(
                          icon: Icons
                              .local_fire_department_rounded,
                          label: l10n.streakDaysSuffix(log.streakAtLog),
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
                            .withValues(alpha: 0.5),
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
                            l10n.newPersonalBestsCount(
                                log.newPersonalBests.length),
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
}

String _sportDisplayName(BuildContext context, String sport) {
  final l10n = context.l10n;
  final key = sport[0].toUpperCase() + sport.substring(1).toLowerCase();
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

String _logTypeLabel(BuildContext context, String type) {
  final l10n = context.l10n;
  return switch (type) {
    'match' => l10n.logTypeMatch,
    'training' => l10n.logTypeTraining,
    'fitness' => l10n.logTypeFitness,
    _ => type,
  };
}

String _outcomeBadgeLabel(BuildContext context, String outcome) {
  final l10n = context.l10n;
  return switch (outcome) {
    'win' => l10n.outcomeWinBadge,
    'loss' => l10n.outcomeLossBadge,
    'draw' => l10n.outcomeDrawBadge,
    _ => outcome,
  };
}

String _moodLabel(BuildContext context, String mood) {
  final l10n = context.l10n;
  return switch (mood) {
    'excellent' => l10n.moodExcellent,
    'good' => l10n.moodGood,
    'neutral' => l10n.moodNeutral,
    'bad' => l10n.moodBad,
    'terrible' => l10n.moodTerrible,
    _ => mood,
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
  const _OutcomeBadge({required this.outcome, required this.label});
  final String outcome;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (outcome) {
      'win' => AppColors.success,
      'loss' => AppColors.error,
      'draw' => AppColors.warning,
      _ => AppColors.grey500,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
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
