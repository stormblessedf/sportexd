import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/meetup_model.dart';
import '../models/venue_model.dart';
import 'places_service.dart';

/// Error types for venue recommendation operations.
enum VenueErrorType {
  /// Request timed out after 10 seconds.
  timeout,

  /// No internet connection.
  network,

  /// API quota exceeded or server error.
  apiQuota,

  /// Unknown / generic error.
  unknown,
}

/// Exception with a typed error for venue operations.
class VenueException implements Exception {
  final VenueErrorType type;
  final String message;
  final Object? cause;

  const VenueException(this.type, this.message, [this.cause]);

  /// User-facing Turkish error message.
  String get userMessage {
    switch (type) {
      case VenueErrorType.timeout:
        return 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
      case VenueErrorType.network:
        return 'İnternet bağlantısı bulunamadı.';
      case VenueErrorType.apiQuota:
        return 'Şu anda çok fazla istek var, lütfen daha sonra tekrar deneyin.';
      case VenueErrorType.unknown:
        return 'Bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
    }
  }

  @override
  String toString() => 'VenueException($type): $message';
}

class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool get isValid => DateTime.now().difference(timestamp).inMinutes < 15;
}

class VenueRecommendationService {
  final PlacesService _placesService;

  VenueRecommendationService(this._placesService);

  /// Timeout duration for API calls.
  static const Duration apiTimeout = Duration(seconds: 10);

  /// Search results cache: key = "$sportType-$lat-$lng"
  final Map<String, _CacheEntry<List<VenueModel>>> _searchCache = {};

  /// Venue detail cache: key = placeId
  final Map<String, _CacheEntry<VenueModel>> _detailCache = {};

  /// Sport type → search keyword mapping
  static const Map<MeetupType, String> sportKeywords = {
    MeetupType.football: 'futbol sahası',
    MeetupType.basketball: 'basketbol sahası',
    MeetupType.volleyball: 'voleybol sahası',
    MeetupType.tennis: 'tenis kortu',
    MeetupType.tableTennis: 'masa tenisi salonu',
    MeetupType.badminton: 'badminton salonu',
    MeetupType.swimming: 'yüzme havuzu',
    MeetupType.running: 'koşu parkuru',
    MeetupType.cycling: 'bisiklet parkuru',
    MeetupType.hiking: 'doğa yürüyüşü parkuru',
    MeetupType.yoga: 'yoga stüdyosu',
    MeetupType.fitness: 'spor salonu',
    MeetupType.boxing: 'boks salonu',
    MeetupType.climbing: 'tırmanış duvarı',
    MeetupType.skiing: 'kayak merkezi',
    MeetupType.other: 'spor tesisi',
  };

  /// Searches venues by sport type and location.
  /// Returns cached results if available and valid (< 15 min).
  Future<List<VenueModel>> searchVenues({
    required MeetupType sportType,
    required double lat,
    required double lng,
    int radius = 10000,
  }) async {
    final cacheKey = '$sportType-$lat-$lng';

    if (isCacheValid(cacheKey)) {
      debugPrint('VenueRecommendationService: Returning cached results for $cacheKey');
      return _searchCache[cacheKey]!.data;
    }

    try {
      final keyword = sportKeywords[sportType] ?? 'spor tesisi';

      final results = await _placesService
          .searchNearbyPlaces(
            lat: lat,
            lng: lng,
            keyword: keyword,
            radius: radius,
          )
          .timeout(apiTimeout);

      final venues = results
          .map((data) => VenueModel.fromPlacesResponse(data))
          .map((v) => VenueModel(
                placeId: v.placeId,
                name: v.name,
                address: v.address,
                latitude: v.latitude,
                longitude: v.longitude,
                rating: v.rating,
                userRatingCount: v.userRatingCount,
                priceLevel: v.priceLevel,
                isOpen: v.isOpen,
                weekdayHours: v.weekdayHours,
                phoneNumber: v.phoneNumber,
                photoUrls: v.photoUrls,
                reviews: v.reviews,
                sportType: sportType,
              ))
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));

      _searchCache[cacheKey] = _CacheEntry(venues);

      debugPrint('VenueRecommendationService: Found ${venues.length} venues for $sportType');
      return venues;
    } on TimeoutException {
      debugPrint('VenueRecommendationService: searchVenues timeout');
      throw const VenueException(
        VenueErrorType.timeout,
        'searchVenues timed out after 10 seconds',
      );
    } catch (e) {
      debugPrint('VenueRecommendationService: searchVenues error: $e');
      throw VenueException(
        _classifyError(e),
        'searchVenues failed: $e',
        e,
      );
    }
  }

  /// Fetches full details for a venue by place ID.
  /// Returns cached result if available and valid.
  Future<VenueModel?> getVenueDetails(String placeId) async {
    if (placeId.isEmpty) return null;

    final cached = _detailCache[placeId];
    if (cached != null && cached.isValid) {
      debugPrint('VenueRecommendationService: Returning cached details for $placeId');
      return cached.data;
    }

    try {
      final data = await _placesService
          .getPlaceFullDetails(placeId)
          .timeout(apiTimeout);
      if (data == null) return null;

      final venue = VenueModel.fromPlacesResponse(data);
      _detailCache[placeId] = _CacheEntry(venue);

      debugPrint('VenueRecommendationService: Got details for ${venue.name}');
      return venue;
    } on TimeoutException {
      debugPrint('VenueRecommendationService: getVenueDetails timeout');
      throw const VenueException(
        VenueErrorType.timeout,
        'getVenueDetails timed out after 10 seconds',
      );
    } catch (e) {
      debugPrint('VenueRecommendationService: getVenueDetails error: $e');
      throw VenueException(
        _classifyError(e),
        'getVenueDetails failed: $e',
        e,
      );
    }
  }

  /// Clears all caches.
  void clearCache() {
    _searchCache.clear();
    _detailCache.clear();
  }

  /// Checks if a cache entry exists and is still valid (< 15 min).
  bool isCacheValid(String key) {
    final entry = _searchCache[key];
    return entry != null && entry.isValid;
  }

  /// Classifies an error into a [VenueErrorType].
  VenueErrorType _classifyError(Object error) {
    final msg = error.toString().toLowerCase();
    if (error is TimeoutException) return VenueErrorType.timeout;
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('xmlhttprequest') ||
        msg.contains('failed to fetch')) {
      return VenueErrorType.network;
    }
    if (msg.contains('quota') ||
        msg.contains('rate limit') ||
        msg.contains('429') ||
        msg.contains('resource_exhausted')) {
      return VenueErrorType.apiQuota;
    }
    return VenueErrorType.unknown;
  }
}
