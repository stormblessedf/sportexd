import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/location_data.dart';

/// Service for Nominatim API (OpenStreetMap geocoding)
/// Implements rate limiting (1 request per second as per Nominatim usage policy)
class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const Duration _rateLimitDuration = Duration(seconds: 1);

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
}
