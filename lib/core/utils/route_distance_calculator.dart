import 'dart:math';
import '../models/location_data.dart';

class RouteDistanceCalculator {
  static const double _earthRadiusKm = 6371.0;

  /// İki koordinat arası Haversine mesafesi (km)
  static double haversineDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  /// Sıralı nokta listesinin toplam mesafesi (km)
  static double totalDistance(List<LocationData> points) {
    if (points.length < 2) return 0.0;

    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += haversineDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return total;
  }

  /// Mesafeyi 0.1 km hassasiyetinde formatla
  static String formatDistance(double km) {
    return '${km.toStringAsFixed(1)} km';
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
