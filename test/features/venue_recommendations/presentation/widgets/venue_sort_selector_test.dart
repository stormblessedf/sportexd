import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/venue_filter_state.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/venue_sort_selector.dart';

void main() {
  Widget buildTestWidget({
    VenueSortOrder currentSort = VenueSortOrder.rating,
    ValueChanged<VenueSortOrder>? onSortChanged,
    bool hasLocationPermission = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: VenueSortSelector(
          currentSort: currentSort,
          onSortChanged: onSortChanged ?? (_) {},
          hasLocationPermission: hasLocationPermission,
        ),
      ),
    );
  }

  group('VenueSortSelector', () {
    testWidgets('displays all three sort options', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Puan'), findsOneWidget);
      expect(find.text('Mesafe'), findsOneWidget);
      expect(find.text('Yorum Sayısı'), findsOneWidget);
    });

    testWidgets('displays "Sırala:" label', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Sırala:'), findsOneWidget);
    });

    testWidgets('highlights the selected sort option', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        currentSort: VenueSortOrder.rating,
      ));

      final puanText = tester.widget<Text>(find.text('Puan'));
      expect(puanText.style?.fontWeight, FontWeight.w600);

      final mesafeText = tester.widget<Text>(find.text('Mesafe'));
      expect(mesafeText.style?.fontWeight, FontWeight.w400);

      final yorumText = tester.widget<Text>(find.text('Yorum Sayısı'));
      expect(yorumText.style?.fontWeight, FontWeight.w400);
    });

    testWidgets('highlights reviewCount when selected', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        currentSort: VenueSortOrder.reviewCount,
      ));

      final yorumText = tester.widget<Text>(find.text('Yorum Sayısı'));
      expect(yorumText.style?.fontWeight, FontWeight.w600);

      final puanText = tester.widget<Text>(find.text('Puan'));
      expect(puanText.style?.fontWeight, FontWeight.w400);
    });

    testWidgets('calls onSortChanged when rating chip is tapped',
        (tester) async {
      VenueSortOrder? selected;

      await tester.pumpWidget(buildTestWidget(
        currentSort: VenueSortOrder.reviewCount,
        onSortChanged: (order) => selected = order,
      ));

      await tester.tap(find.text('Puan'));
      expect(selected, VenueSortOrder.rating);
    });

    testWidgets('calls onSortChanged when reviewCount chip is tapped',
        (tester) async {
      VenueSortOrder? selected;

      await tester.pumpWidget(buildTestWidget(
        currentSort: VenueSortOrder.rating,
        onSortChanged: (order) => selected = order,
      ));

      await tester.tap(find.text('Yorum Sayısı'));
      expect(selected, VenueSortOrder.reviewCount);
    });

    testWidgets(
        'calls onSortChanged for distance when location permission granted',
        (tester) async {
      VenueSortOrder? selected;

      await tester.pumpWidget(buildTestWidget(
        currentSort: VenueSortOrder.rating,
        onSortChanged: (order) => selected = order,
        hasLocationPermission: true,
      ));

      await tester.tap(find.text('Mesafe'));
      expect(selected, VenueSortOrder.distance);
    });

    testWidgets(
        'does NOT call onSortChanged for distance without location permission',
        (tester) async {
      VenueSortOrder? selected;

      await tester.pumpWidget(buildTestWidget(
        currentSort: VenueSortOrder.rating,
        onSortChanged: (order) => selected = order,
        hasLocationPermission: false,
      ));

      await tester.tap(find.text('Mesafe'));
      await tester.pump();

      expect(selected, isNull);
    });

    testWidgets('shows snackbar when distance tapped without permission',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        hasLocationPermission: false,
      ));

      await tester.tap(find.text('Mesafe'));
      await tester.pump();

      expect(
        find.text('Mesafeye göre sıralama için konum izni gerekli'),
        findsOneWidget,
      );
    });

    testWidgets('does not show snackbar when distance tapped with permission',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        hasLocationPermission: true,
      ));

      await tester.tap(find.text('Mesafe'));
      await tester.pump();

      expect(
        find.text('Mesafeye göre sıralama için konum izni gerekli'),
        findsNothing,
      );
    });

    testWidgets('displays sort icons for each option', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.near_me_rounded), findsOneWidget);
      expect(find.byIcon(Icons.reviews_rounded), findsOneWidget);
    });
  });
}
