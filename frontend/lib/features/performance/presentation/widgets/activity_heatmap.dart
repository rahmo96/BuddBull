import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/features/performance/data/models/performance_model.dart';
import 'package:flutter/material.dart';

/// GitHub-style activity heatmap showing the last 16 weeks of activity.
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({
    super.key,
    required this.entries,
  });

  final List<HeatmapEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Build a map of date → count for O(1) lookup
    final dateMap = <String, int>{};
    for (final e in entries) {
      final key =
          '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      dateMap[key] = e.count;
    }

    final maxCount = entries.isEmpty
        ? 1
        : entries.map((e) => e.count).fold(0, (a, b) => a > b ? a : b);

    final today = DateTime.now();
    // Show 16 weeks back, aligned to Monday
    final startOffset = today.weekday - 1; // Mon = 0
    final start = today.subtract(Duration(days: startOffset + 7 * 15));

    // Build weeks
    const weeks = 16;
    final weekColumns = <List<DateTime>>[];
    for (int w = 0; w < weeks; w++) {
      final days = <DateTime>[];
      for (int d = 0; d < 7; d++) {
        days.add(start.add(Duration(days: w * 7 + d)));
      }
      weekColumns.add(days);
    }

    const cellSize = 12.0;
    const gap = 2.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.activity, style: AppTextStyles.titleSmall),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Day labels ──────────────────────────────────
              Row(
                children: [
                  const SizedBox(width: 20),
                  ...weekColumns.map(
                    (week) => SizedBox(
                      width: cellSize + gap,
                      child: Text(
                        _monthLabel(context, week, weekColumns.indexOf(week)),
                        style: AppTextStyles.labelSmall
                            .copyWith(fontSize: 9),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // ── Grid ────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day-of-week labels
                  Column(
                    children: [
                      const SizedBox(height: cellSize + gap),
                      const SizedBox(height: cellSize + gap),
                      _DayLabel(l10n.dayWed),
                      const SizedBox(height: cellSize + gap),
                      _DayLabel(l10n.dayFri),
                      const SizedBox(height: cellSize + gap),
                      const SizedBox(height: cellSize + gap),
                    ],
                  ),
                  const SizedBox(width: 4),
                  // Cells
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: weekColumns.map((week) {
                      return Column(
                        children: week.map((day) {
                          final key =
                              '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                          final count = dateMap[key] ?? 0;
                          final isToday = isSameDay(day, today);
                          final isFuture = day.isAfter(today);

                          return Tooltip(
                            message: isFuture
                                ? ''
                                : count == 0
                                    ? l10n.heatmapNoActivity
                                    : l10n.heatmapSessionCount(count),
                            child: Container(
                              width: cellSize,
                              height: cellSize,
                              margin: const EdgeInsets.all(gap / 2),
                              decoration: BoxDecoration(
                                color: isFuture
                                    ? Colors.transparent
                                    : _cellColor(
                                        count, maxCount),
                                borderRadius:
                                    BorderRadius.circular(2),
                                border: isToday
                                    ? Border.all(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // ── Legend ────────────────────────────────────────────
        Row(
          children: [
            Text(l10n.less, style: AppTextStyles.labelSmall),
            const SizedBox(width: 4),
            ...List.generate(
              5,
              (i) => Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: _cellColor(i, 4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(l10n.more, style: AppTextStyles.labelSmall),
          ],
        ),
      ],
    );
  }

  Color _cellColor(int count, int maxCount) {
    if (count == 0) return AppColors.grey100;
    final t = (count / maxCount).clamp(0.0, 1.0);
    return Color.lerp(
      AppColors.primary.withValues(alpha: 0.25),
      AppColors.primary,
      t,
    )!;
  }

  String _monthLabel(BuildContext context, List<DateTime> week, int weekIndex) {
    if (weekIndex == 0 || week.first.day <= 7) {
      return _monthAbbr(context, week.first.month);
    }
    return '';
  }

  String _monthAbbr(BuildContext context, int month) {
    final l10n = context.l10n;
    return switch (month) {
      1 => l10n.monthJan,
      2 => l10n.monthFeb,
      3 => l10n.monthMar,
      4 => l10n.monthApr,
      5 => l10n.monthMay,
      6 => l10n.monthJun,
      7 => l10n.monthJul,
      8 => l10n.monthAug,
      9 => l10n.monthSep,
      10 => l10n.monthOct,
      11 => l10n.monthNov,
      12 => l10n.monthDec,
      _ => '',
    };
  }
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _DayLabel extends StatelessWidget {
  const _DayLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
      ),
    );
  }
}
