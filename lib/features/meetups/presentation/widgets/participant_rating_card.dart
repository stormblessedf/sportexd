import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import 'attendance_toggle.dart';

class ParticipantRatingData {
  final String odiserId;
  AttendanceStatus attendance;
  int? rating;

  ParticipantRatingData({
    required this.odiserId,
    this.attendance = AttendanceStatus.notSelected,
    this.rating,
  });
}

class ParticipantRatingCard extends StatelessWidget {
  final UserModel participant;
  final bool isOrganizer;
  final AttendanceStatus attendance;
  final int? rating;
  final String? comment;
  final ValueChanged<AttendanceStatus> onAttendanceChanged;
  final ValueChanged<int> onRatingChanged;
  final ValueChanged<String> onCommentChanged;

  const ParticipantRatingCard({
    super.key,
    required this.participant,
    this.isOrganizer = false,
    required this.attendance,
    this.rating,
    this.comment,
    required this.onAttendanceChanged,
    required this.onRatingChanged,
    required this.onCommentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final showRating = attendance == AttendanceStatus.attended;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User info row
            Row(
              children: [
                // Avatar with ORG badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: participant.profileImageUrl != null
                            ? NetworkImage(participant.profileImageUrl!)
                            : null,
                        child: participant.profileImageUrl == null
                            ? Icon(Icons.person, color: Colors.grey[600])
                            : null,
                      ),
                    ),
                    if (isOrganizer)
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF13EC5B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Text(
                            'ORG',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF102216),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Name
                Expanded(
                  child: Text(
                    participant.username,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                // Attendance toggle
                AttendanceToggle(
                  status: attendance,
                  onChanged: onAttendanceChanged,
                ),
              ],
            ),
            // Rating section (only if attended)
            if (showRating) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Performans / Fair Play',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        _buildStarRating(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Comment field
                    TextField(
                      onChanged: onCommentChanged,
                      maxLines: 2,
                      maxLength: 150,
                      decoration: InputDecoration(
                        hintText: 'Kısa bir yorum ekle (opsiyonel)',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF13EC5B)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        counterStyle: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[400],
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF0F172A),
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

  Widget _buildStarRating() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1; // Left to right: 1, 2, 3, 4, 5
        final isSelected = rating != null && rating! >= starValue;

        return GestureDetector(
          onTap: () => onRatingChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              Icons.star,
              size: 32,
              color: isSelected ? const Color(0xFFFFB800) : const Color(0xFFE2E8F0),
            ),
          ),
        );
      }),
    );
  }
}
