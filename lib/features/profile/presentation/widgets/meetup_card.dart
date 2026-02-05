import 'package:flutter/material.dart';
import '../../../../core/models/eligible_meetup.dart';
import '../../../../theme/app_theme.dart';

class MeetupCard extends StatelessWidget {
  final EligibleMeetup meetup;
  final VoidCallback onRatePressed;

  const MeetupCard({
    super.key,
    required this.meetup,
    required this.onRatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        onTap: onRatePressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Sport icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getSportIcon(meetup.sportType),
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Meetup details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      meetup.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(meetup.date),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.sports,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatSportType(meetup.sportType),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Arrow indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSportIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'football':
        return Icons.sports_soccer;
      case 'basketball':
        return Icons.sports_basketball;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'tennis':
        return Icons.sports_tennis;
      case 'tabletennis':
        return Icons.sports_cricket;
      case 'badminton':
        return Icons.sports_tennis;
      case 'swimming':
        return Icons.pool;
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'hiking':
        return Icons.hiking;
      case 'yoga':
        return Icons.self_improvement;
      case 'fitness':
        return Icons.fitness_center;
      case 'boxing':
        return Icons.sports_mma;
      case 'climbing':
        return Icons.terrain;
      case 'skiing':
        return Icons.downhill_skiing;
      default:
        return Icons.sports;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatSportType(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'football':
        return 'Futbol';
      case 'basketball':
        return 'Basketbol';
      case 'volleyball':
        return 'Voleybol';
      case 'tennis':
        return 'Tenis';
      case 'tabletennis':
        return 'Masa Tenisi';
      case 'badminton':
        return 'Badminton';
      case 'swimming':
        return 'Yüzme';
      case 'running':
        return 'Koşu';
      case 'cycling':
        return 'Bisiklet';
      case 'hiking':
        return 'Doğa Yürüyüşü';
      case 'yoga':
        return 'Yoga';
      case 'fitness':
        return 'Fitness';
      case 'boxing':
        return 'Boks';
      case 'climbing':
        return 'Tırmanış';
      case 'skiing':
        return 'Kayak';
      default:
        return sportType;
    }
  }
}
