import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/app_theme.dart';

class StatsCards extends StatelessWidget {
  final double reliabilityScore;
  final int totalMeetups;
  final String profileOwnerId;
  final VoidCallback? onRatingTap;

  const StatsCards({
    super.key,
    required this.reliabilityScore,
    required this.totalMeetups,
    required this.profileOwnerId,
    this.onRatingTap,
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
              color: const Color(0xFF2196F3),
              icon: Icons.verified_user,
            ),
          ),
          const SizedBox(width: 12),

          // Meetups Card
          Expanded(
            child: _StatCard(
              value: totalMeetups.toString(),
              label: 'ETKİNLİKLER',
              color: const Color(0xFF4CAF50),
              icon: Icons.groups,
            ),
          ),
          const SizedBox(width: 12),

          // Rating Card - Real-time with StreamBuilder
          Expanded(
            child: _RatingStatCard(
              profileOwnerId: profileOwnerId,
              minRatingsToShow: minRatingsToShow,
              onTap: onRatingTap,
            ),
          ),
        ],
      ),
    );
  }
}

/// Real-time Rating Card that listens to Firestore changes
class _RatingStatCard extends StatelessWidget {
  final String profileOwnerId;
  final int minRatingsToShow;
  final VoidCallback? onTap;

  const _RatingStatCard({
    required this.profileOwnerId,
    required this.minRatingsToShow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(profileOwnerId)
          .snapshots(),
      builder: (context, snapshot) {
        double averageRating = 0.0;
        int totalRatings = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            averageRating = (data['averageRating'] ?? 0.0).toDouble();
            totalRatings = (data['totalRatings'] ?? 0) as int;
          }
        }

        return GestureDetector(
          onTap: onTap,
          child: totalRatings >= minRatingsToShow
              ? _StatCard(
                  value: averageRating.toStringAsFixed(1),
                  label: 'PUAN',
                  color: const Color(0xFFFF9800),
                  icon: Icons.star,
                  showStar: true,
                  isClickable: onTap != null,
                )
              : _StatCard(
                  value: totalRatings > 0 ? averageRating.toStringAsFixed(1) : '-',
                  label: 'PUAN',
                  color: totalRatings > 0 ? const Color(0xFFFF9800) : Colors.grey,
                  icon: totalRatings > 0 ? Icons.star : Icons.star_border,
                  subtitle: '$totalRatings/$minRatingsToShow değerlendirme',
                  showStar: totalRatings > 0,
                  isClickable: onTap != null,
                ),
        );
      },
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
  final bool isClickable;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    this.showStar = false,
    this.subtitle,
    this.isClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClickable ? color.withValues(alpha: 0.3) : AppTheme.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              color: color.withValues(alpha: 0.15),
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
                fontSize: 9,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
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

          // Clickable indicator
          if (isClickable) ...[
            const SizedBox(height: 4),
            Icon(
              Icons.touch_app,
              size: 12,
              color: Colors.grey[400],
            ),
          ],
        ],
      ),
    );
  }
}
