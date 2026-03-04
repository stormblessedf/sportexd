import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/theme/app_theme.dart';

class CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final Set<int> eventDays;
  final Set<int> pastEventDays;
  final Set<int> activeEventDays;
  final DateTime today;

  const CalendarGrid({
    super.key,
    required this.year,
    required this.month,
    required this.eventDays,
    this.pastEventDays = const {},
    this.activeEventDays = const {},
    required this.today,
  });

  bool _isToday(int day) =>
      today.year == year && today.month == month && today.day == day;

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = (firstDayOfMonth.weekday - 1) % 7;
    final totalCells = firstWeekday + daysInMonth;

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: List.generate(totalCells, (index) {
        if (index < firstWeekday) {
          return const SizedBox.shrink();
        }

        final day = index - firstWeekday + 1;
        final isUpcoming = eventDays.contains(day);
        final isPast = pastEventDays.contains(day);
        final isActive = activeEventDays.contains(day);
        final isToday = _isToday(day);

        return _DayCell(
          day: day,
          isUpcomingEvent: isUpcoming,
          isPastEvent: isPast,
          isActiveEvent: isActive,
          isToday: isToday,
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isUpcomingEvent;
  final bool isPastEvent;
  final bool isActiveEvent;
  final bool isToday;

  const _DayCell({
    required this.day,
    required this.isUpcomingEvent,
    required this.isPastEvent,
    this.isActiveEvent = false,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final hasEvent = isUpcomingEvent || isPastEvent || isActiveEvent;

    Color bgColor;
    Color textColor;

    // Priority: isToday > isActiveEvent > isUpcomingEvent > isPastEvent
    if (isToday) {
      bgColor = AppTheme.primary;
      textColor = Colors.white;
    } else if (isActiveEvent) {
      bgColor = const Color(0xFF4CAF50);
      textColor = Colors.white;
    } else if (isUpcomingEvent) {
      bgColor = const Color(0xFF2196F3);
      textColor = Colors.white;
    } else if (isPastEvent) {
      bgColor = const Color(0xFFBBDEFB);
      textColor = const Color(0xFF1565C0);
    } else {
      bgColor = Colors.transparent;
      textColor = AppTheme.textMuted;
    }

    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: GoogleFonts.lexend(
            fontSize: 12,
            fontWeight: hasEvent || isToday ? FontWeight.w600 : FontWeight.normal,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
