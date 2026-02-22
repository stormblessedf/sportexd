import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/theme/app_theme.dart';

class CalendarEventCard extends StatelessWidget {
  final MeetupModel meetup;
  final VoidCallback? onTap;

  const CalendarEventCard({
    super.key,
    required this.meetup,
    this.onTap,
  });

  Color get _statusDotColor {
    if (meetup.isFull) return const Color(0xFFFF9800); // amber
    if (meetup.date.isAfter(DateTime.now())) return const Color(0xFF2196F3); // blue
    return const Color(0xFF4CAF50); // green
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _statusDotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meetup.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('dd MMM', 'tr').format(meetup.date)} • ${DateFormat('HH:mm').format(meetup.date)} • ${meetup.currentParticipants}/${meetup.maxParticipants} kişi',
                    style: GoogleFonts.lexend(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                meetup.type.displayName,
                style: GoogleFonts.lexend(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0A8F35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
