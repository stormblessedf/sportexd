import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/features/profile/presentation/widgets/calendar_event_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
  });

  MeetupModel buildMeetup({
    bool isFull = false,
    DateTime? date,
    MeetupType type = MeetupType.football,
    int currentParticipants = 5,
    int maxParticipants = 10,
  }) {
    return MeetupModel(
      id: 'test-1',
      title: 'Test Etkinlik',
      description: 'Açıklama',
      imageUrl: '',
      type: type,
      date: date ?? DateTime.now().add(const Duration(days: 1)),
      locationName: 'Saha',
      locationAddress: 'Adres',
      organizerId: 'org-1',
      organizerName: 'Organizer',
      currentParticipants: currentParticipants,
      maxParticipants: maxParticipants,
      isFull: isFull,
    );
  }

  testWidgets('shows amber dot for full meetup', (tester) async {
    final meetup = buildMeetup(isFull: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarEventCard(meetup: meetup),
        ),
      ),
    );

    // Find the status dot container (8x8 circle)
    final dotFinder = find.byWidgetPredicate((widget) =>
        widget is Container &&
        widget.constraints?.maxWidth == 8 &&
        widget.constraints?.maxHeight == 8);

    // Verify the dot exists by checking decoration
    final containers = tester.widgetList<Container>(find.byType(Container));
    final dotContainer = containers.where((c) {
      final dec = c.decoration;
      if (dec is BoxDecoration && dec.shape == BoxShape.circle) {
        return dec.color == const Color(0xFFFF9800);
      }
      return false;
    });
    expect(dotContainer, isNotEmpty);
  });

  testWidgets('shows blue dot for upcoming meetup', (tester) async {
    final meetup = buildMeetup(
      isFull: false,
      date: DateTime.now().add(const Duration(days: 7)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarEventCard(meetup: meetup),
        ),
      ),
    );

    final containers = tester.widgetList<Container>(find.byType(Container));
    final dotContainer = containers.where((c) {
      final dec = c.decoration;
      if (dec is BoxDecoration && dec.shape == BoxShape.circle) {
        return dec.color == const Color(0xFF2196F3);
      }
      return false;
    });
    expect(dotContainer, isNotEmpty);
  });

  testWidgets('shows green dot for past meetup', (tester) async {
    final meetup = buildMeetup(
      isFull: false,
      date: DateTime.now().subtract(const Duration(days: 1)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarEventCard(meetup: meetup),
        ),
      ),
    );

    final containers = tester.widgetList<Container>(find.byType(Container));
    final dotContainer = containers.where((c) {
      final dec = c.decoration;
      if (dec is BoxDecoration && dec.shape == BoxShape.circle) {
        return dec.color == const Color(0xFF4CAF50);
      }
      return false;
    });
    expect(dotContainer, isNotEmpty);
  });

  testWidgets('renders title and sport type tag', (tester) async {
    final meetup = buildMeetup(type: MeetupType.tennis);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarEventCard(meetup: meetup),
        ),
      ),
    );

    expect(find.text('Test Etkinlik'), findsOneWidget);
    expect(find.text('Tenis'), findsOneWidget);
  });

  testWidgets('renders metadata with participant count', (tester) async {
    final meetup = buildMeetup(
      currentParticipants: 3,
      maxParticipants: 8,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarEventCard(meetup: meetup),
        ),
      ),
    );

    expect(find.textContaining('3/8 kişi'), findsOneWidget);
  });

  testWidgets('invokes onTap callback', (tester) async {
    var tapped = false;
    final meetup = buildMeetup();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarEventCard(
            meetup: meetup,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Test Etkinlik'));
    expect(tapped, isTrue);
  });
}
