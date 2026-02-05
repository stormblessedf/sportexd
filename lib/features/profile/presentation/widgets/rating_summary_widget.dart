import 'package:flutter/material.dart';
import '../../../../core/models/rating_distribution.dart';
import 'rating_distribution_chart.dart';

class RatingSummaryWidget extends StatelessWidget {
  final double averageRating;
  final int totalRatings;
  final RatingDistribution distribution;

  const RatingSummaryWidget({
    super.key,
    required this.averageRating,
    required this.totalRatings,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Average Rating Display
            Row(
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStarVisualization(averageRating),
                    const SizedBox(height: 4),
                    Text(
                      '$totalRatings ${totalRatings == 1 ? 'rating' : 'ratings'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Rating Distribution Chart
            RatingDistributionChart(distribution: distribution),
          ],
        ),
      ),
    );
  }

  Widget _buildStarVisualization(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        if (rating >= starValue) {
          // Full star
          return const Icon(
            Icons.star,
            color: Colors.amber,
            size: 20,
          );
        } else if (rating >= starValue - 0.5) {
          // Half star
          return const Icon(
            Icons.star_half,
            color: Colors.amber,
            size: 20,
          );
        } else {
          // Empty star
          return Icon(
            Icons.star_border,
            color: Colors.grey[400],
            size: 20,
          );
        }
      }),
    );
  }
}
