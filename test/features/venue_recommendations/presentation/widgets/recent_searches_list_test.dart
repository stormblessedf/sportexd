import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/core/models/search_query_model.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/recent_searches_list.dart';

/// Sample searches for testing.
List<SearchQueryModel> _sampleSearches() {
  final now = DateTime.now();
  return [
    SearchQueryModel(
      id: '1',
      sportType: MeetupType.football,
      regionName: 'Kadıköy, İstanbul',
      latitude: 40.98,
      longitude: 29.03,
      searchedAt: now,
    ),
    SearchQueryModel(
      id: '2',
      sportType: MeetupType.basketball,
      regionName: 'Beşiktaş, İstanbul',
      latitude: 41.04,
      longitude: 29.00,
      searchedAt: now.subtract(const Duration(days: 1)),
    ),
    SearchQueryModel(
      id: '3',
      sportType: MeetupType.tennis,
      regionName: 'Çankaya, Ankara',
      latitude: 39.92,
      longitude: 32.85,
      searchedAt: now.subtract(const Duration(days: 5)),
    ),
  ];
}

void main() {
  Widget buildTestWidget({
    ValueChanged<SearchQueryModel>? onSearchTap,
    RecentSearchesFetcher? fetcher,
    SearchDeleter? deleter,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: RecentSearchesList(
            onSearchTap: onSearchTap ?? (_) {},
            recentSearchesFetcher: fetcher ?? () async => _sampleSearches(),
            searchDeleter: deleter ?? (_) async {},
          ),
        ),
      ),
    );
  }

  group('RecentSearchesList', () {
    testWidgets('displays all search items with sport emoji and region',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('⚽'), findsOneWidget);
      expect(find.text('🏀'), findsOneWidget);
      expect(find.text('🎾'), findsOneWidget);

      expect(find.text('Futbol - Kadıköy, İstanbul'), findsOneWidget);
      expect(find.text('Basketbol - Beşiktaş, İstanbul'), findsOneWidget);
      expect(find.text('Tenis - Çankaya, Ankara'), findsOneWidget);
    });

    testWidgets('shows relative dates for each item', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Bugün'), findsOneWidget);
      expect(find.text('Dün'), findsOneWidget);
      expect(find.text('5 gün önce'), findsOneWidget);
    });

    testWidgets('shows empty state when no searches exist', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        fetcher: () async => [],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Henüz arama geçmişi yok'), findsOneWidget);
    });

    testWidgets('calls onSearchTap when an item is tapped', (tester) async {
      SearchQueryModel? tappedSearch;

      await tester.pumpWidget(buildTestWidget(
        onSearchTap: (search) => tappedSearch = search,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Futbol - Kadıköy, İstanbul'));
      expect(tappedSearch?.id, '1');
      expect(tappedSearch?.sportType, MeetupType.football);
    });

    testWidgets('swipe to dismiss removes item and calls deleter',
        (tester) async {
      String? deletedId;

      await tester.pumpWidget(buildTestWidget(
        deleter: (id) async => deletedId = id,
      ));
      await tester.pumpAndSettle();

      // Verify item exists
      expect(find.text('Futbol - Kadıköy, İstanbul'), findsOneWidget);

      // Swipe the first item to the left
      await tester.drag(
        find.text('Futbol - Kadıköy, İstanbul'),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(deletedId, '1');
      expect(find.text('Futbol - Kadıköy, İstanbul'), findsNothing);
    });

    testWidgets('shows loading indicator while fetching', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        fetcher: () => Future.delayed(
          const Duration(seconds: 2),
          () => _sampleSearches(),
        ),
      ));

      // Should show loading indicator before data arrives
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // After loading, items should be visible
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Futbol - Kadıköy, İstanbul'), findsOneWidget);
    });

    testWidgets('formats week-old dates correctly', (tester) async {
      final weekAgo = DateTime.now().subtract(const Duration(days: 10));
      await tester.pumpWidget(buildTestWidget(
        fetcher: () async => [
          SearchQueryModel(
            id: 'w1',
            sportType: MeetupType.yoga,
            regionName: 'Muratpaşa, Antalya',
            latitude: 36.88,
            longitude: 30.70,
            searchedAt: weekAgo,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('1 hafta önce'), findsOneWidget);
    });
  });
}
