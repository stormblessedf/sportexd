import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/theme/app_theme.dart';

class CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final Set<int> eventDays;
  final DateTime today;

  const CalendarGrid({
    super.key,
    required this.year,
    required this.month,
    required this.eventDays,
    required this.today,
  });

  bool _isToday(int day) =>
      today.year == year && today.month == month && today.day == day;

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Monday = 0, Sunday = 6
    final firstWeekday = (firstDayOfMonth.weekday - 1) % 7;
    final totalCells = firstWeekday + daysInMonth;

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(totalCells, (index) {
        if (index < firstWeekday) {
          return const SizedBox.shrink();
        }

        final day = index - firstWeekday + 1;
        final isEvent = eventDays.contains(day);
        final isToday = _isToday(day);

        return _DayCell(day: day, isEvent: isEvent, isToday: isToday);
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isEvent;
  final bool isToday;

  const _DayCell({
    required this.day,
    required this.isEvent,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.lexend(
      fontSize: 12,
      fontWeight: isEvent ? FontWeight.bold : FontWeight.normal,
      color: isEvent || isToday ? AppTheme.textDark : AppTheme.textMuted,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: isToday
              ? BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                )
              : null,
          alignment: Alignment.center,
          child: Text('$day', style: textStyle),
        ),
        if (isEvent)
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }
}
