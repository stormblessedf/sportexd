import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/theme/app_theme.dart';
import '../../data/statistics_constants.dart';

class SportDistributionChart extends StatelessWidget {
  final Map<MeetupType, double> sportPercentages;
  final Map<MeetupType, int> sportDistribution;

  const SportDistributionChart({
    super.key,
    required this.sportPercentages,
    required this.sportDistribution,
  });

  @override
  Widget build(BuildContext context) {
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
            'Spor Dağılımı',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          if (sportPercentages.isEmpty)
            _buildEmptyState()
          else ...[
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: _buildSections(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return sportPercentages.entries.map((entry) {
      final color = sportColors[entry.key] ?? Colors.grey;
      final emoji = sportEmojis[entry.key] ?? '🏅';
      return PieChartSectionData(
        value: entry.value,
        color: color,
        radius: 50,
        title: '$emoji ${entry.value.toStringAsFixed(0)}%',
        titleStyle: GoogleFonts.lexend(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: sportDistribution.entries.map((entry) {
        final color = sportColors[entry.key] ?? Colors.grey;
        final emoji = sportEmojis[entry.key] ?? '🏅';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$emoji ${entry.key.displayName} (${entry.value})',
              style: GoogleFonts.lexend(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Henüz etkinlik verisi yok',
          style: GoogleFonts.lexend(
            fontSize: 13,
            color: AppTheme.textLight,
          ),
        ),
      ),
    );
  }
}
