import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/rating_service.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class RateMembersScreen extends StatefulWidget {
  final String meetupId;
  final String meetupTitle;
  final List<String> participantIds;

  const RateMembersScreen({
    super.key,
    required this.meetupId,
    required this.meetupTitle,
    required this.participantIds,
  });

  @override
  State<RateMembersScreen> createState() => _RateMembersScreenState();
}

class _RateMembersScreenState extends State<RateMembersScreen> {
  final RatingService _ratingService = RatingService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, double> _ratings = {};
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, bool> _alreadyRated = {};

  List<UserModel> _participants = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _currentUserId;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  @override
  void dispose() {
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadParticipants() async {
    final authService = context.read<AuthService>();
    _currentUserId = authService.currentUserId;

    if (_currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Fetch user data for each participant ID
      final participants = <UserModel>[];
      for (final participantId in widget.participantIds) {
        if (participantId != _currentUserId) {
          final userDoc = await _firestore.collection('users').doc(participantId).get();
          if (userDoc.exists) {
            participants.add(UserModel.fromJson(userDoc.data()!));
          }
        }
      }

      // Load rating status for each participant
      for (final participant in participants) {
        _commentControllers[participant.id] = TextEditingController();

        // Check if already rated
        final hasRated = await _ratingService.hasRated(
          meetupId: widget.meetupId,
          raterId: _currentUserId!,
          ratedUserId: participant.id,
        );
        _alreadyRated[participant.id] = hasRated;
      }

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
      }
    }
  }

  Future<void> _submitRatings() async {
    if (_currentUserId == null) return;

    // Check if any ratings to submit
    final ratingsToSubmit = _ratings.entries
        .where((e) => !(_alreadyRated[e.key] ?? false))
        .toList();

    if (ratingsToSubmit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.rateAtLeastOne),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      int successCount = 0;

      for (final entry in ratingsToSubmit) {
        final userId = entry.key;
        final rating = entry.value;
        final comment = _commentControllers[userId]?.text.trim();

        try {
          await _ratingService.createRating(
            meetupId: widget.meetupId,
            raterId: _currentUserId!,
            ratedUserId: userId,
            rating: rating,
            comment: comment?.isNotEmpty == true ? comment : null,
          );
          successCount++;
          _alreadyRated[userId] = true;
        } catch (e) {
          debugPrint('Error rating user $userId: $e');
        }
      }

      if (!mounted) return;

      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.ratingsSubmitted(successCount)),
            backgroundColor: AppTheme.primary,
          ),
        );

        // Refresh the list to show updated status
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorWithMessage(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.rateParticipants),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _participants.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noParticipantsToRate,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final unratedCount = _participants
        .where((p) => !(_alreadyRated[p.id] ?? false))
        .length;

    return Column(
      children: [
        // Meetup info header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha:0.1),
            border: const Border(
              bottom: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.meetupTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.participantCount(_participants.length),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Participants list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _participants.length,
            itemBuilder: (context, index) {
              final participant = _participants[index];
              return _ParticipantRatingCard(
                participant: participant,
                currentRating: _ratings[participant.id] ?? 0,
                commentController: _commentControllers[participant.id]!,
                alreadyRated: _alreadyRated[participant.id] ?? false,
                onRatingChanged: (rating) {
                  setState(() {
                    _ratings[participant.id] = rating;
                  });
                },
              );
            },
          ),
        ),

        // Submit button
        if (unratedCount > 0)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRatings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.textDark,
                            ),
                          ),
                        )
                      : Text(
                          l10n.submitRatings,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ParticipantRatingCard extends StatelessWidget {
  final UserModel participant;
  final double currentRating;
  final TextEditingController commentController;
  final bool alreadyRated;
  final ValueChanged<double> onRatingChanged;

  const _ParticipantRatingCard({
    required this.participant,
    required this.currentRating,
    required this.commentController,
    required this.alreadyRated,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alreadyRated
            ? Colors.grey[100]
            : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alreadyRated
              ? Colors.grey[300]!
              : AppTheme.borderLight,
        ),
        boxShadow: alreadyRated ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200],
                backgroundImage: participant.profileImageUrl != null
                    ? NetworkImage(participant.profileImageUrl!)
                    : null,
                child: participant.profileImageUrl == null
                    ? Icon(Icons.person, color: Colors.grey[400])
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.username,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: alreadyRated
                            ? Colors.grey[600]
                            : AppTheme.textDark,
                      ),
                    ),
                    if (participant.location != null)
                      Text(
                        participant.location!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
              if (alreadyRated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.alreadyReviewed,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          if (!alreadyRated) ...[
            const SizedBox(height: 16),

            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1.0;
                return GestureDetector(
                  onTap: () => onRatingChanged(starValue),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      currentRating >= starValue
                          ? Icons.star
                          : Icons.star_border,
                      size: 36,
                      color: currentRating >= starValue
                          ? const Color(0xFFFF9800)
                          : Colors.grey[400],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),

            // Comment field
            TextField(
              controller: commentController,
              maxLines: 2,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: l10n.commentOptional,
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
                contentPadding: const EdgeInsets.all(12),
                counterStyle: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}





