import 'package:flutter/material.dart';
import '../../../../core/models/rating_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../theme/app_theme.dart';

class RatingCard extends StatelessWidget {
  final RatingModel rating;
  final UserModel rater;
  final bool showAsGiven;

  const RatingCard({
    super.key,
    required this.rating,
    required this.rater,
    this.showAsGiven = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label for given ratings
            if (showAsGiven) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Verdiğim Puan',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Header: Profile picture, name, and time
            Row(
              children: [
                // Profile picture
                CircleAvatar(
                  radius: 20,
                  backgroundImage: rater.profileImageUrl != null
                      ? NetworkImage(rater.profileImageUrl!)
                      : null,
                  child: rater.profileImageUrl == null
                      ? Text(
                          rater.username.isNotEmpty ? rater.username[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Name and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              rater.username,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showAsGiven) ...[
                            const SizedBox(width: 4),
                            Text(
                              'kişisine',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        formatRelativeTime(rating.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                // Star rating
                _buildStarRating(rating.rating),
              ],
            ),
            const SizedBox(height: 12),
            // Meetup context
            if (rating.meetupTitle != null || rating.sportType != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.sports_soccer,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _buildMeetupContext(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            // Comment
            if (rating.comment != null && rating.comment!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rating.comment!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 18,
        ),
      ],
    );
  }

  String _buildMeetupContext() {
    final parts = <String>[];
    if (rating.meetupTitle != null) {
      parts.add(rating.meetupTitle!);
    }
    if (rating.sportType != null) {
      parts.add(_formatSportType(rating.sportType!));
    }
    return parts.join(' • ');
  }

  String _formatSportType(String sportType) {
    // Convert enum name to display name
    switch (sportType.toLowerCase()) {
      case 'football':
        return 'Futbol';
      case 'basketball':
        return 'Basketbol';
      case 'tennis':
        return 'Tenis';
      case 'yoga':
        return 'Yoga';
      case 'running':
        return 'Koşu';
      default:
        return sportType;
    }
  }
}
