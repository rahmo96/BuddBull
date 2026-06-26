import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/performance/data/models/performance_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
      return const _EmptyChart(title: 'Win rate trend', variant: _GhostVariant.line);
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
                    color: AppColors.success.withValues(alpha: 0.1),
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
  const _EmptyChart({required this.title, this.variant = _GhostVariant.bar});
  final String title;
  final _GhostVariant variant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleSmall),
        const SizedBox(height: 8),
        Text(
          'Your stats preview — log sessions to unlock',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: variant == _GhostVariant.bar ? 160 : 140,
          child: variant == _GhostVariant.bar
              ? const _GhostBarChart()
              : const _GhostLineChart(),
        ),
      ],
    );
  }
}

enum _GhostVariant { bar, line }

class _GhostBarChart extends StatelessWidget {
  const _GhostBarChart();

  @override
  Widget build(BuildContext context) {
    const heights = [0.45, 0.72, 0.55, 0.88, 0.62, 0.78, 0.5, 0.68];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final h in heights)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                height: 120 * h,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GhostLineChart extends StatelessWidget {
  const _GhostLineChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GhostLinePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _GhostLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = AppColors.success.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = AppColors.success.withValues(alpha: 0.22)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final points = [
      Offset(size.width * 0.05, size.height * 0.72),
      Offset(size.width * 0.22, size.height * 0.55),
      Offset(size.width * 0.4, size.height * 0.62),
      Offset(size.width * 0.58, size.height * 0.38),
      Offset(size.width * 0.76, size.height * 0.48),
      Offset(size.width * 0.95, size.height * 0.28),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, fill);
    canvas.drawPath(path, stroke);

    for (final p in points) {
      canvas.drawCircle(
        p,
        4,
        Paint()..color = AppColors.success.withValues(alpha: 0.25),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
