import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/core/models/venue_model.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/venue_card.dart';

VenueModel _makeVenue({
  String name = 'Test Venue',
  String address = 'Test Address, Istanbul',
  double rating = 4.2,
  int userRatingCount = 56,
  bool isOpen = true,
  List<String> photoUrls = const [],
  MeetupType? sportType,
}) {
  return VenueModel(
    placeId: 'place_1',
    name: name,
    address: address,
    rating: rating,
    userRatingCount: userRatingCount,
    isOpen: isOpen,
    photoUrls: photoUrls,
    sportType: sportType,
  );
}

Widget _buildTestWidget({
  VenueModel? venue,
  double? distanceKm,
  bool isFavorite = false,
  VoidCallback? onTap,
  VoidCallback? onFavoriteTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: VenueCard(
        venue: venue ?? _makeVenue(),
        distanceKm: distanceKm,
        isFavorite: isFavorite,
        onTap: onTap ?? () {},
        onFavoriteTap: onFavoriteTap,
      ),
    ),
  );
}

void main() {
  group('VenueCard', () {
    testWidgets('displays venue name and address', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        venue: _makeVenue(name: 'Halı Saha', address: 'Kadıköy, İstanbul'),
      ));

      expect(find.text('Halı Saha'), findsOneWidget);
      expect(find.text('Kadıköy, İstanbul'), findsOneWidget);
    });

    testWidgets('displays rating and review count', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        venue: _makeVenue(rating: 4.5, userRatingCount: 128),
      ));

      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('(128 yorum)'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('shows green Açık label when venue is open', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        venue: _makeVenue(isOpen: true),
      ));

      expect(find.text('Açık'), findsOneWidget);
      expect(find.text('Kapalı'), findsNothing);
    });

    testWidgets('shows red Kapalı label when venue is closed', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        venue: _makeVenue(isOpen: false),
      ));

      expect(find.text('Kapalı'), findsOneWidget);
      expect(find.text('Açık'), findsNothing);
    });

    testWidgets('shows distance in km when distanceKm >= 1', (tester) async {
      await tester.pumpWidget(_buildTestWidget(distanceKm: 2.3));

      expect(find.text('2.3 km'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('shows distance in meters when distanceKm < 1',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(distanceKm: 0.8));

      expect(find.text('800 m'), findsOneWidget);
    });

    testWidgets('hides distance when distanceKm is null', (tester) async {
      await tester.pumpWidget(_buildTestWidget(distanceKm: null));

      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    });

    testWidgets('shows sport emoji placeholder when no photos',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        venue: _makeVenue(photoUrls: [], sportType: MeetupType.football),
      ));

      expect(find.text('⚽'), findsOneWidget);
    });

    testWidgets('shows default emoji when sportType is null and no photos',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        venue: _makeVenue(photoUrls: [], sportType: null),
      ));

      expect(find.text('🏅'), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_buildTestWidget(
        onTap: () => tapped = true,
      ));

      await tester.tap(find.text('Test Venue'));
      expect(tapped, isTrue);
    });

    testWidgets('shows favorite icon when onFavoriteTap is provided',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        isFavorite: false,
        onFavoriteTap: () {},
      ));

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('shows filled heart when isFavorite is true', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        isFavorite: true,
        onFavoriteTap: () {},
      ));

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('hides favorite icon when onFavoriteTap is null',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(onFavoriteTap: null));

      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    });

    testWidgets('calls onFavoriteTap when heart icon is tapped',
        (tester) async {
      var favTapped = false;
      await tester.pumpWidget(_buildTestWidget(
        onFavoriteTap: () => favTapped = true,
      ));

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      expect(favTapped, isTrue);
    });
  });
}
