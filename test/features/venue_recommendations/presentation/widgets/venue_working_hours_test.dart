import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/venue_working_hours.dart';

Widget _buildTestWidget({
  List<String> weekdayHours = const [],
  bool isOpen = true,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: VenueWorkingHours(
          weekdayHours: weekdayHours,
          isOpen: isOpen,
        ),
      ),
    ),
  );
}

const _sampleHours = [
  'Pazartesi: 09:00–22:00',
  'Salı: 09:00–22:00',
  'Çarşamba: 09:00–22:00',
  'Perşembe: 09:00–22:00',
  'Cuma: 09:00–23:00',
  'Cumartesi: 10:00–23:00',
  'Pazar: 10:00–20:00',
];

void main() {
  group('VenueWorkingHours', () {
    testWidgets('shows section title with clock icon', (tester) async {
      await tester.pumpWidget(_buildTestWidget(weekdayHours: _sampleHours));

      expect(find.text('Çalışma Saatleri'), findsOneWidget);
      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
    });

    testWidgets('shows Açık badge when venue is open', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        weekdayHours: _sampleHours,
        isOpen: true,
      ));

      expect(find.text('Açık'), findsOneWidget);
      expect(find.text('Kapalı'), findsNothing);
    });

    testWidgets('shows Kapalı badge when venue is closed', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        weekdayHours: _sampleHours,
        isOpen: false,
      ));

      expect(find.text('Kapalı'), findsOneWidget);
      expect(find.text('Açık'), findsNothing);
    });

    testWidgets('shows empty message when weekdayHours is empty',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(weekdayHours: []));

      expect(find.text('Çalışma saatleri bilgisi yok'), findsOneWidget);
    });

    testWidgets('displays all 7 days with hours', (tester) async {
      await tester.pumpWidget(_buildTestWidget(weekdayHours: _sampleHours));

      expect(find.text('Pazartesi'), findsOneWidget);
      expect(find.text('Salı'), findsOneWidget);
      expect(find.text('Çarşamba'), findsOneWidget);
      expect(find.text('Perşembe'), findsOneWidget);
      expect(find.text('Cuma'), findsOneWidget);
      expect(find.text('Cumartesi'), findsOneWidget);
      expect(find.text('Pazar'), findsOneWidget);
      expect(find.text('09:00–22:00'), findsNWidgets(4));
      expect(find.text('09:00–23:00'), findsOneWidget);
      expect(find.text('10:00–23:00'), findsOneWidget);
      expect(find.text('10:00–20:00'), findsOneWidget);
    });

    testWidgets('handles entry without colon gracefully', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        weekdayHours: ['Closed all day'],
      ));

      expect(find.text('Closed all day'), findsOneWidget);
    });
  });
}
