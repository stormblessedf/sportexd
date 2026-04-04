import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/filter_state.dart';
import '../models/meetup_model.dart';
import 'filter_service.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FilterService _filterService = FilterService();
  final Map<String, List<String>> _interestedSportsCache = {};
  final Map<String, DateTime> _interestedSportsCacheTimestamps = {};
  static const Duration _interestedSportsCacheDuration = Duration(minutes: 10);

  /// Generate all recommendation sections
  Future<RecommendationSections> generateRecommendations({
    required String userId,
    double? userLatitude,
    double? userLongitude,
    List<MeetupModel>? allMeetups,
  }) async {
    try {
      // Fetch all upcoming meetups if not provided
      final meetups = allMeetups ?? await _fetchUpcomingMeetups();
      if (meetups.isEmpty) {
        return const RecommendationSections();
      }

      // Track used meetup IDs to avoid overlap
      final usedIds = <String>{};

      // Generate sections
      final forYou = await _getForYou(userId, meetups, usedIds);
      final trendingNearby = _getTrendingNearby(
        meetups,
        userLatitude,
        userLongitude,
        usedIds,
      );
      final startingSoon = _getStartingSoon(meetups, usedIds);
      final newEvents = _getNewEvents(meetups, usedIds);

      return RecommendationSections(
        forYou: forYou,
        trendingNearby: trendingNearby,
        startingSoon: startingSoon,
        newEvents: newEvents,
      );
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
      return const RecommendationSections();
    }
  }

  /// Fetch upcoming meetups
  Future<List<MeetupModel>> _fetchUpcomingMeetups() async {
    final now = DateTime.now();
    final horizon = now.add(const Duration(days: 21));
    final snapshot = await _firestore
        .collection('meetups')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(horizon))
        .orderBy('date')
        .limit(40)
        .get();

    return snapshot.docs
        .map((doc) => MeetupModel.fromJson(doc.data()))
        .where((meetup) => meetup.isFeedVisible)
        .toList();
  }

  /// Get "For You" recommendations based on user's participated sport types
  Future<List<MeetupModel>> _getForYou(
    String userId,
    List<MeetupModel> meetups,
    Set<String> usedIds,
  ) async {
    try {
      // Get user's participation history
      final interestedSports = await _getInterestedSports(userId);

      if (interestedSports.isEmpty) {
        return _getTrending(meetups, usedIds);
      }

      // Filter meetups matching user's interests
      final recommendations = meetups.where((m) {
        if (usedIds.contains(m.id)) return false;
        return interestedSports.any((sport) =>
            m.type.name.toLowerCase() == sport.toLowerCase() ||
            m.type.displayName.toLowerCase() == sport.toLowerCase());
      }).take(5).toList();

      // Mark as used
      for (final m in recommendations) {
        usedIds.add(m.id);
      }

      // If not enough, fallback to trending
      if (recommendations.length < 3) {
        return _getTrending(meetups, usedIds);
      }

      return recommendations;
    } catch (e) {
      debugPrint('Error getting for you recommendations: $e');
      return _getTrending(meetups, usedIds);
    }
  }

  Future<List<String>> _getInterestedSports(String userId) async {
    if (_isInterestedSportsCacheValid(userId)) {
      return _interestedSportsCache[userId] ?? const [];
    }

    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      _updateInterestedSportsCache(userId, const []);
      return const [];
    }

    final userData = userDoc.data();
    final interestedSports = (userData?['interestedSports'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    _updateInterestedSportsCache(userId, interestedSports);
    return interestedSports;
  }

  bool _isInterestedSportsCacheValid(String userId) {
    final timestamp = _interestedSportsCacheTimestamps[userId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) <
        _interestedSportsCacheDuration;
  }

  void _updateInterestedSportsCache(String userId, List<String> interestedSports) {
    _interestedSportsCache[userId] = interestedSports;
    _interestedSportsCacheTimestamps[userId] = DateTime.now();
  }

  /// Get trending meetups (fallback for users without history)
  List<MeetupModel> _getTrending(
    List<MeetupModel> meetups,
    Set<String> usedIds,
  ) {
    final trending = meetups
        .where((m) => !usedIds.contains(m.id))
        .toList()
      ..sort((a, b) => b.currentParticipants.compareTo(a.currentParticipants));

    final result = trending.take(5).toList();

    for (final m in result) {
      usedIds.add(m.id);
    }

    return result;
  }

  /// Get trending meetups within 10km
  List<MeetupModel> _getTrendingNearby(
    List<MeetupModel> meetups,
    double? userLatitude,
    double? userLongitude,
    Set<String> usedIds,
  ) {
    if (userLatitude == null || userLongitude == null) {
      return [];
    }

    final nearby = meetups.where((m) {
      if (usedIds.contains(m.id)) return false;
      if (!m.hasCoordinates) return false;

      final distance = _filterService.calculateDistance(
        userLatitude,
        userLongitude,
        m.latitude!,
        m.longitude!,
      );

      return distance <= 10.0; // 10km radius
    }).toList();

    // Sort by popularity
    nearby.sort((a, b) => b.currentParticipants.compareTo(a.currentParticipants));

    final result = nearby.take(5).toList();

    for (final m in result) {
      usedIds.add(m.id);
    }

    return result;
  }

  /// Get meetups starting in the next 24 hours
  List<MeetupModel> _getStartingSoon(
    List<MeetupModel> meetups,
    Set<String> usedIds,
  ) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(hours: 24));

    final startingSoon = meetups.where((m) {
      if (usedIds.contains(m.id)) return false;
      return m.date.isAfter(now) && m.date.isBefore(tomorrow);
    }).toList();

    // Sort by date (soonest first)
    startingSoon.sort((a, b) => a.date.compareTo(b.date));

    final result = startingSoon.take(5).toList();

    for (final m in result) {
      usedIds.add(m.id);
    }

    return result;
  }

  /// Get meetups created in the last 7 days
  List<MeetupModel> _getNewEvents(
    List<MeetupModel> meetups,
    Set<String> usedIds,
  ) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final newEvents = meetups.where((m) {
      if (usedIds.contains(m.id)) return false;
      return m.createdAt.isAfter(weekAgo);
    }).toList();

    // Sort by creation date (newest first)
    newEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final result = newEvents.take(5).toList();

    for (final m in result) {
      usedIds.add(m.id);
    }

    return result;
  }
}
