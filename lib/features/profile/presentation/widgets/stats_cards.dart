import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class StatsCards extends StatelessWidget {
  final double reliabilityScore;
  final int totalMeetups;
  final double averageRating;
  final int totalRatings;

  const StatsCards({
    super.key,
    required this.reliabilityScore,
    required this.totalMeetups,
    required this.averageRating,
    required this.totalRatings,
  });

  // Minimum ratings required to show rating
  static const int minRatingsToShow = 3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Reliability Card
          Expanded(
            child: _StatCard(
              value: '${reliabilityScore.round()}%',
              label: 'GÜVENİLİRLİK',
              color: const Color(0xFF2196F3), // Blue
              icon: Icons.verified_user,
            ),
          ),
          const SizedBox(width: 12),

          // Meetups Card
          Expanded(
            child: _StatCard(
              value: totalMeetups.toString(),
              label: 'ETKİNLİKLER',
              color: const Color(0xFF4CAF50), // Green
              icon: Icons.groups,
            ),
          ),
          const SizedBox(width: 12),

          // Rating Card (only show if minimum ratings met)
          Expanded(
            child: totalRatings >= minRatingsToShow
                ? _StatCard(
                    value: averageRating.toStringAsFixed(1),
                    label: 'PUAN',
                    color: const Color(0xFFFF9800), // Orange
                    icon: Icons.star,
                    showStar: true,
                  )
                : _StatCard(
                    value: '-',
                    label: 'PUAN',
                    color: Colors.grey[400]!,
                    icon: Icons.star_border,
                    subtitle: '$totalRatings/$minRatingsToShow',
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final bool showStar;
  final String? subtitle;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    this.showStar = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),

          // Value
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (showStar) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.star,
                  color: color,
                  size: 18,
                ),
              ],
            ],
          ),

          // Subtitle (for ratings below threshold)
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],

          const SizedBox(height: 4),

          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
