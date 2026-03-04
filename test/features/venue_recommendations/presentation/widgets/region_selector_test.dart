import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/location_data.dart';
import 'package:sporsal/core/models/place_autocomplete_result.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/region_selector.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kadikoy = PlaceAutocompleteResult(
  placeId: 'p1',
  description: 'Kadıköy, İstanbul',
  mainText: 'Kadıköy',
  secondaryText: 'İstanbul',
);

const _kartal = PlaceAutocompleteResult(
  placeId: 'p2',
  description: 'Kartal, İstanbul',
  mainText: 'Kartal',
  secondaryText: 'İstanbul',
);

const _kadikoyLocation = LocationData(
  latitude: 40.98,
  longitude: 29.03,
  name: 'Kadıköy',
  address: 'Kadıköy, İstanbul',
);

const _currentLocation = LocationData(
  latitude: 41.01,
  longitude: 28.97,
  address: 'Beyoğlu, İstanbul',
);

Widget _buildTestWidget({
  ValueChanged<LocationData>? onRegionSelected,
  ValueChanged<String>? onRegionNameChanged,
  AutocompleteFetcher? autocompleteFetcher,
  PlaceDetailFetcher? placeDetailFetcher,
  CurrentLocationFetcher? currentLocationFetcher,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: RegionSelector(
          onRegionSelected: onRegionSelected ?? (_) {},
          onRegionNameChanged: onRegionNameChanged,
          autocompleteFetcher: autocompleteFetcher ?? (_) async => [],
          placeDetailFetcher: placeDetailFetcher ?? (_) async => null,
          currentLocationFetcher: currentLocationFetcher ?? () async => null,
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RegionSelector', () {
    testWidgets('renders search field and current location button',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget());

      expect(find.text('Mevcut Konumumu Kullan'), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('current location button is above search field',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget());

      final buttonOffset =
          tester.getTopLeft(find.text('Mevcut Konumumu Kullan'));
      final fieldOffset = tester.getTopLeft(find.byType(TextField));

      expect(buttonOffset.dy, lessThan(fieldOffset.dy));
    });

    testWidgets('shows autocomplete suggestions after typing',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        autocompleteFetcher: (_) async => [_kadikoy, _kartal],
      ));

      await tester.enterText(find.byType(TextField), 'Ka');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Kadıköy'), findsOneWidget);
      expect(find.text('Kartal'), findsOneWidget);
    });

    testWidgets('calls onRegionSelected when suggestion is tapped',
        (tester) async {
      LocationData? selectedRegion;

      await tester.pumpWidget(_buildTestWidget(
        autocompleteFetcher: (_) async => [_kadikoy],
        placeDetailFetcher: (_) async => _kadikoyLocation,
        onRegionSelected: (loc) => selectedRegion = loc,
      ));

      await tester.enterText(find.byType(TextField), 'Ka');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kadıköy'));
      await tester.pumpAndSettle();

      expect(selectedRegion, isNotNull);
      expect(selectedRegion!.latitude, 40.98);
      expect(selectedRegion!.longitude, 29.03);
    });

    testWidgets('uses current location and calls onRegionSelected',
        (tester) async {
      LocationData? selectedRegion;

      await tester.pumpWidget(_buildTestWidget(
        currentLocationFetcher: () async => _currentLocation,
        onRegionSelected: (loc) => selectedRegion = loc,
      ));

      await tester.tap(find.text('Mevcut Konumumu Kullan'));
      await tester.pumpAndSettle();

      expect(selectedRegion, isNotNull);
      expect(selectedRegion!.latitude, 41.01);
    });

    testWidgets(
        'shows permission denied message when location returns null',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        currentLocationFetcher: () async => null,
      ));

      await tester.tap(find.text('Mevcut Konumumu Kullan'));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Konum izni reddedildi. Lütfen manuel olarak konum girin.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('does not fetch suggestions when query is too short',
        (tester) async {
      int callCount = 0;

      await tester.pumpWidget(_buildTestWidget(
        autocompleteFetcher: (_) async {
          callCount++;
          return [_kadikoy];
        },
      ));

      await tester.enterText(find.byType(TextField), 'K');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });

    testWidgets('clears suggestions when clear button is tapped',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        autocompleteFetcher: (_) async => [_kadikoy],
      ));

      await tester.enterText(find.byType(TextField), 'Ka');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Kadıköy'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Kadıköy'), findsNothing);
    });

    testWidgets('calls onRegionNameChanged when suggestion is selected',
        (tester) async {
      String? regionName;

      await tester.pumpWidget(_buildTestWidget(
        autocompleteFetcher: (_) async => [_kadikoy],
        placeDetailFetcher: (_) async => _kadikoyLocation,
        onRegionNameChanged: (name) => regionName = name,
      ));

      await tester.enterText(find.byType(TextField), 'Ka');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kadıköy'));
      await tester.pumpAndSettle();

      expect(regionName, 'Kadıköy');
    });
  });
}
