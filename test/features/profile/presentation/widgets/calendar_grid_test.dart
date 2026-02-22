import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/features/profile/presentation/widgets/calendar_grid.dart';
import 'package:sporsal/theme/app_theme.dart';

Widget _buildGrid({
  required int year,
  required int month,
  Set<int> eventDays = const {},
  DateTime? today,
}) {
  return MaterialApp(
    home: Scaffold(
      body: CalendarGrid(
        year: year,
        month: month,
        eventDays: eventDays,
        today: today ?? DateTime(2000, 1, 1),
      ),
    ),
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
    testWidgets('highlights today with green-tinted circular bg',
        (tester) async {
      final today = DateTime(2025, 6, 15);
      await tester.pumpWidget(
        _buildGrid(year: 2025, month: 6, today: today),
      );

      // Find the Container wrapping today's text
      final todayText = find.text('15');
      expect(todayText, findsOneWidget);

      // The parent Container of today should have a green-tinted decoration
      final container = tester.widget<Container>(
        find.ancestor(of: todayText, matching: find.byType(Container)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, AppTheme.primary.withValues(alpha: 0.1));
    });

    testWidgets('does not highlight non-today days with circular bg',
        (tester) async {
      final today = DateTime(2025, 6, 15);
      await tester.pumpWidget(
        _buildGrid(year: 2025, month: 6, today: today),
      );

      // Day 10 should not have a circular bg decoration
      final dayText = find.text('10');
      expect(dayText, findsOneWidget);

      final container = tester.widget<Container>(
        find.ancestor(of: dayText, matching: find.byType(Container)).first,
      );
      expect(container.decoration, isNull);
    });
  });

  group('CalendarGrid event day rendering', () {
    testWidgets('renders green dot for event days', (tester) async {
      await tester.pumpWidget(
        _buildGrid(year: 2025, month: 6, eventDays: {5, 20}),
      );

      // Find 4px green dot containers (event indicators)
      final greenDots = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final dec = widget.decoration as BoxDecoration;
          return dec.color == AppTheme.primary &&
              dec.shape == BoxShape.circle &&
              widget.constraints?.maxWidth == 4;
        }
        return false;
      });

      expect(greenDots, findsNWidgets(2));
    });

    testWidgets('today + event day combines both styles', (tester) async {
      final today = DateTime(2025, 6, 10);
      await tester.pumpWidget(
        _buildGrid(year: 2025, month: 6, eventDays: {10}, today: today),
      );

      final dayText = find.text('10');
      expect(dayText, findsOneWidget);

      // Should have circular bg (today)
      final bgContainer = tester.widget<Container>(
        find.ancestor(of: dayText, matching: find.byType(Container)).first,
      );
      final decoration = bgContainer.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);

      // Should also have a green dot (event)
      final greenDots = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final dec = widget.decoration as BoxDecoration;
          return dec.color == AppTheme.primary &&
              dec.shape == BoxShape.circle &&
              widget.constraints?.maxWidth == 4;
        }
        return false;
      });
      expect(greenDots, findsOneWidget);
    });
  });
}
