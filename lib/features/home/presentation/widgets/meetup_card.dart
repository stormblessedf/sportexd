import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/meetup_model.dart';
import '../../../../core/services/meetup_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/user_rating_badge.dart';
import '../../../meetups/presentation/widgets/join_celebration_overlay.dart';
import '../../../../l10n/app_localizations.dart';

class MeetupCard extends StatefulWidget {
  final MeetupModel meetup;
  final VoidCallback onTap;

  const MeetupCard({super.key, required this.meetup, required this.onTap});

  @override
  State<MeetupCard> createState() => _MeetupCardState();
}

class _MeetupCardState extends State<MeetupCard> {
  // Theme colors from HTML
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF13EC5B);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  // Local state for tracking join status
  late bool _isJoined;
  late int _currentParticipants;
  bool _isJoining = false;
  bool _isOnWaitlist = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;
  double? _organizerRating;

  @override
  void initState() {
    super.initState();
    final userId = AuthService().currentUserId;
    _isJoined = userId != null && widget.meetup.participantIds.contains(userId);
    _currentParticipants = widget.meetup.currentParticipants;
    _isOnWaitlist =
        userId != null && widget.meetup.waitlistUserIds.contains(userId);
    _fetchOrganizerRating();
  }

  Future<void> _fetchOrganizerRating() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.meetup.organizerId)
          .get();
      if (userDoc.exists && mounted) {
        final userData = userDoc.data();
        setState(() {
          _organizerRating = (userData?['averageRating'] as num?)?.toDouble();
        });
      }
    } catch (e) {
      debugPrint('Error fetching organizer rating: $e');
    }
  }

  @override
  void didUpdateWidget(MeetupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state if meetup changes (e.g., from parent refresh)
    if (oldWidget.meetup.id != widget.meetup.id) {
      final userId = AuthService().currentUserId;
      _isJoined =
          userId != null && widget.meetup.participantIds.contains(userId);
      _currentParticipants = widget.meetup.currentParticipants;
    }
  }

  Future<void> _handleJoin() async {
    final userId = AuthService().currentUserId;
    if (userId == null) {
      context.go('/login');
      return;
    }

    if (widget.meetup.isFootballWithTeams) {
      widget.onTap();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.selectPositionFirst),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      await MeetupService().joinMeetup(widget.meetup.id, userId);

      // Update local state immediately
      setState(() {
        _isJoined = true;
        _currentParticipants++;
        _isOnWaitlist = false; // Remove from waitlist
        _isJoining = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.joinedSuccessfully),
            backgroundColor: primary,
          ),
        );
        JoinCelebrationOverlay.show(context);
      }
    } catch (e) {
      setState(() {
        _isJoining = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleJoinWaitlist() async {
    final userId = AuthService().currentUserId;
    if (userId == null) {
      context.go('/login');
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      await MeetupService().joinWaitlist(widget.meetup.id, userId);

      setState(() {
        _isOnWaitlist = true;
        _isJoining = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.spotNotification),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isJoining = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetupService = MeetupService();
    final isPast = meetupService.isMeetupPast(widget.meetup);
    final isFull = _currentParticipants >= widget.meetup.maxParticipants;
    final userId = AuthService().currentUserId;

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
                      context.push(
                        '/user-profile/${widget.meetup.organizerId}',
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: surfaceLight, width: 2),
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
                        backgroundImage: widget.meetup.organizerImageUrl != null
                            ? NetworkImage(widget.meetup.organizerImageUrl!)
                            : null,
                        child: widget.meetup.organizerImageUrl == null
                            ? Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.grey[600],
                              )
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
                        UsernameWithRating(
                          username: widget.meetup.organizerName,
                          rating: _organizerRating,
                          userId: widget.meetup.organizerId,
                          usernameStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(widget.meetup.date),
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
                      color: _getSportColor(
                        widget.meetup.type,
                      ).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getSportIcon(widget.meetup.type),
                      size: 18,
                      color: _getSportColor(widget.meetup.type),
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
                          widget.meetup.title,
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
                              _formatDateTime(
                                widget.meetup.date,
                                endDate: widget.meetup.endDate,
                              ),
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
                                widget.meetup.locationName,
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
                            // Participants Tag - uses local state
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
                                '$_currentParticipants/${widget.meetup.maxParticipants} Kişi',
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
                                _getSportName(widget.meetup.type),
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
                        widget.meetup.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF1F5F9),
                            child: Icon(
                              _getSportIcon(widget.meetup.type),
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
                      onPressed: widget.onTap,
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
                  // Join/Waitlist Button
                  Expanded(
                    child: userId == null
                        ? ElevatedButton(
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
                          )
                        : _isJoined
                        ? ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary.withValues(alpha: 0.3),
                              foregroundColor: Colors.grey[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Katıldın ✓',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : isFull
                        ? ElevatedButton(
                            onPressed: _isJoining ? null : _handleJoinWaitlist,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isOnWaitlist
                                  ? Colors.green
                                  : Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: _isJoining
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _isOnWaitlist ? 'Listede ✓' : 'Hatırlat',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          )
                        : ElevatedButton(
                            onPressed: _isJoining ? null : _handleJoin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: textDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: _isJoining
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        textDark,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Katıl',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatDateTime(DateTime date, {DateTime? endDate}) {
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
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final startTime = '$hour:$minute';

    if (endDate != null) {
      final endHour = endDate.hour.toString().padLeft(2, '0');
      final endMinute = endDate.minute.toString().padLeft(2, '0');
      return '${date.day} ${months[date.month - 1]}, $startTime - $endHour:$endMinute';
    }
    return '${date.day} ${months[date.month - 1]}, $startTime';
  }

  String _getSportName(MeetupType type) {
    return type.displayName;
  }

  IconData _getSportIcon(MeetupType type) {
    switch (type) {
      case MeetupType.football:
        return Icons.sports_soccer;
      case MeetupType.basketball:
        return Icons.sports_basketball;
      case MeetupType.volleyball:
        return Icons.sports_volleyball;
      case MeetupType.tennis:
        return Icons.sports_tennis;
      case MeetupType.tableTennis:
        return Icons.sports_cricket;
      case MeetupType.badminton:
        return Icons.sports_tennis;
      case MeetupType.swimming:
        return Icons.pool;
      case MeetupType.running:
        return Icons.directions_run;
      case MeetupType.cycling:
        return Icons.directions_bike;
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

  Color _getSportColor(MeetupType type) {
    switch (type) {
      case MeetupType.football:
        return Colors.green;
      case MeetupType.basketball:
        return Colors.orange;
      case MeetupType.volleyball:
        return Colors.indigo;
      case MeetupType.tennis:
        return Colors.amber;
      case MeetupType.tableTennis:
        return Colors.teal;
      case MeetupType.badminton:
        return Colors.lime;
      case MeetupType.swimming:
        return Colors.cyan;
      case MeetupType.running:
        return Colors.blue;
      case MeetupType.cycling:
        return Colors.red;
      case MeetupType.hiking:
        return Colors.brown;
      case MeetupType.yoga:
        return Colors.purple;
      case MeetupType.fitness:
        return Colors.deepOrange;
      case MeetupType.boxing:
        return Colors.redAccent;
      case MeetupType.climbing:
        return Colors.blueGrey;
      case MeetupType.skiing:
        return Colors.lightBlue;
      case MeetupType.other:
        return Colors.grey;
    }
  }
}



