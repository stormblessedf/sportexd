import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/features/profile/presentation/widgets/active_meetup_card.dart';

import '../../../../helpers/test_builders.dart';

void main() {
  MeetupModel buildActiveMeetup({
    MeetupType type = MeetupType.football,
    String locationName = 'Test Saha',
  }) {
    return TestMeetupBuilder()
        .withType(type)
        .withLocationName(locationName)
        .withDate(DateTime.now().subtract(const Duration(minutes: 30)))
        .build();
  }

  Widget buildWidget({
    required MeetupModel meetup,
    Duration remainingTime = const Duration(hours: 1, minutes: 23),
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ActiveMeetupCard(
          meetup: meetup,
          remainingTime: remainingTime,
          onTap: onTap,
        ),
      ),
    );
  }

  group('ActiveMeetupCard', () {
    testWidgets('displays "CANLI" text', (tester) async {
      final meetup = buildActiveMeetup();
      await tester.pumpWidget(buildWidget(meetup: meetup));

      expect(find.text('CANLI'), findsOneWidget);
    });

    testWidgets('has green-tinted background and border decoration',
        (tester) async {
      final meetup = buildActiveMeetup();
      await tester.pumpWidget(buildWidget(meetup: meetup));

      // Find the outer Container with BoxDecoration
      final containers = tester.widgetList<Container>(find.byType(Container));
      final greenContainer = containers.where((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration) {
          final hasGreenBg =
              dec.color == const Color(0xFF4CAF50).withValues(alpha: 0.08);
          final hasGreenBorder = dec.border is Border &&
              (dec.border as Border).top.color ==
                  const Color(0xFF4CAF50).withValues(alpha: 0.3);
          return hasGreenBg && hasGreenBorder;
        }
        return false;
      });

      expect(greenContainer, isNotEmpty,
          reason: 'Card should have green background and green border');
    });

    testWidgets('invokes onTap callback when tapped', (tester) async {
      var tapped = false;
      final meetup = buildActiveMeetup();

      await tester.pumpWidget(
        buildWidget(meetup: meetup, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(GestureDetector).first);
      expect(tapped, isTrue);
    });

    testWidgets('formats remaining time with hours and minutes',
        (tester) async {
      final meetup = buildActiveMeetup();
      await tester.pumpWidget(
        buildWidget(
          meetup: meetup,
          remainingTime: const Duration(hours: 1, minutes: 23),
        ),
      );

      expect(find.text('1s 23dk kaldı'), findsOneWidget);
    });

    testWidgets('formats remaining time with minutes only', (tester) async {
      final meetup = buildActiveMeetup();
      await tester.pumpWidget(
        buildWidget(
          meetup: meetup,
          remainingTime: const Duration(minutes: 45),
        ),
      );

      expect(find.text('45dk kaldı'), findsOneWidget);
    });

    testWidgets('displays sport type and location', (tester) async {
      final meetup = buildActiveMeetup(
        type: MeetupType.tennis,
        locationName: 'Dalyan Tenis Kulübü',
      );
      await tester.pumpWidget(buildWidget(meetup: meetup));

      expect(find.text('Tenis'), findsAtLeastNWidgets(1));
      expect(find.text('Dalyan Tenis Kulübü'), findsOneWidget);
    });

    testWidgets('shows 0dk kaldı for negative remaining time',
        (tester) async {
      final meetup = buildActiveMeetup();
      await tester.pumpWidget(
        buildWidget(
          meetup: meetup,
          remainingTime: const Duration(minutes: -5),
        ),
      );

      expect(find.text('0dk kaldı'), findsOneWidget);
    });
  });
}
