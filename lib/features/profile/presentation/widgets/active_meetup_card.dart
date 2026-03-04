import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/theme/app_theme.dart';

class ActiveMeetupCard extends StatelessWidget {
  final MeetupModel meetup;
  final Duration remainingTime;
  final VoidCallback? onTap;

  const ActiveMeetupCard({
    super.key,
    required this.meetup,
    required this.remainingTime,
    this.onTap,
  });

  String get _remainingTimeText {
    final totalMinutes = remainingTime.inMinutes;
    if (totalMinutes < 0) return '0dk kaldı';
    final hours = remainingTime.inHours;
    final minutes = totalMinutes % 60;
    if (hours > 0) return '${hours}s ${minutes}dk kaldı';
    return '${minutes}dk kaldı';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Left: CANLI indicator
            _buildLiveIndicator(),
            const SizedBox(width: 10),
            // Center: Sport type, location, remaining time
            Expanded(child: _buildInfo()),
            const SizedBox(width: 8),
            // Right: Sport type chip
            _buildSportChip(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'CANLI',
          style: GoogleFonts.lexend(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          meetup.type.displayName,
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
          meetup.locationName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.lexend(
            fontSize: 10,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _remainingTimeText,
          style: GoogleFonts.lexend(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildSportChip() {
    return Container(
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
    );
  }
}
