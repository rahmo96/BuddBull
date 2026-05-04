import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/performance/data/models/performance_model.dart';

/// Bar chart showing sessions per week over the last 8 weeks.
class ProgressChart extends StatelessWidget {
  const ProgressChart({
    super.key,
    required this.sessions,
    this.title = 'Sessions per week',
  });

  final List<WeeklySession> sessions;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return _EmptyChart(title: title);
    }

    final maxY = sessions
        .map((s) => s.sessionCount.toDouble())
        .fold(0.0, (a, b) => a > b ? a : b)
        .clamp(4.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleSmall),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: maxY + 1,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY / 4).ceilToDouble(),
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.grey200,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: (maxY / 4).ceilToDouble(),
                    getTitlesWidget: (value, _) => Text(
                      value.toInt().toString(),
                      style: AppTextStyles.labelSmall,
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= sessions.length) {
                        return const SizedBox.shrink();
                      }
                      final label = sessions[i]
                          .weekLabel
                          .split(' ')
                          .first;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          label,
                          style: AppTextStyles.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(sessions.length, (i) {
                final s = sessions[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: s.sessionCount.toDouble(),
                      color: AppColors.primary,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY + 1,
                        color: AppColors.grey100,
                      ),
                    ),
                  ],
                );
              }),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.grey900,
                  getTooltipItem: (group, _, rod, __) =>
                      BarTooltipItem(
                    '${rod.toY.toInt()} sessions\n'
                    '${sessions[group.x].totalMinutes} min',
                    AppTextStyles.labelSmall.copyWith(
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Line chart for win/loss trend over sessions.
class WinRateChart extends StatelessWidget {
  const WinRateChart({
    super.key,
    required this.sessions,
  });

  final List<WeeklySession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const _EmptyChart(title: 'Win rate trend');
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      final rate = s.sessionCount > 0
          ? s.wins / s.sessionCount
          : 0.0;
      spots.add(FlSpot(i.toDouble(), rate));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Win rate trend', style: AppTextStyles.titleSmall),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 1,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.25,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.grey200,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 0.25,
                    getTitlesWidget: (v, _) => Text(
                      '${(v * 100).toInt()}%',
                      style: AppTextStyles.labelSmall,
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles:
                        SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles:
                        SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(
                    sideTitles:
                        SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppColors.success,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.success,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.success.withOpacity(0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.grey900,
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            '${(s.y * 100).toInt()}%',
                            AppTextStyles.labelSmall.copyWith(
                                color: Colors.white),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleSmall),
        const SizedBox(height: 16),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Log some sessions to see your progress',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}
