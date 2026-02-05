import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/models/meetup_model.dart';

/// Activity badge widget that displays sport/activity icon overlay on profile image.
///
/// Shows a circular badge with the meetup type icon in the bottom-right corner
/// of the profile image.
class ActivityBadge extends StatelessWidget {
  final MeetupType meetupType;
  final double size;

  const ActivityBadge({
    super.key,
    required this.meetupType,
    this.size = 24.0,
  });

  /// Get the appropriate icon for the given meetup type.
  IconData getIconForType(MeetupType type) {
    switch (type) {
      case MeetupType.football:
        return Icons.sports_soccer;
      case MeetupType.basketball:
        return Icons.sports_basketball;
      case MeetupType.volleyball:
        return Icons.sports_volleyball;
      case MeetupType.tennis:
      case MeetupType.tableTennis:
      case MeetupType.badminton:
        return Icons.sports_tennis;
      case MeetupType.running:
        return Icons.directions_run;
      case MeetupType.cycling:
        return Icons.directions_bike;
      case MeetupType.swimming:
        return Icons.pool;
      case MeetupType.hiking:
        return Icons.hiking;
      case MeetupType.yoga:
        return Icons.self_improvement;
      case MeetupType.fitness:
        return Icons.fitness_center;
      case MeetupType.boxing:
        return Icons.sports_mma;
      case MeetupType.climbing:
        return Icons.terrain;
      case MeetupType.skiing:
        return Icons.downhill_skiing;
      case MeetupType.other:
        return Icons.sports;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        getIconForType(meetupType),
        color: Colors.white,
        size: size * 0.55,
      ),
    );
  }
}
