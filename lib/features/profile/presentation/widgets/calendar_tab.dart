import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/core/services/meetup_service.dart';
import 'package:sporsal/features/profile/presentation/widgets/active_meetup_card.dart';
import 'package:sporsal/features/profile/presentation/widgets/calendar_event_card.dart';
import 'package:sporsal/features/profile/presentation/widgets/calendar_grid.dart';
import 'package:sporsal/theme/app_theme.dart';

class CalendarTab extends StatefulWidget {
  final List<MeetupModel> meetups;
  final Function(MeetupModel) onMeetupTap;
  final MeetupService meetupService;

  const CalendarTab({
    super.key,
    required this.meetups,
    required this.onMeetupTap,
    required this.meetupService,
  });

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  late DateTime _selectedMonth;

  static const _turkishMonths = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  static const _weekdayHeaders = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  List<MeetupModel> get _activeMeetups => widget.meetups
      .where((m) => widget.meetupService.isMeetupActive(m))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  Set<int> get _activeEventDays => widget.meetups
      .where((m) =>
          m.date.year == _selectedMonth.year &&
          m.date.month == _selectedMonth.month &&
          widget.meetupService.isMeetupActive(m))
      .map((m) => m.date.day)
      .toSet();

  List<MeetupModel> get _monthMeetups => widget.meetups
      .where((m) =>
          m.date.year == _selectedMonth.year &&
          m.date.month == _selectedMonth.month &&
          m.date.isAfter(DateTime.now()) &&
          !widget.meetupService.isMeetupActive(m))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  Set<int> get _eventDays => widget.meetups
      .where((m) =>
          m.date.year == _selectedMonth.year &&
          m.date.month == _selectedMonth.month)
      .map((m) => m.date.day)
      .toSet();

  Set<int> get _pastEventDays => widget.meetups
      .where((m) =>
          m.date.year == _selectedMonth.year &&
          m.date.month == _selectedMonth.month &&
          !m.date.isAfter(DateTime.now()))
      .map((m) => m.date.day)
      .toSet();

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthName = _turkishMonths[_selectedMonth.month - 1];
    final title = '$monthName ${_selectedMonth.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month navigation row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousMonth,
            ),
            Text(
              title,
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _nextMonth,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Turkish weekday headers
        Row(
          children: _weekdayHeaders
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        // Calendar grid
        CalendarGrid(
          year: _selectedMonth.year,
          month: _selectedMonth.month,
          eventDays: _eventDays,
          pastEventDays: _pastEventDays,
          activeEventDays: _activeEventDays,
          today: DateTime.now(),
        ),
        if (_activeMeetups.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            'Şu An Aktif',
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 8),
          ..._activeMeetups.map((meetup) {
            final effectiveEnd =
                widget.meetupService.getEffectiveEndDate(meetup);
            final remaining = effectiveEnd.difference(DateTime.now());
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ActiveMeetupCard(
                meetup: meetup,
                remainingTime: remaining,
                onTap: () => widget.onMeetupTap(meetup),
              ),
            );
          }),
        ],
        if (_monthMeetups.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            'Yaklaşan Etkinlikler',
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Only upcoming event cards
        ..._monthMeetups.map((meetup) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CalendarEventCard(
                meetup: meetup,
                onTap: () => widget.onMeetupTap(meetup),
              ),
            )),
      ],
    );
  }
}
