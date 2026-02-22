import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/features/profile/presentation/widgets/calendar_tab.dart';

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
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
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
      final thisMonth = DateTime(now.year, now.month, 15, 10, 0);
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

  group('onMeetupTap callback', () {
    testWidgets('invokes onMeetupTap when event card is tapped', (tester) async {
      final now = DateTime.now();
      final meetupDate = DateTime(now.year, now.month, 15, 10, 0);
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
}
