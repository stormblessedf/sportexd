import 'package:flutter/material.dart';
import '../../../core/models/rating_model.dart';
import '../../../core/models/eligible_meetup.dart';
import '../../../core/services/rating_service.dart';
import '../../../core/services/partnership_service.dart';
import '../../../core/widgets/partnership_suggestion_dialog.dart';
import 'widgets/star_rating_selector.dart';
import 'widgets/comment_text_field.dart';
import '../../../l10n/app_localizations.dart';

class RateUserScreen extends StatefulWidget {
  final String currentUserId;
  final String profileOwnerId;
  final EligibleMeetup meetup;

  const RateUserScreen({
    super.key,
    required this.currentUserId,
    required this.profileOwnerId,
    required this.meetup,
  });

  @override
  State<RateUserScreen> createState() => _RateUserScreenState();
}

class _RateUserScreenState extends State<RateUserScreen> {
  final RatingService _ratingService = RatingService();
  final PartnershipService _partnershipService = PartnershipService();
  final TextEditingController _commentController = TextEditingController();

  int? _selectedRating;
  bool _isSubmitting = false;
  String? _errorMessage;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    // Validate
    if (_selectedRating == null) {
      setState(() {
        _errorMessage = l10n.selectRating;
      });
      return;
    }

    if (_commentController.text.length > 200) {
      setState(() {
        _errorMessage = l10n.commentMaxLength;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final ratingId = DateTime.now().millisecondsSinceEpoch.toString();
      final rating = RatingModel(
        id: ratingId,
        meetupId: widget.meetup.meetupId,
        raterId: widget.currentUserId,
        ratedUserId: widget.profileOwnerId,
        rating: _selectedRating!.toDouble(),
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _ratingService.submitRating(rating);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.ratingSubmitted),
            backgroundColor: Colors.green,
          ),
        );

        // Check for partnership suggestion (4-5 stars)
        if (_selectedRating! >= 4) {
          final suggestion = await _partnershipService.checkForSuggestion(
            raterId: widget.currentUserId,
            ratedUserId: widget.profileOwnerId,
            meetupId: widget.meetup.meetupId,
            stars: _selectedRating!,
            attended: true,
          );
          if (suggestion != null && mounted) {
            final sharedIds = await _partnershipService.getSharedMeetupIds(
              widget.currentUserId,
              widget.profileOwnerId,
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
                        requesterId: widget.currentUserId,
                        receiverId: widget.profileOwnerId,
                        sharedMeetupIds: sharedIds,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.partnerRequestSent),
                            backgroundColor: Colors.green,
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
          }
        }

        // Pop back to profile with refresh flag
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
          Navigator.of(context).pop(true); // Pop select meetup screen too
        }
      }
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      String errorMsg = l10n.ratingSubmitFailed;
      if (e is ArgumentError) {
        errorMsg = e.message.toString();
      } else if (e is StateError) {
        errorMsg = l10n.alreadyRatedUser;
      }
      setState(() {
        _errorMessage = errorMsg;
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rateUserTitle), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Meetup context card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.eventLabel,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.meetup.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Star rating selector
            Text(
              l10n.yourRating,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            StarRatingSelector(
              selectedRating: _selectedRating,
              onRatingSelected: (rating) {
                setState(() {
                  _selectedRating = rating;
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 24),
            // Comment field
            Text(
              l10n.commentOptional,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            CommentTextField(
              controller: _commentController,
              onChanged: (_) {
                setState(() {
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 24),
            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting || _selectedRating == null
                  ? null
                  : _submitRating,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(l10n.submitRating),
            ),
          ],
        ),
      ),
    );
  }
}
