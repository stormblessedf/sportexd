import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/search_query_model.dart';

class SearchHistoryService {
  static const String _storageKey = 'venue_search_history';
  static const int _maxHistoryItems = 10;

  /// Saves a search query to the front of the history list.
  /// Trims to [_maxHistoryItems] max.
  Future<void> saveSearch(SearchQueryModel query) async {
    final searches = await getRecentSearches();
    searches.removeWhere((s) => s.id == query.id);
    searches.insert(0, query);
    if (searches.length > _maxHistoryItems) {
      searches.removeRange(_maxHistoryItems, searches.length);
    }
    await _persist(searches);
  }

  /// Returns all saved searches, newest first.
  Future<List<SearchQueryModel>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded
          .map((e) => SearchQueryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Removes a specific search by [id].
  Future<void> deleteSearch(String id) async {
    final searches = await getRecentSearches();
    searches.removeWhere((s) => s.id == id);
    await _persist(searches);
  }

  /// Removes all saved searches.
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _persist(List<SearchQueryModel> searches) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(searches.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
