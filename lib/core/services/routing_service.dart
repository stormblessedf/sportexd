import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/meetup_model.dart';

/// OSRM tabanlı routing servisi - yürünebilir/sürülebilir gerçek yol rotaları
class RoutingService {
  // OSRM demo sunucusu (ücretsiz, rate-limited)
  static const String _baseUrl = 'https://router.project-osrm.org';

  /// Etkinlik türüne göre OSRM profili
  static String _profileForType(MeetupType? type) {
    switch (type) {
      case MeetupType.cycling:
        return 'bike';
      case MeetupType.running:
      case MeetupType.hiking:
      default:
        return 'foot';
    }
  }

  /// Koordinat listesi arasında gerçek yol rotası al
  /// Dönen: (polyline noktaları, toplam mesafe km)
  static Future<RoutingResult?> getRoute({
    required List<LatLng> coordinates,
    MeetupType? meetupType,
  }) async {
    if (coordinates.length < 2) return null;

    final profile = _profileForType(meetupType);
    final coordStr = coordinates
        .map((c) => '${c.longitude},${c.latitude}')
        .join(';');

    final url = '$_baseUrl/route/v1/$profile/$coordStr'
        '?overview=full&geometries=geojson&steps=false';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Sporsal/1.0'},
      );

      if (response.statusCode != 200) {
        debugPrint('OSRM error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') {
        debugPrint('OSRM code: ${data['code']}');
        return null;
      }

      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) return null;

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coords = geometry['coordinates'] as List<dynamic>;
      final distanceMeters = (route['distance'] as num).toDouble();

      final polylinePoints = coords.map((c) {
        final coord = c as List<dynamic>;
        return LatLng(
          (coord[1] as num).toDouble(),
          (coord[0] as num).toDouble(),
        );
      }).toList();

      return RoutingResult(
        polylinePoints: polylinePoints,
        distanceKm: distanceMeters / 1000.0,
      );
    } catch (e) {
      debugPrint('OSRM routing error: $e');
      return null;
    }
  }
}

class RoutingResult {
  final List<LatLng> polylinePoints;
  final double distanceKm;

  const RoutingResult({
    required this.polylinePoints,
    required this.distanceKm,
  });
}
