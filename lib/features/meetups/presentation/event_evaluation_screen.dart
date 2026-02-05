import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/meetup_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/rating_model.dart';
import '../../../core/services/rating_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/partnership_model.dart';
import '../../../core/services/partnership_service.dart';
import '../../../core/widgets/partnership_suggestion_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/attendance_toggle.dart';
import 'widgets/participant_rating_card.dart';

class ParticipantEvaluation {
  final UserModel user;
  final bool isOrganizer;
  AttendanceStatus attendance;
  int? rating;
  String? comment;

  ParticipantEvaluation({
    required this.user,
    this.isOrganizer = false,
    this.attendance = AttendanceStatus.notSelected,
    this.rating,
    this.comment,
  });
}

class EventEvaluationScreen extends StatefulWidget {
  final MeetupModel meetup;

  const EventEvaluationScreen({
    super.key,
    required this.meetup,
  });

  @override
  State<EventEvaluationScreen> createState() => _EventEvaluationScreenState();
}

class _EventEvaluationScreenState extends State<EventEvaluationScreen> {
  final RatingService _ratingService = RatingService();
  final PartnershipService _partnershipService = PartnershipService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ParticipantEvaluation> _participants = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      _currentUserId = AuthService().currentUserId;
      if (_currentUserId == null) {
        if (mounted) context.go('/login');
        return;
      }

      final participants = <ParticipantEvaluation>[];

      for (final participantId in widget.meetup.participantIds) {
        // Skip current user - can't rate yourself
        if (participantId == _currentUserId) continue;

        // Check if already rated this user for this meetup
        final hasRated = await _ratingService.hasRatedUserInMeetup(
          _currentUserId!,
          participantId,
          widget.meetup.id,
        );
        if (hasRated) continue;

        // Fetch user data
        final userDoc = await _firestore.collection('users').doc(participantId).get();
        if (!userDoc.exists) continue;

        final user = UserModel.fromJson(userDoc.data()!);
        final isOrganizer = participantId == widget.meetup.organizerId;

        participants.add(ParticipantEvaluation(
          user: user,
          isOrganizer: isOrganizer,
        ));
      }

      // Sort: organizer first, then alphabetically
      participants.sort((a, b) {
        if (a.isOrganizer && !b.isOrganizer) return -1;
        if (!a.isOrganizer && b.isOrganizer) return 1;
        return a.user.username.compareTo(b.user.username);
      });

      if (mounted) {
        setState(() {
          _participants = participants;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading participants: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Katılımcılar yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitEvaluations() async {
    // Validate - at least one evaluation needed
    final attendedParticipants = _participants
        .where((p) => p.attendance == AttendanceStatus.attended)
        .toList();

    if (attendedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir katılımcıyı "Geldi" olarak işaretleyin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check all attended have ratings
    final missingRatings = attendedParticipants.where((p) => p.rating == null).toList();
    if (missingRatings.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${missingRatings.length} kişinin puanı eksik'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      int successCount = 0;

      for (final participant in attendedParticipants) {
        if (participant.rating == null) continue;

        final ratingId = '${widget.meetup.id}_${_currentUserId}_${participant.user.id}';
        final rating = RatingModel(
          id: ratingId,
          meetupId: widget.meetup.id,
          raterId: _currentUserId!,
          ratedUserId: participant.user.id,
          rating: participant.rating!.toDouble(),
          comment: participant.comment,
          createdAt: DateTime.now(),
          meetupTitle: widget.meetup.title,
          sportType: widget.meetup.type.name,
        );

        await _ratingService.submitRating(rating);
        successCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount değerlendirme başarıyla gönderildi!'),
            backgroundColor: const Color(0xFF13EC5B),
          ),
        );

        // Check for partnership suggestions (4-5 star ratings for attended users)
        for (final participant in attendedParticipants) {
          if (participant.rating != null && participant.rating! >= 4) {
            // Check if already partners
            final existingPartnership = await _partnershipService.getPartnershipStatus(
              _currentUserId!,
              participant.user.id,
            );
            if (existingPartnership?.status == PartnershipStatus.accepted) {
              continue; // Already partners, skip suggestion
            }

            final suggestion = await _partnershipService.checkForSuggestion(
              raterId: _currentUserId!,
              ratedUserId: participant.user.id,
              meetupId: widget.meetup.id,
              stars: participant.rating!,
              attended: true,
            );
            if (suggestion != null && mounted) {
              final sharedIds = await _partnershipService.getSharedMeetupIds(
                _currentUserId!,
                participant.user.id,
              );
              if (mounted) {
                await showDialog(
                  context: context,
                  builder: (dialogContext) => PartnershipSuggestionDialog(
                    suggestion: suggestion,
                    onAccept: () async {
                      Navigator.pop(dialogContext);
                      try {
                        await _partnershipService.sendPartnershipRequest(
                          requesterId: _currentUserId!,
                          receiverId: participant.user.id,
                          sharedMeetupIds: sharedIds,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Partner isteği gönderildi!'),
                              backgroundColor: Color(0xFF13EC5B),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Error sending partnership request: $e');
                      }
                    },
                    onDismiss: () => Navigator.pop(dialogContext),
                  ),
                );
              }
              break; // Only show one suggestion per submission
            }
          }
        }

        if (mounted) context.pop(true);
      }
    } catch (e) {
      debugPrint('Error submitting evaluations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatDateTime(DateTime date, DateTime? endDate) {
    final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    final startTime = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    String timeRange = startTime;
    if (endDate != null) {
      final endTime = '${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}';
      timeRange = '$startTime - $endTime';
    }

    return '${date.day} ${months[date.month - 1]} ${date.year} • $timeRange';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Etkinlik Değerlendirme',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'İptal',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _participants.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
      bottomNavigationBar: _participants.isNotEmpty ? _buildBottomBar() : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tüm katılımcıları değerlendirdiniz',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu etkinlik için değerlendirilecek kimse kalmadı.',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Geri Dön'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event info card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.meetup.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDateTime(widget.meetup.date, widget.meetup.endDate),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.meetup.locationName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/detail', extra: widget.meetup),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF13EC5B).withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Detaylar',
                          style: TextStyle(
                            color: Color(0xFF0eb545),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Participants header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Katılımcılar',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Participant cards
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _participants.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final participant = _participants[index];
              return ParticipantRatingCard(
                participant: participant.user,
                isOrganizer: participant.isOrganizer,
                attendance: participant.attendance,
                rating: participant.rating,
                comment: participant.comment,
                onAttendanceChanged: (status) {
                  setState(() {
                    participant.attendance = status;
                    if (status != AttendanceStatus.attended) {
                      participant.rating = null;
                      participant.comment = null;
                    }
                  });
                },
                onRatingChanged: (rating) {
                  setState(() {
                    participant.rating = rating;
                  });
                },
                onCommentChanged: (comment) {
                  participant.comment = comment.isEmpty ? null : comment;
                },
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final attendedCount = _participants
        .where((p) => p.attendance == AttendanceStatus.attended)
        .length;
    final ratedCount = _participants
        .where((p) => p.attendance == AttendanceStatus.attended && p.rating != null)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitEvaluations,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF13EC5B),
            foregroundColor: const Color(0xFF102216),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF102216)),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      attendedCount > 0
                          ? 'Değerlendirmeyi Tamamla ($ratedCount/$attendedCount)'
                          : 'Değerlendirmeyi Tamamla',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
