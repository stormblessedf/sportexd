import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/filter_state.dart';
import '../models/meetup_model.dart';

class FilterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _filterStateKey = 'discovery_filter_state';

  /// Build Firestore query with date range filter
  Query<Map<String, dynamic>> buildQuery(FilterState state) {
    Query<Map<String, dynamic>> query = _firestore.collection('meetups');

    // Apply date range filter (server-side) using Timestamp
    final startDate = state.dateRange.startDate;
    final endDate = state.dateRange.endDate;
    final sportTypes = state.sportTypes.map((type) => type.name).toList();

    // Push single-sport and small multi-sport filters to Firestore to avoid
    // downloading irrelevant meetup pages at scale.
    if (sportTypes.length == 1) {
      query = query.where('type', isEqualTo: sportTypes.first);
    } else if (sportTypes.length > 1 && sportTypes.length <= 10) {
      query = query.where('type', whereIn: sportTypes);
    }

    switch (state.participantFilter) {
      case ParticipantFilter.any:
        break;
      case ParticipantFilter.hasSpace:
        query = query.where('isFull', isEqualTo: false);
        break;
      case ParticipantFilter.almostFull:
        query = query.where('participantState', isEqualTo: 'almost_full');
        break;
    }

    final normalizedSearchToken = _normalizeSearchToken(state.searchQuery);
    if (normalizedSearchToken != null) {
      query = query.where('searchKeywords', arrayContains: normalizedSearchToken);
    }

    query = query
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: false);

    return query;
  }

