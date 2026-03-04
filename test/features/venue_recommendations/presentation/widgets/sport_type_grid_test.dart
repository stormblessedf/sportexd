import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/sport_type_grid.dart';

void main() {
  Widget buildTestWidget({
    MeetupType? selectedType,
    ValueChanged<MeetupType>? onTypeSelected,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SportTypeGrid(
            selectedType: selectedType,
            onTypeSelected: onTypeSelected ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('SportTypeGrid', () {
    testWidgets('displays all MeetupType values', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      for (final type in MeetupType.values) {
        expect(find.text(type.displayName), findsOneWidget);
      }
    });

    testWidgets('shows popular types first in grid order', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Verify popular types appear before non-popular types
      // by checking the vertical position of the first popular vs first non-popular
      final futbolFinder = find.text('Futbol');
      final yogaFinder = find.text('Yoga');

      final futbolOffset = tester.getTopLeft(futbolFinder);
      final yogaOffset = tester.getTopLeft(yogaFinder);

      // Futbol (popular) should be above or at same level as Yoga (non-popular)
      expect(futbolOffset.dy, lessThanOrEqualTo(yogaOffset.dy));
    });

    testWidgets('calls onTypeSelected when a type is tapped', (tester) async {
      MeetupType? tappedType;

      await tester.pumpWidget(buildTestWidget(
        onTypeSelected: (type) => tappedType = type,
      ));

      await tester.tap(find.text('Futbol'));
      expect(tappedType, MeetupType.football);
    });

    testWidgets('visually highlights the selected type', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        selectedType: MeetupType.basketball,
      ));

      // The selected type text should use bold weight (w600)
      final basketbolText = tester.widget<Text>(find.text('Basketbol'));
      final style = basketbolText.style;
      expect(style?.fontWeight, FontWeight.w600);
    });

    testWidgets('non-selected types are not highlighted', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        selectedType: MeetupType.basketball,
      ));

      // A non-selected type should use normal weight (w400)
      final futbolText = tester.widget<Text>(find.text('Futbol'));
      final style = futbolText.style;
      expect(style?.fontWeight, FontWeight.w400);
    });

    testWidgets('supports single selection - only one type highlighted',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        selectedType: MeetupType.tennis,
      ));

      // Only tennis should be bold
      final tenisText = tester.widget<Text>(find.text('Tenis'));
      expect(tenisText.style?.fontWeight, FontWeight.w600);

      // Others should not be bold
      final futbolText = tester.widget<Text>(find.text('Futbol'));
      expect(futbolText.style?.fontWeight, FontWeight.w400);

      final yogaText = tester.widget<Text>(find.text('Yoga'));
      expect(yogaText.style?.fontWeight, FontWeight.w400);
    });

    testWidgets('displays emoji for each sport type', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Check a few known emojis
      expect(find.text('⚽'), findsOneWidget);
      expect(find.text('🏀'), findsOneWidget);
      expect(find.text('🎾'), findsOneWidget);
      expect(find.text('🏊'), findsOneWidget);
      expect(find.text('💪'), findsOneWidget);
    });

    testWidgets('renders with no selection (null selectedType)',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(selectedType: null));

      // All types should use normal weight when nothing is selected
      for (final type in MeetupType.values) {
        final text = tester.widget<Text>(find.text(type.displayName));
        expect(text.style?.fontWeight, FontWeight.w400);
      }
    });
  });
}
