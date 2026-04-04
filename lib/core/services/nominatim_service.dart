import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/location_data.dart';
import '../models/place_autocomplete_result.dart';

/// Service for Nominatim API (OpenStreetMap geocoding)
/// Implements rate limiting (1 request per second as per Nominatim usage policy)
class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const Duration _rateLimitDuration = Duration(seconds: 1);
  static const String _placeIdPrefix = 'nominatim:';

  DateTime? _lastRequestTime;

  /// Ensures rate limiting between requests
  Future<void> _waitForRateLimit() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _rateLimitDuration) {
        await Future.delayed(_rateLimitDuration - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Get address from coordinates (reverse geocoding)
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      await _waitForRateLimit();

      final url = Uri.parse(
        '$_baseUrl/reverse?format=json&lat=$latitude&lon=$longitude&accept-language=tr&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Sporsal/1.0 (https://sporsal.app)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] as String?;
      }

      debugPrint('Nominatim reverse geocoding failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Nominatim reverse geocoding error: $e');
      return null;
    }
  }

  /// Get coordinates from address (forward geocoding)
  Future<LocationData?> getCoordinatesFromAddress(String address) async {
    try {
      await _waitForRateLimit();

      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse(
        '$_baseUrl/search?format=json&q=$encodedAddress&accept-language=tr&limit=1&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Sporsal/1.0 (https://sporsal.app)',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final result = data.first;
          return LocationData(
            latitude: double.parse(result['lat']),
            longitude: double.parse(result['lon']),
            address: result['display_name'] as String?,
          );
        }
      }

      debugPrint('Nominatim forward geocoding failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Nominatim forward geocoding error: $e');
      return null;
    }
  }

  /// Fetch autocomplete-style suggestions for typed location input.
  Future<List<PlaceAutocompleteResult>> getAutocompleteSuggestions(
    String query, {
    int limit = 5,
  }) async {
    if (query.trim().length < 2) return [];

    try {
      await _waitForRateLimit();

      final encodedQuery = Uri.encodeComponent(query.trim());
      final url = Uri.parse(
        '$_baseUrl/search?format=jsonv2&q=$encodedQuery&accept-language=tr&limit=$limit&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Sporsal/1.0 (https://sporsal.app)',
        },
      );

      if (response.statusCode != 200) {
        debugPrint('Nominatim autocomplete failed: ${response.statusCode}');
        return [];
      }

      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data
          .map(_parseAutocompleteSuggestion)
          .whereType<PlaceAutocompleteResult>()
          .toList();
    } catch (e) {
      debugPrint('Nominatim autocomplete error: $e');
      return [];
    }
  }

  static bool isNominatimPlaceId(String placeId) {
    return placeId.startsWith(_placeIdPrefix);
  }

  static LocationData? locationFromPlaceId(String placeId) {
    if (!isNominatimPlaceId(placeId)) return null;

    try {
      final payload = placeId.substring(_placeIdPrefix.length);
      final decoded =
          json.decode(Uri.decodeComponent(payload)) as Map<String, dynamic>;
      return LocationData(
        latitude: (decoded['latitude'] as num).toDouble(),
        longitude: (decoded['longitude'] as num).toDouble(),
        name: decoded['name'] as String?,
        address: decoded['address'] as String?,
      );
    } catch (e) {
      debugPrint('Nominatim placeId decode error: $e');
      return null;
    }
  }

  PlaceAutocompleteResult? _parseAutocompleteSuggestion(dynamic item) {
    if (item is! Map) return null;

    final result = Map<String, dynamic>.from(item);
    final lat = double.tryParse('${result['lat'] ?? ''}');
    final lon = double.tryParse('${result['lon'] ?? ''}');
    final description = _asString(result['display_name'])?.trim();

    if (lat == null || lon == null || description == null || description.isEmpty) {
      return null;
    }

    final mainText = _deriveMainText(result, description);
    final secondaryText = _deriveSecondaryText(description, mainText);

    return PlaceAutocompleteResult(
      placeId: _encodePlaceId(
        latitude: lat,
        longitude: lon,
        name: mainText,
        address: description,
      ),
      description: description,
      mainText: mainText,
      secondaryText: secondaryText,
    );
  }

  String _deriveMainText(Map<String, dynamic> result, String description) {
    final named = _asString(result['name'])?.trim();
    if (named != null && named.isNotEmpty) {
      return named;
    }

    final firstSegment = description.split(',').first.trim();
    return firstSegment.isEmpty ? description : firstSegment;
  }

  String _deriveSecondaryText(String description, String mainText) {
    if (description == mainText) return '';

    if (description.startsWith('$mainText,')) {
      return description.substring(mainText.length + 1).trim();
    }

    final segments = description.split(',');
    if (segments.length <= 1) return '';
    return segments.skip(1).join(',').trim();
  }

  String _encodePlaceId({
    required double latitude,
    required double longitude,
    required String name,
    required String address,
  }) {
    final payload = json.encode({
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'address': address,
    });
    return '$_placeIdPrefix${Uri.encodeComponent(payload)}';
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    final stringValue = value.toString();
    return stringValue.isEmpty ? null : stringValue;
  }
}