/*
  String? _normalizeSearchToken(String query) {
    final normalized = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9Ã§ÄŸÄ±Ã¶ÅŸÃ¼\s]'), ' ')
        .trim();
    if (normalized.isEmpty) return null;

    final token = normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().length >= 2)
        .fold<String?>(
          null,
          (best, part) => best == null || part.length > best.length ? part : best,
        );

    return token;
  }

*/

  String? _normalizeSearchToken(String query) {
    final normalized = _normalizeSearchText(query).trim();
    if (normalized.isEmpty) return null;

    final token = normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().length >= 2)
        .fold<String?>(
          null,
          (best, part) => best == null || part.length > best.length ? part : best,
        );

    return token;
  }

  String _normalizeSearchText(String input) {
    var normalized = input.toLowerCase();
    const replacements = <String, String>{
      '\u00E7': 'c',
      '\u011F': 'g',
      '\u0131': 'i',
      'i\u0307': 'i',
      '\u00F6': 'o',
      '\u015F': 's',
      '\u00FC': 'u',
    };

    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });

    return normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  }

  /// Apply post-query filters (client-side)
  List<MeetupWithDistance> applyPostFilters(
    List<MeetupModel> meetups,
    FilterState state,
    double? userLatitude,
    double? userLongitude,
  ) {
    var filtered = meetups;

    // Sport type filter
    if (state.sportTypes.isNotEmpty) {
      filtered = filtered.where((m) => state.sportTypes.contains(m.type)).toList();
    }

    // Participant filter
    filtered = _applyParticipantFilter(filtered, state.participantFilter);

    // Search query filter
    if (state.searchQuery.isNotEmpty) {
      filtered = _applySearchFilter(filtered, state.searchQuery);
    }

    // Calculate distances and apply distance filter
    List<MeetupWithDistance> withDistance = filtered.map((meetup) {
      double? distance;
      if (userLatitude != null &&
          userLongitude != null &&
          meetup.hasCoordinates) {
        distance = calculateDistance(
          userLatitude,
          userLongitude,
          meetup.latitude!,
          meetup.longitude!,
        );
      }
      return MeetupWithDistance(meetup: meetup, distanceKm: distance);
    }).toList();

    // Distance filter
    if (state.distance != null) {
      withDistance = withDistance
          .where((m) =>
              m.distanceKm != null && m.distanceKm! <= state.distance!.radiusKm)
          .toList();
    }

    // Apply sorting
    withDistance = _applySorting(withDistance, state.sortOrder, userLatitude, userLongitude);

    return withDistance;
  }

  /// Apply participant availability filter
  List<MeetupModel> _applyParticipantFilter(
    List<MeetupModel> meetups,
    ParticipantFilter filter,
  ) {
    switch (filter) {
      case ParticipantFilter.any:
        return meetups;
      case ParticipantFilter.hasSpace:
        return meetups
            .where((m) => m.currentParticipants < m.maxParticipants)
            .toList();
      case ParticipantFilter.almostFull:
        return meetups
            .where((m) =>
                m.currentParticipants >= m.maxParticipants * 0.8 &&
                m.currentParticipants < m.maxParticipants)
            .toList();
    }
  }

  /// Apply search filter
  List<MeetupModel> _applySearchFilter(List<MeetupModel> meetups, String query) {
    final lowerQuery = query.toLowerCase();
    return meetups.where((m) {
      return m.title.toLowerCase().contains(lowerQuery) ||
          m.description.toLowerCase().contains(lowerQuery) ||
          m.locationName.toLowerCase().contains(lowerQuery) ||
          m.locationAddress.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Apply sorting based on sort order
  List<MeetupWithDistance> _applySorting(
    List<MeetupWithDistance> meetups,
    SortOrder sortOrder,
    double? userLatitude,
    double? userLongitude,
  ) {
    switch (sortOrder) {
      case SortOrder.date:
        meetups.sort((a, b) => a.meetup.date.compareTo(b.meetup.date));
        break;
      case SortOrder.distance:
        meetups.sort((a, b) {
          if (a.distanceKm == null && b.distanceKm == null) return 0;
          if (a.distanceKm == null) return 1;
          if (b.distanceKm == null) return -1;
          return a.distanceKm!.compareTo(b.distanceKm!);
        });
        break;
      case SortOrder.popularity:
        meetups.sort((a, b) =>
            b.meetup.currentParticipants.compareTo(a.meetup.currentParticipants));
        break;
      case SortOrder.newest:
        meetups.sort((a, b) =>
            b.meetup.createdAt.compareTo(a.meetup.createdAt));
        break;
      case SortOrder.intelligent:
        meetups = _applyIntelligentSort(meetups, userLatitude, userLongitude);
        break;
    }
    return meetups;
  }

  /// Intelligent sort with weighted scoring
  List<MeetupWithDistance> _applyIntelligentSort(
    List<MeetupWithDistance> meetups,
    double? userLatitude,
    double? userLongitude,
  ) {
    final scoredMeetups = meetups.map((m) {
      final double score = _calculateIntelligentScore(m, userLatitude, userLongitude);
      return _ScoredMeetup(m, score);
    }).toList();

    scoredMeetups.sort((a, b) => b.score.compareTo(a.score));
    return scoredMeetups.map((s) => s.meetup).toList();
  }

  /// Calculate intelligent score for a meetup
  double _calculateIntelligentScore(
    MeetupWithDistance meetup,
    double? userLatitude,
    double? userLongitude,
  ) {
    double score = 0.0;

    // Time proximity (0-40 points)
    final hoursUntil = meetup.meetup.date.difference(DateTime.now()).inHours;
    if (hoursUntil <= 24) {
      score += 40;
    } else if (hoursUntil <= 72) {
      score += 30;
    } else if (hoursUntil <= 168) {
      score += 20;
    } else {
      score += 10;
    }

    // Distance proximity (0-30 points)
    if (meetup.distanceKm != null) {
      if (meetup.distanceKm! <= 5) {
        score += 30;
      } else if (meetup.distanceKm! <= 10) {
        score += 20;
      } else if (meetup.distanceKm! <= 25) {
        score += 10;
      }
    }

    // Popularity (0-30 points)
    final fillRate =
        meetup.meetup.currentParticipants / meetup.meetup.maxParticipants;
    score += fillRate * 30;

    return score;
  }

  /// Calculate distance using Haversine formula
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  /// Save filter state to SharedPreferences
  Future<void> saveFilterState(FilterState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_filterStateKey, state.toJsonString());
  }

  /// Load filter state from SharedPreferences
  Future<FilterState?> loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_filterStateKey);
    if (jsonString == null) return null;
    try {
      return FilterState.fromJsonString(jsonString);
    } catch (e) {
      return null;
    }
  }

  /// Clear saved filter state
  Future<void> clearFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_filterStateKey);
  }
}

/// Helper class for intelligent sorting
class _ScoredMeetup {
  final MeetupWithDistance meetup;
  final double score;

  _ScoredMeetup(this.meetup, this.score);
}

