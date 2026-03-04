import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/features/profile/presentation/widgets/calendar_grid.dart';
import 'package:sporsal/theme/app_theme.dart';

Widget _buildGrid({
  required int year,
  required int month,
  Set<int> eventDays = const {},
  Set<int> pastEventDays = const {},
  Set<int> activeEventDays = const {},
  DateTime? today,
}) {
  return MaterialApp(
    home: Scaffold(
      body: CalendarGrid(
        year: year,
        month: month,
        eventDays: eventDays,
        pastEventDays: pastEventDays,
        activeEventDays: activeEventDays,
        today: today ?? DateTime(2000, 1, 1),
      ),
    ),
  );
}

/// Finds the Container wrapping a given day number text.
Container _findDayContainer(WidgetTester tester, String dayText) {
  final textFinder = find.text(dayText);
  return tester.widget<Container>(
    find.ancestor(of: textFinder, matching: find.byType(Container)).first,
  );
}

void main() {
  group('CalendarGrid day count', () {
    testWidgets('renders 31 days for January', (tester) async {
      await tester.pumpWidget(_buildGrid(year: 2025, month: 1));
      expect(find.text('31'), findsOneWidget);
      expect(find.text('32'), findsNothing);
    });

    testWidgets('renders 28 days for February non-leap year', (tester) async {
      await tester.pumpWidget(_buildGrid(year: 2025, month: 2));
      expect(find.text('28'), findsOneWidget);
      expect(find.text('29'), findsNothing);
    });

    testWidgets('renders 29 days for February leap year', (tester) async {
      await tester.pumpWidget(_buildGrid(year: 2024, month: 2));
      expect(find.text('29'), findsOneWidget);
      expect(find.text('30'), findsNothing);
    });

    testWidgets('renders 30 days for April', (tester) async {
      await tester.pumpWidget(_buildGrid(year: 2025, month: 4));
      expect(find.text('30'), findsOneWidget);
      expect(find.text('31'), findsNothing);
    });
  });

  group('CalendarGrid today highlighting', () {
    testWidgets('highlights today with primary bg and white text',
        (tester) async {
      final today = DateTime(2025, 6, 15);
      await tester.pumpWidget(
        _buildGrid(year: 2025, month: 6, today: today),
      );

      final container = _findDayContainer(tester, '15');
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppTheme.primary);
    });

    testWidgets('non-today days have transparent bg', (tester) async {
      final today = DateTime(2025, 6, 15);
      await tester.pumpWidget(
        _buildGrid(year: 2025, month: 6, today: today),
      );

      final container = _findDayContainer(tester, '10');
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.transparent);
    });
  });

  group('CalendarGrid event day rendering', () {
    testWidgets('upcoming event days have blue bg', (tester) async {
      await tester.pumpWidget(
        _buildGrid(year: 2025, month: 6, eventDays: {5, 20}),
      );

      final container5 = _findDayContainer(tester, '5');
      final dec5 = container5.decoration as BoxDecoration;
      expect(dec5.color, const Color(0xFF2196F3));

      final container20 = _findDayContainer(tester, '20');
      final dec20 = container20.decoration as BoxDecoration;
      expect(dec20.color, const Color(0xFF2196F3));
    });

    testWidgets('past event days have light blue bg', (tester) async {
      await tester.pumpWidget(
        _buildGrid(year: 2025, month: 6, pastEventDays: {3}),
      );

      final container = _findDayContainer(tester, '3');
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFBBDEFB));
    });

    testWidgets('today takes priority over event day', (tester) async {
      final today = DateTime(2025, 6, 10);
      await tester.pumpWidget(
        _buildGrid(year: 2025, month: 6, eventDays: {10}, today: today),
      );

      final container = _findDayContainer(tester, '10');
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppTheme.primary);
    });
  });

  group('CalendarGrid active event day rendering', () {
    testWidgets('active event days have green bg with white text',
        (tester) async {
      await tester.pumpWidget(
        _buildGrid(year: 2025, month: 6, activeEventDays: {12}),
      );

      final container = _findDayContainer(tester, '12');
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF4CAF50));
    });

    testWidgets('today takes priority over active event day', (tester) async {
      final today = DateTime(2025, 6, 12);
      await tester.pumpWidget(
        _buildGrid(
          year: 2025,
          month: 6,
          activeEventDays: {12},
          today: today,
        ),
      );

      final container = _findDayContainer(tester, '12');
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppTheme.primary);
    });

    testWidgets('active event takes priority over upcoming event',
        (tester) async {
      await tester.pumpWidget(
        _buildGrid(
          year: 2025,
          month: 6,
          eventDays: {15},
          activeEventDays: {15},
        ),
      );

      final container = _findDayContainer(tester, '15');
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF4CAF50));
    });

    testWidgets('active event takes priority over past event', (tester) async {
      await tester.pumpWidget(
        _buildGrid(
          year: 2025,
          month: 6,
          pastEventDays: {8},
          activeEventDays: {8},
        ),
      );

      final container = _findDayContainer(tester, '8');
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF4CAF50));
    });

    testWidgets('non-active days are unaffected by activeEventDays',
        (tester) async {
      await tester.pumpWidget(
        _buildGrid(year: 2025, month: 6, activeEventDays: {12}),
      );

      final container = _findDayContainer(tester, '10');
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.transparent);
    });
  });
}
