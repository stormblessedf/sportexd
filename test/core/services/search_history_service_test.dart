import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/core/models/search_query_model.dart';
import 'package:sporsal/core/services/search_history_service.dart';

void main() {
  late SearchHistoryService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = SearchHistoryService();
  });

  SearchQueryModel _makeQuery({
    String? id,
    MeetupType sportType = MeetupType.football,
    String regionName = 'Kadıköy',
  }) {
    return SearchQueryModel(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      sportType: sportType,
      regionName: regionName,
      latitude: 40.98,
      longitude: 29.03,
      searchedAt: DateTime.now(),
    );
  }

  group('SearchHistoryService', () {
    test('getRecentSearches returns empty list initially', () async {
      final result = await service.getRecentSearches();
      expect(result, isEmpty);
    });

    test('saveSearch stores a query and retrieves it', () async {
      final query = _makeQuery(id: 'q1');
      await service.saveSearch(query);

      final result = await service.getRecentSearches();
      expect(result.length, 1);
      expect(result.first.id, 'q1');
    });

    test('saveSearch adds new query to front of list', () async {
      final q1 = _makeQuery(id: 'q1');
      final q2 = _makeQuery(id: 'q2');
      await service.saveSearch(q1);
      await service.saveSearch(q2);

      final result = await service.getRecentSearches();
      expect(result.length, 2);
      expect(result[0].id, 'q2');
      expect(result[1].id, 'q1');
    });

    test('saveSearch trims list to 10 max', () async {
      for (var i = 0; i < 12; i++) {
        await service.saveSearch(_makeQuery(id: 'q$i'));
      }

      final result = await service.getRecentSearches();
      expect(result.length, 10);
      // Most recent should be first
      expect(result.first.id, 'q11');
    });

    test('saveSearch deduplicates by id, moving to front', () async {
      final q1 = _makeQuery(id: 'q1', regionName: 'Kadıköy');
      final q2 = _makeQuery(id: 'q2');
      await service.saveSearch(q1);
      await service.saveSearch(q2);

      // Re-save q1 — should move to front
      final q1Updated = _makeQuery(id: 'q1', regionName: 'Beşiktaş');
      await service.saveSearch(q1Updated);

      final result = await service.getRecentSearches();
      expect(result.length, 2);
      expect(result[0].id, 'q1');
      expect(result[0].regionName, 'Beşiktaş');
      expect(result[1].id, 'q2');
    });

    test('deleteSearch removes specific search by id', () async {
      await service.saveSearch(_makeQuery(id: 'q1'));
      await service.saveSearch(_makeQuery(id: 'q2'));
      await service.deleteSearch('q1');

      final result = await service.getRecentSearches();
      expect(result.length, 1);
      expect(result.first.id, 'q2');
    });

    test('deleteSearch with non-existent id does nothing', () async {
      await service.saveSearch(_makeQuery(id: 'q1'));
      await service.deleteSearch('non-existent');

      final result = await service.getRecentSearches();
      expect(result.length, 1);
    });

    test('clearHistory removes all searches', () async {
      await service.saveSearch(_makeQuery(id: 'q1'));
      await service.saveSearch(_makeQuery(id: 'q2'));
      await service.clearHistory();

      final result = await service.getRecentSearches();
      expect(result, isEmpty);
    });

    test('getRecentSearches handles corrupted data gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('venue_search_history', 'not-valid-json');

      final result = await service.getRecentSearches();
      expect(result, isEmpty);
    });
  });
}
