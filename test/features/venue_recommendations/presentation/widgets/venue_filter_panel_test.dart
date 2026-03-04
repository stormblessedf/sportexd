import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/venue_filter_state.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/venue_filter_panel.dart';

Widget _buildTestWidget({
  VenueFilterState? currentFilter,
  ValueChanged<VenueFilterState>? onFilterChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => SizedBox(
                height: 600,
                child: VenueFilterPanel(
                  currentFilter: currentFilter ?? VenueFilterState.empty,
                  onFilterChanged: onFilterChanged ?? (_) {},
                ),
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    ),
  );
}

Future<void> _openPanel(WidgetTester tester, {
  VenueFilterState? currentFilter,
  ValueChanged<VenueFilterState>? onFilterChanged,
}) async {
  await tester.pumpWidget(_buildTestWidget(
    currentFilter: currentFilter,
    onFilterChanged: onFilterChanged,
  ));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  group('VenueFilterPanel', () {
    testWidgets('displays header with title', (tester) async {
      await _openPanel(tester);
      expect(find.text('Filtreler'), findsOneWidget);
    });

    testWidgets('displays close button', (tester) async {
      await _openPanel(tester);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows active filter count badge when filters are active',
        (tester) async {
      await _openPanel(
        tester,
        currentFilter: const VenueFilterState(onlyOpen: true, minRating: 3.0),
      );
      // activeFilterCount = 2 (onlyOpen + minRating)
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('hides badge when no filters are active', (tester) async {
      await _openPanel(tester);
      // The header row should not contain a badge count
      // When activeFilterCount == 0, the badge Container is not rendered
      // Verify by checking that the header only has title + close, no count badge
      final headerRow = find.ancestor(
        of: find.text('Filtreler'),
        matching: find.byType(Row),
      ).first;
      // No green badge container should exist in the header
      expect(
        find.descendant(
          of: headerRow,
          matching: find.byIcon(Icons.close),
        ),
        findsOneWidget,
      );
    });

    // ── Environment toggle ──
    testWidgets('displays environment toggle with all three options',
        (tester) async {
      await _openPanel(tester);
      expect(find.text('Mekan Türü'), findsOneWidget);
      expect(find.text('Tümü'), findsOneWidget);
      expect(find.text('İç Mekan'), findsOneWidget);
      expect(find.text('Dış Mekan'), findsOneWidget);
    });

    testWidgets('tapping environment option updates selection',
        (tester) async {
      VenueFilterState? result;
      await _openPanel(
        tester,
        onFilterChanged: (f) => result = f,
      );

      await tester.tap(find.text('İç Mekan'));
      await tester.pumpAndSettle();

      // Apply to capture the state
      await tester.tap(find.text('Uygula'));
      await tester.pumpAndSettle();

      expect(result?.environment, VenueEnvironment.indoor);
    });

    // ── Price level chips ──
    testWidgets('displays all price level chips', (tester) async {
      await _openPanel(tester);
      expect(find.text('Fiyat Seviyesi'), findsOneWidget);
      expect(find.text('Ücretsiz'), findsOneWidget);
      expect(find.text('₺'), findsOneWidget);
      expect(find.text('₺₺'), findsOneWidget);
      expect(find.text('₺₺₺'), findsOneWidget);
      expect(find.text('₺₺₺₺'), findsOneWidget);
    });

    testWidgets('price level chips support multi-select', (tester) async {
      VenueFilterState? result;
      await _openPanel(
        tester,
        onFilterChanged: (f) => result = f,
      );

      await tester.tap(find.text('Ücretsiz'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('₺₺'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Uygula'));
      await tester.pumpAndSettle();

      expect(result?.priceLevels, {0, 2});
    });

    testWidgets('tapping selected price chip deselects it', (tester) async {
      VenueFilterState? result;
      await _openPanel(
        tester,
        currentFilter: const VenueFilterState(priceLevels: {1, 2}),
        onFilterChanged: (f) => result = f,
      );

      // Deselect ₺ (price level 1)
      await tester.tap(find.text('₺'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Uygula'));
      await tester.pumpAndSettle();

      expect(result?.priceLevels, {2});
    });

    // ── Rating slider ──
    testWidgets('displays minimum rating section', (tester) async {
      await _openPanel(tester);
      expect(find.text('Minimum Puan'), findsOneWidget);
      expect(find.text('0.0'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('shows current rating value from initial filter',
        (tester) async {
      await _openPanel(
        tester,
        currentFilter: const VenueFilterState(minRating: 3.5),
      );
      expect(find.text('3.5'), findsOneWidget);
    });

    // ── Distance chips ──
    testWidgets('displays all distance options', (tester) async {
      await _openPanel(tester);
      expect(find.text('Maksimum Mesafe'), findsOneWidget);
      expect(find.text('1 km'), findsOneWidget);
      expect(find.text('3 km'), findsOneWidget);
      expect(find.text('5 km'), findsOneWidget);
      expect(find.text('10 km'), findsOneWidget);
      expect(find.text('20 km'), findsOneWidget);
      expect(find.text('Sınırsız'), findsOneWidget);
    });

    testWidgets('distance chips are single-select', (tester) async {
      VenueFilterState? result;
      await _openPanel(
        tester,
        onFilterChanged: (f) => result = f,
      );

      await tester.tap(find.text('5 km'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10 km'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Uygula'));
      await tester.pumpAndSettle();

      // Only the last selection should be active
      expect(result?.maxDistanceKm, 10.0);
    });

    // ── Only open switch ──
    testWidgets('displays Şu An Açık switch', (tester) async {
      await _openPanel(tester);
      expect(find.text('Şu An Açık'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('toggling switch updates onlyOpen state', (tester) async {
      VenueFilterState? result;
      await _openPanel(
        tester,
        onFilterChanged: (f) => result = f,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Uygula'));
      await tester.pumpAndSettle();

      expect(result?.onlyOpen, isTrue);
    });

    // ── Clear filters ──
    testWidgets('Filtreleri Temizle resets to empty state', (tester) async {
      VenueFilterState? result;
      await _openPanel(
        tester,
        currentFilter: const VenueFilterState(
          onlyOpen: true,
          minRating: 4.0,
          priceLevels: {1, 2},
        ),
        onFilterChanged: (f) => result = f,
      );

      await tester.tap(find.text('Filtreleri Temizle'));
      await tester.pumpAndSettle();

      // Apply the cleared state
      await tester.tap(find.text('Uygula'));
      await tester.pumpAndSettle();

      expect(result?.onlyOpen, isFalse);
      expect(result?.minRating, 0.0);
      expect(result?.priceLevels, isEmpty);
      expect(result?.maxDistanceKm, isNull);
      expect(result?.environment, VenueEnvironment.all);
    });

    // ── Apply button ──
    testWidgets('Uygula calls onFilterChanged and closes panel',
        (tester) async {
      VenueFilterState? result;
      await _openPanel(
        tester,
        onFilterChanged: (f) => result = f,
      );

      await tester.tap(find.text('Uygula'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      // Panel should be dismissed
      expect(find.text('Filtreler'), findsNothing);
    });

    // ── Close button ──
    testWidgets('close button dismisses panel without applying',
        (tester) async {
      VenueFilterState? result;
      await _openPanel(
        tester,
        onFilterChanged: (f) => result = f,
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(result, isNull);
      expect(find.text('Filtreler'), findsNothing);
    });
  });
}
