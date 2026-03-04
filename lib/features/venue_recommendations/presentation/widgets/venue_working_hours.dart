import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/theme/app_colors.dart';

/// Displays venue working hours in a day-by-day table format.
///
/// Highlights today's row with a subtle primary background.
/// Shows an "Açık" / "Kapalı" badge next to the section title.
/// If [weekdayHours] is empty, shows a fallback message.
///
/// Validates: Requirements 6.4
class VenueWorkingHours extends StatelessWidget {
  const VenueWorkingHours({
    super.key,
    required this.weekdayHours,
    required this.isOpen,
  });

  /// 7 elements from Google Places API, e.g. ["Pazartesi: 09:00–22:00", ...].
  /// Index 0 = Monday, index 6 = Sunday.
  final List<String> weekdayHours;

  /// Current open/closed status of the venue.
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        if (weekdayHours.isEmpty)
          _buildEmpty()
        else
          _buildHoursTable(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.access_time_rounded,
          size: 20,
          color: AppColors.textDark,
        ),
        const SizedBox(width: 8),
        Text(
          'Çalışma Saatleri',
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(width: 8),
        _OpenClosedBadge(isOpen: isOpen),
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Çalışma saatleri bilgisi yok',
        style: GoogleFonts.lexend(
          fontSize: 13,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildHoursTable() {
    // DateTime.now().weekday: 1=Monday, 7=Sunday
    // weekdayHours is 0-indexed starting from Monday
    final todayIndex = DateTime.now().weekday - 1; // 0=Monday, 6=Sunday

    return Column(
      children: List.generate(weekdayHours.length, (index) {
        final isToday = index == todayIndex;
        final parts = _parseDayAndHours(weekdayHours[index]);

        return _HoursRow(
          day: parts.$1,
          hours: parts.$2,
          isToday: isToday,
        );
      }),
    );
  }

  /// Splits a string like "Pazartesi: 09:00–22:00" into (day, hours).
  /// Falls back gracefully if the format is unexpected.
  static (String, String) _parseDayAndHours(String entry) {
    final colonIndex = entry.indexOf(':');
    if (colonIndex == -1) return (entry.trim(), '');
    final day = entry.substring(0, colonIndex).trim();
    final hours = entry.substring(colonIndex + 1).trim();
    return (day, hours);
  }
}

/// A single row in the working hours table.
class _HoursRow extends StatelessWidget {
  const _HoursRow({
    required this.day,
    required this.hours,
    required this.isToday,
  });

  final String day;
  final String hours;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isToday ? AppColors.primary.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              day,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                color: isToday ? AppColors.textDark : AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              hours,
              textAlign: TextAlign.end,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                color: isToday ? AppColors.textDark : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small badge showing "Açık" (green) or "Kapalı" (red).
class _OpenClosedBadge extends StatelessWidget {
  const _OpenClosedBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isOpen ? 'Açık' : 'Kapalı',
        style: GoogleFonts.lexend(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isOpen ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}
