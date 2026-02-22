import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/theme/app_theme.dart';
import '../../models/user_statistics_model.dart';
import '../../data/statistics_constants.dart';

class ActivityTrendChart extends StatelessWidget {
  final List<MonthlyActivity> monthlyActivities;

  const ActivityTrendChart({
    super.key,
    required this.monthlyActivities,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = monthlyActivities.isEmpty
        ? 5.0
        : (monthlyActivities
                    .map((a) => a.count)
                    .reduce((a, b) => a > b ? a : b)
                    .toDouble() *
                1.3)
            .ceilToDouble()
            .clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aylık Aktivite',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY / 4).ceilToDouble().clamp(1, maxY),
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppTheme.borderLight,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= monthlyActivities.length) {
                          return const SizedBox.shrink();
                        }
                        final month = monthlyActivities[idx].month;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            turkishMonthAbbreviations[month - 1],
                            style: GoogleFonts.lexend(
                              fontSize: 10,
                              color: AppTheme.textLight,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.lexend(
                            fontSize: 10,
                            color: AppTheme.textLight,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      monthlyActivities.length,
                      (i) => FlSpot(
                        i.toDouble(),
                        monthlyActivities[i].count.toDouble(),
                      ),
                    ),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: AppTheme.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: AppTheme.primary,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
