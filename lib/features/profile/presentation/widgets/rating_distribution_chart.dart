import 'package:flutter/material.dart';
import '../../../../core/models/rating_distribution.dart';

class RatingDistributionChart extends StatelessWidget {
  final RatingDistribution distribution;

  const RatingDistributionChart({
    super.key,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      children: [
        _buildDistributionRow(context, 5, distribution.fiveStarCount, distribution.fiveStarPercentage, primaryColor),
        const SizedBox(height: 8),
        _buildDistributionRow(context, 4, distribution.fourStarCount, distribution.fourStarPercentage, primaryColor),
        const SizedBox(height: 8),
        _buildDistributionRow(context, 3, distribution.threeStarCount, distribution.threeStarPercentage, primaryColor),
        const SizedBox(height: 8),
        _buildDistributionRow(context, 2, distribution.twoStarCount, distribution.twoStarPercentage, primaryColor),
        const SizedBox(height: 8),
        _buildDistributionRow(context, 1, distribution.oneStarCount, distribution.oneStarPercentage, primaryColor),
      ],
    );
  }

  Widget _buildDistributionRow(
    BuildContext context,
    int starLevel,
    int count,
    double percentage,
    Color primaryColor,
  ) {
    return Row(
      children: [
        // Star label
        SizedBox(
          width: 60,
          child: Row(
            children: [
              Text(
                '$starLevel',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.star,
                size: 16,
                color: Colors.amber,
              ),
            ],
          ),
        ),
        // Progress bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: distribution.totalCount > 0 ? percentage / 100 : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Percentage label
        SizedBox(
          width: 50,
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
