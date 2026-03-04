import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/core/services/meetup_service.dart';
import 'package:sporsal/features/profile/presentation/widgets/active_meetup_card.dart';
import 'package:sporsal/features/profile/presentation/widgets/calendar_tab.dart';
import '../../../../mock_firebase.dart';

MeetupModel _buildMeetup({
  required String id,
  required String title,
  required DateTime date,
  MeetupType type = MeetupType.football,
  int currentParticipants = 5,
  int maxParticipants = 10,
}) {
  return MeetupModel(
    id: id,
    title: title,
    description: 'Açıklama',
    imageUrl: '',
    type: type,
    date: date,
    locationName: 'Saha',
    locationAddress: 'Adres',
    organizerId: 'org-1',
    organizerName: 'Organizer',
    currentParticipants: currentParticipants,
    maxParticipants: maxParticipants,
  );
}

Widget _buildCalendarTab({
  required List<MeetupModel> meetups,
  Function(MeetupModel)? onMeetupTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: CalendarTab(
          meetups: meetups,
          onMeetupTap: onMeetupTap ?? (_) {},
          meetupService: MeetupService(),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    await initializeDateFormatting('tr');
  });

  group('Turkish weekday headers', () {
    testWidgets('displays all 7 Turkish weekday abbreviations', (tester) async {
      await tester.pumpWidget(_buildCalendarTab(meetups: []));

      for (final header in ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz']) {
        expect(find.text(header), findsOneWidget);
      }
    });
  });

  group('Month navigation', () {
    testWidgets('displays current month in Turkish', (tester) async {
      await tester.pumpWidget(_buildCalendarTab(meetups: []));

      final now = DateTime.now();
      const turkishMonths = [
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
      ];
      final expectedTitle = '${turkishMonths[now.month - 1]} ${now.year}';
      expect(find.text(expectedTitle), findsOneWidget);
    });

    testWidgets('navigates to previous month on left arrow tap', (tester) async {
      await tester.pumpWidget(_buildCalendarTab(meetups: []));

      final now = DateTime.now();
      const turkishMonths = [
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
      ];

      // Tap left arrow
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      final prevMonth = DateTime(now.year, now.month - 1);
      final expectedTitle = '${turkishMonths[prevMonth.month - 1]} ${prevMonth.year}';
      expect(find.text(expectedTitle), findsOneWidget);
    });

    testWidgets('navigates to next month on right arrow tap', (tester) async {
      await tester.pumpWidget(_buildCalendarTab(meetups: []));

      final now = DateTime.now();
      const turkishMonths = [
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
      ];

      // Tap right arrow
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      final nextMonth = DateTime(now.year, now.month + 1);
      final expectedTitle = '${turkishMonths[nextMonth.month - 1]} ${nextMonth.year}';
      expect(find.text(expectedTitle), findsOneWidget);
    });
  });

  group('Event filtering', () {
    testWidgets('shows event cards only for current month meetups', (tester) async {
      final now = DateTime.now();
      // Use a date guaranteed to be in the future within this month
      final thisMonth = now.add(const Duration(hours: 4));
      final nextMonth = DateTime(now.year, now.month + 1, 10, 14, 0);

      final meetups = [
        _buildMeetup(id: '1', title: 'Bu Ay Etkinlik', date: thisMonth),
        _buildMeetup(id: '2', title: 'Gelecek Ay Etkinlik', date: nextMonth),
      ];

      await tester.pumpWidget(_buildCalendarTab(meetups: meetups));

      expect(find.text('Bu Ay Etkinlik'), findsOneWidget);
      expect(find.text('Gelecek Ay Etkinlik'), findsNothing);
    });

    testWidgets('shows next month events after navigating forward', (tester) async {
      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1, 10, 14, 0);

      final meetups = [
        _buildMeetup(id: '1', title: 'Gelecek Ay Etkinlik', date: nextMonth),
      ];

      await tester.pumpWidget(_buildCalendarTab(meetups: meetups));

      // Initially not visible
      expect(find.text('Gelecek Ay Etkinlik'), findsNothing);

      // Navigate to next month
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.text('Gelecek Ay Etkinlik'), findsOneWidget);
    });
  });

  group('Active section visibility', () {
    testWidgets('shows "Şu An Aktif" title when active meetups exist',
        (tester) async {
      // A meetup that started 30 min ago → currently active (ends date+2h)
      final activeMeetup = _buildMeetup(
        id: 'active-1',
        title: 'Aktif Maç',
        date: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      await tester.pumpWidget(_buildCalendarTab(meetups: [activeMeetup]));

      expect(find.text('Şu An Aktif'), findsOneWidget);
    });

    testWidgets('hides "Şu An Aktif" section when no active meetups',
        (tester) async {
      // A future meetup — not active
      final futureMeetup = _buildMeetup(
        id: 'future-1',
        title: 'Gelecek Maç',
        date: DateTime.now().add(const Duration(hours: 4)),
      );

      await tester.pumpWidget(_buildCalendarTab(meetups: [futureMeetup]));

      expect(find.text('Şu An Aktif'), findsNothing);
    });

    testWidgets(
        'active section appears before upcoming events section',
        (tester) async {
      final activeMeetup = _buildMeetup(
        id: 'active-2',
        title: 'Aktif Etkinlik',
        date: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      final futureMeetup = _buildMeetup(
        id: 'future-2',
        title: 'Yaklaşan Etkinlik',
        date: DateTime.now().add(const Duration(hours: 4)),
      );

      await tester.pumpWidget(
        _buildCalendarTab(meetups: [activeMeetup, futureMeetup]),
      );

      // Both sections should be visible
      expect(find.text('Şu An Aktif'), findsOneWidget);
      expect(find.text('Yaklaşan Etkinlikler'), findsOneWidget);

      // "Şu An Aktif" should appear before "Yaklaşan Etkinlikler"
      final activeOffset = tester
          .getTopLeft(find.text('Şu An Aktif'))
          .dy;
      final upcomingOffset = tester
          .getTopLeft(find.text('Yaklaşan Etkinlikler'))
          .dy;
      expect(activeOffset, lessThan(upcomingOffset));
    });
  });

  group('onMeetupTap callback', () {
    testWidgets('invokes onMeetupTap when event card is tapped', (tester) async {
      final now = DateTime.now();
      // Use a date guaranteed to be in the future
      final meetupDate = now.add(const Duration(hours: 4));
      MeetupModel? tappedMeetup;

      final meetup = _buildMeetup(
        id: 'tap-test',
        title: 'Tıklanacak Etkinlik',
        date: meetupDate,
      );

      await tester.pumpWidget(_buildCalendarTab(
        meetups: [meetup],
        onMeetupTap: (m) => tappedMeetup = m,
      ));

      // Scroll to make the event card visible
      await tester.ensureVisible(find.text('Tıklanacak Etkinlik'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tıklanacak Etkinlik'));
      expect(tappedMeetup, isNotNull);
      expect(tappedMeetup!.id, 'tap-test');
    });
  });

  group('Edge cases', () {
    test('endDate null → effective end equals date + 2 hours', () {
      final service = MeetupService();
      final date = DateTime(2025, 6, 15, 14, 0);
      final meetup = _buildMeetup(id: 'no-end', title: 'Test', date: date);

      final effectiveEnd = service.getEffectiveEndDate(meetup);

      expect(effectiveEnd, date.add(const Duration(hours: 2)));
    });

    testWidgets('multiple active meetups render multiple ActiveMeetupCard widgets',
        (tester) async {
      final now = DateTime.now();
      final meetup1 = _buildMeetup(
        id: 'active-a',
        title: 'Aktif 1',
        date: now.subtract(const Duration(minutes: 30)),
      );
      final meetup2 = _buildMeetup(
        id: 'active-b',
        title: 'Aktif 2',
        date: now.subtract(const Duration(minutes: 45)),
      );

      await tester.pumpWidget(
        _buildCalendarTab(meetups: [meetup1, meetup2]),
      );

      expect(find.byType(ActiveMeetupCard), findsNWidgets(2));
    });
  });
}
