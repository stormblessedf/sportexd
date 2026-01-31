import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/meetup_model.dart';
import '../../../../core/services/meetup_service.dart';
import '../../../../core/services/auth_service.dart';

class MeetupCard extends StatelessWidget {
  final MeetupModel meetup;
  final VoidCallback onTap;

  const MeetupCard({super.key, required this.meetup, required this.onTap});

  // Theme colors from HTML
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF13EC5B);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final meetupService = MeetupService();
    final isPast = meetupService.isMeetupPast(meetup);
    
    return Opacity(
      opacity: isPast ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceLight,
          borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: User Info & Sport Icon
            Row(
              children: [
                // Profile Picture
                GestureDetector(
                  onTap: () {
                    context.push('/user-profile/${meetup.organizerId}');
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: surfaceLight,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: meetup.organizerImageUrl != null
                          ? NetworkImage(meetup.organizerImageUrl!)
                          : null,
                      child: meetup.organizerImageUrl == null
                          ? Icon(Icons.person, size: 20, color: Colors.grey[600])
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meetup.organizerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(meetup.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Sport Type Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getSportColor(meetup.type).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getSportIcon(meetup.type),
                    size: 18,
                    color: _getSportColor(meetup.type),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Body: Activity Info & Image
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        meetup.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      // Date
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDateTime(meetup.date),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              meetup.locationName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Tags
                      Row(
                        children: [
                          // Participants Tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${meetup.currentParticipants}/${meetup.maxParticipants} Kişi',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Sport Type Tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getSportName(meetup.type),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3B82F6),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Right: Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 96,
                    height: 96,
                    color: const Color(0xFFF1F5F9),
                    child: Image.network(
                      meetup.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF1F5F9),
                          child: Icon(
                            _getSportIcon(meetup.type),
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Footer: Action Buttons
            Row(
              children: [
                // Details Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textDark,
                      side: const BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Detaylar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Join Button
                Expanded(
                  child: FutureBuilder<String?>(
                    future: AuthService().currentUserId != null
                        ? Future.value(AuthService().currentUserId)
                        : Future.value(null),
                    builder: (context, userSnapshot) {
                      final userId = userSnapshot.data;
                      if (userId == null) {
                        return ElevatedButton(
                          onPressed: () => context.go('/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: textDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Giriş Yap',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }

                      final isJoined = meetup.participantIds.contains(userId);
                      final isFull = meetup.currentParticipants >= meetup.maxParticipants;

                      return ElevatedButton(
                        onPressed: isJoined || isFull
                            ? null
                            : () async {
                                try {
                                  await MeetupService().joinMeetup(meetup.id, userId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Etkinliğe katıldınız!'),
                                        backgroundColor: primary,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Hata: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isJoined
                              ? primary.withValues(alpha: 0.3)
                              : isFull
                                  ? Colors.grey[300]
                                  : primary,
                          foregroundColor: isJoined || isFull
                              ? Colors.grey[600]
                              : textDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          isJoined
                              ? 'Katıldın ✓'
                              : isFull
                                  ? 'Dolu'
                                  : 'Katıl',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]}, $hour:$minute';
  }

  String _getSportName(MeetupType type) {
    switch (type) {
      case MeetupType.football:
        return 'Futbol';
      case MeetupType.basketball:
        return 'Basketbol';
      case MeetupType.tennis:
        return 'Tenis';
      case MeetupType.yoga:
        return 'Yoga';
      case MeetupType.running:
        return 'Koşu';
      case MeetupType.other:
        return 'Diğer';
    }
  }

  IconData _getSportIcon(MeetupType type) {
    switch (type) {
      case MeetupType.football:
        return Icons.sports_soccer;
      case MeetupType.basketball:
        return Icons.sports_basketball;
      case MeetupType.tennis:
        return Icons.sports_tennis;
      case MeetupType.yoga:
        return Icons.self_improvement;
      case MeetupType.running:
        return Icons.directions_run;
      case MeetupType.other:
        return Icons.sports;
    }
  }

  Color _getSportColor(MeetupType type) {
    switch (type) {
      case MeetupType.football:
        return Colors.green;
      case MeetupType.basketball:
        return Colors.orange;
      case MeetupType.tennis:
        return Colors.amber;
      case MeetupType.yoga:
        return Colors.purple;
      case MeetupType.running:
        return Colors.blue;
      case MeetupType.other:
        return Colors.grey;
    }
  }
}
