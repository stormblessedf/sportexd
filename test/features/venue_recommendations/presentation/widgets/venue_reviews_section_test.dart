import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/venue_model.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/venue_reviews_section.dart';

Widget _buildTestWidget({
  List<VenueReview> reviews = const [],
  double overallRating = 0.0,
  int totalReviewCount = 0,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: VenueReviewsSection(
          reviews: reviews,
          overallRating: overallRating,
          totalReviewCount: totalReviewCount,
        ),
      ),
    ),
  );
}

const _sampleReviews = [
  VenueReview(
    authorName: 'Ahmet Yılmaz',
    rating: 5.0,
    text: 'Harika bir mekan, kesinlikle tavsiye ederim!',
    relativeTime: '2 ay önce',
  ),
  VenueReview(
    authorName: 'Mehmet Kaya',
    rating: 3.5,
    text: 'Fena değil ama biraz pahalı.',
    relativeTime: '1 hafta önce',
  ),
  VenueReview(
    authorName: '',
    rating: 4.0,
    text: 'Güzel tesis.',
    relativeTime: '',
  ),
];

void main() {
  group('VenueReviewsSection', () {
    testWidgets('shows section title with chat icon', (tester) async {
      await tester.pumpWidget(_buildTestWidget(reviews: _sampleReviews));

      expect(find.text('Yorumlar'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    });

    testWidgets('shows overall rating when totalReviewCount > 0',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        reviews: _sampleReviews,
        overallRating: 4.3,
        totalReviewCount: 128,
      ));

      expect(find.text('4.3/5'), findsOneWidget);
      expect(find.text('(128 yorum)'), findsOneWidget);
    });

    testWidgets('hides overall rating when totalReviewCount is 0',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        reviews: [],
        overallRating: 0.0,
        totalReviewCount: 0,
      ));

      expect(find.text('/5'), findsNothing);
      expect(find.text('(0 yorum)'), findsNothing);
    });

    testWidgets('shows empty message when reviews list is empty',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(reviews: []));

      expect(find.text('Henüz yorum yok'), findsOneWidget);
    });

    testWidgets('displays author names for each review', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        reviews: _sampleReviews,
        overallRating: 4.2,
        totalReviewCount: 3,
      ));

      expect(find.text('Ahmet Yılmaz'), findsOneWidget);
      expect(find.text('Mehmet Kaya'), findsOneWidget);
      // Empty author name falls back to 'Anonim'
      expect(find.text('Anonim'), findsOneWidget);
    });

    testWidgets('displays relative time for reviews', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        reviews: _sampleReviews,
        overallRating: 4.2,
        totalReviewCount: 3,
      ));

      expect(find.text('2 ay önce'), findsOneWidget);
      expect(find.text('1 hafta önce'), findsOneWidget);
    });

    testWidgets('displays review text', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        reviews: _sampleReviews,
        overallRating: 4.2,
        totalReviewCount: 3,
      ));

      expect(find.text('Harika bir mekan, kesinlikle tavsiye ederim!'),
          findsOneWidget);
      expect(find.text('Fena değil ama biraz pahalı.'), findsOneWidget);
      expect(find.text('Güzel tesis.'), findsOneWidget);
    });

    testWidgets('shows star icons for ratings', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        reviews: const [
          VenueReview(authorName: 'Test', rating: 5.0, text: 'Great'),
        ],
        overallRating: 5.0,
        totalReviewCount: 1,
      ));

      // 5 filled stars for the review + 1 star in header = 6 star_rounded icons
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(6));
      expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
    });

    testWidgets('shows half star for fractional ratings', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        reviews: const [
          VenueReview(authorName: 'Test', rating: 3.5, text: 'OK'),
        ],
        overallRating: 3.5,
        totalReviewCount: 1,
      ));

      expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
    });

    testWidgets('shows dividers between reviews but not after last',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        reviews: _sampleReviews,
        overallRating: 4.2,
        totalReviewCount: 3,
      ));

      // 3 reviews → 2 dividers
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });
}
