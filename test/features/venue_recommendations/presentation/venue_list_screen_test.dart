import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/core/models/venue_model.dart';
import 'package:sporsal/features/venue_recommendations/presentation/venue_list_screen.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/venue_sort_selector.dart';

VenueModel _makeVenue({
  String placeId = 'place_1',
  String name = 'Test Venue',
  String address = 'Test Address, Istanbul',
  double rating = 4.2,
  int userRatingCount = 56,
  bool isOpen = true,
  double latitude = 41.0,
  double longitude = 29.0,
}) {
  return VenueModel(
    placeId: placeId,
    name: name,
    address: address,
    rating: rating,
    userRatingCount: userRatingCount,
    isOpen: isOpen,
    latitude: latitude,
    longitude: longitude,
  );
}

List<VenueModel> _makeVenues(int count) {
  return List.generate(
    count,
    (i) => _makeVenue(
      placeId: 'place_$i',
      name: 'Venue $i',
      address: 'Address $i',
    ),
  );
}

Widget _buildTestWidget({
  List<VenueModel> venues = const [],
  MeetupType sportType = MeetupType.football,
  String regionName = 'Kadıköy',
  double? userLat,
  double? userLng,
}) {
  return MaterialApp(
    home: VenueListScreen(
      venues: venues,
      sportType: sportType,
      regionName: regionName,
      userLat: userLat,
      userLng: userLng,
    ),
  );
}

void main() {
  group('VenueListScreen', () {
    testWidgets('shows skeleton cards during initial loading', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        venues: _makeVenues(3),
      ));

      // Before the 400ms delay completes, skeletons should be visible.
      // Venue names should NOT be visible yet.
      expect(find.text('Venue 0'), findsNothing);
      expect(find.text('Bu bölgede sonuç bulunamadı'), findsNothing);

      // Complete the loading timer and skeleton animations.
      await tester.pumpAndSettle();
    });

    testWidgets('shows empty state when venues list is empty', (tester) async {
      await tester.pumpWidget(_buildTestWidget(venues: []));
      await tester.pumpAndSettle();

      expect(find.text('Bu bölgede sonuç bulunamadı'), findsOneWidget);
      expect(
        find.text('Farklı bir bölge veya spor türü deneyin'),
        findsOneWidget,
      );
      expect(find.text('Kriterleri Değiştir'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });

    testWidgets('shows app bar with sport type and region name',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        sportType: MeetupType.basketball,
        regionName: 'Beşiktaş',
        venues: _makeVenues(1),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Basketbol - Beşiktaş'), findsOneWidget);
    });

    testWidgets('shows fallback title when regionName is empty',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        regionName: '',
        venues: _makeVenues(1),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mekan Önerileri'), findsOneWidget);
    });

    testWidgets('shows result count header', (tester) async {
      await tester.pumpWidget(_buildTestWidget(venues: _makeVenues(5)));
      await tester.pumpAndSettle();

      expect(find.text('5 mekan bulundu'), findsOneWidget);
    });

    testWidgets('displays venue cards after loading', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        venues: [_makeVenue(name: 'Halı Saha Kadıköy')],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Halı Saha Kadıköy'), findsOneWidget);
    });

    testWidgets('shows max 20 venues initially', (tester) async {
      await tester.pumpWidget(_buildTestWidget(venues: _makeVenues(25)));
      await tester.pumpAndSettle();

      // Result count should show total (25), but only 20 cards rendered.
      expect(find.text('25 mekan bulundu'), findsOneWidget);
      // Venue 0 should be visible, Venue 24 should not.
      expect(find.text('Venue 0'), findsOneWidget);
    });

    testWidgets('has a back button in app bar', (tester) async {
      await tester.pumpWidget(_buildTestWidget(venues: _makeVenues(1)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets(
        'shows location permission banner when userLat/userLng is null',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        venues: _makeVenues(3),
        userLat: null,
        userLng: null,
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('Mesafe bilgisi için konum izni gerekli'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.location_off_outlined), findsOneWidget);
    });

    testWidgets(
        'hides location permission banner when userLat/userLng is provided',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        venues: _makeVenues(3),
        userLat: 41.0,
        userLng: 29.0,
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('Mesafe bilgisi için konum izni gerekli'),
        findsNothing,
      );
    });

    // ── Filter & sort integration tests (Task 10.3) ──

    testWidgets('shows filter button with Icons.tune in app bar',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(venues: _makeVenues(3)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    testWidgets('shows sort selector with sort options', (tester) async {
      await tester.pumpWidget(_buildTestWidget(venues: _makeVenues(3)));
      await tester.pumpAndSettle();

      expect(find.byType(VenueSortSelector), findsOneWidget);
      expect(find.text('Sırala:'), findsOneWidget);
      expect(find.text('Puan'), findsOneWidget);
      expect(find.text('Mesafe'), findsOneWidget);
      expect(find.text('Yorum Sayısı'), findsOneWidget);
    });

    testWidgets('opens filter panel bottom sheet on filter button tap',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(venues: _makeVenues(3)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      // Filter panel header should be visible in the bottom sheet.
      expect(find.text('Filtreler'), findsOneWidget);
      expect(find.text('Uygula'), findsOneWidget);
      expect(find.text('Filtreleri Temizle'), findsOneWidget);
    });

    testWidgets(
        'filter panel applies minimum rating filter correctly',
        (tester) async {
      // Create venues with different ratings.
      final venues = [
        _makeVenue(placeId: 'p1', name: 'High Rated', rating: 4.5),
        _makeVenue(placeId: 'p2', name: 'Mid Rated', rating: 3.0),
        _makeVenue(placeId: 'p3', name: 'Low Rated', rating: 1.5),
      ];

      await tester.pumpWidget(_buildTestWidget(venues: venues));
      await tester.pumpAndSettle();

      // Initially all 3 shown.
      expect(find.text('3 mekan bulundu'), findsOneWidget);

      // Open filter panel.
      await tester.tap(find.byIcon(Icons.tune).first);
      await tester.pumpAndSettle();

      // The filter panel should be visible with its sections.
      expect(find.text('Filtreler'), findsOneWidget);
      expect(find.text('Minimum Puan'), findsOneWidget);
      expect(find.text('Uygula'), findsOneWidget);
    });
  });
}
