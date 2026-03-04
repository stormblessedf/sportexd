import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/venue_photo_carousel.dart';

Widget _buildTestWidget({
  List<String> photoUrls = const [],
  MeetupType? sportType,
  double height = 250,
}) {
  return MaterialApp(
    home: Scaffold(
      body: VenuePhotoCarousel(
        photoUrls: photoUrls,
        sportType: sportType,
        height: height,
      ),
    ),
  );
}

void main() {
  group('VenuePhotoCarousel', () {
    testWidgets('shows sport emoji placeholder when no photos',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        sportType: MeetupType.football,
      ));

      expect(find.text('⚽'), findsOneWidget);
      expect(find.text('Fotoğraf yok'), findsOneWidget);
    });

    testWidgets('shows default emoji when sportType is null and no photos',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget());

      expect(find.text('🏅'), findsOneWidget);
      expect(find.text('Fotoğraf yok'), findsOneWidget);
    });

    testWidgets('shows basketball emoji for basketball type', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        sportType: MeetupType.basketball,
      ));

      expect(find.text('🏀'), findsOneWidget);
    });

    testWidgets('renders PageView when photos are provided', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        photoUrls: ['https://example.com/photo1.jpg'],
      ));

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Fotoğraf yok'), findsNothing);
    });

    testWidgets('does not show page indicator for single photo',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        photoUrls: ['https://example.com/photo1.jpg'],
      ));

      // With a single photo, no dot indicators should appear
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets('shows page indicator dots for multiple photos',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        photoUrls: [
          'https://example.com/photo1.jpg',
          'https://example.com/photo2.jpg',
          'https://example.com/photo3.jpg',
        ],
      ));

      // 3 photos = 3 indicator dots (AnimatedContainer)
      expect(find.byType(AnimatedContainer), findsNWidgets(3));
    });

    testWidgets('respects custom height', (tester) async {
      await tester.pumpWidget(_buildTestWidget(height: 300));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 300);
    });

    testWidgets('uses ClipRRect for rounded corners', (tester) async {
      await tester.pumpWidget(_buildTestWidget());

      expect(find.byType(ClipRRect), findsOneWidget);
    });
  });
}
