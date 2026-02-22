import 'location_data.dart';

class RouteData {
  final LocationData startPoint;
  final LocationData? endPoint;
  final List<LocationData> waypoints;
  final double totalDistanceKm;
  /// OSRM'den gelen detaylı rota geometrisi [lat, lng] çiftleri
  final List<List<double>> routeGeometry;

  const RouteData({
    required this.startPoint,
    this.endPoint,
    this.waypoints = const [],
    this.totalDistanceKm = 0.0,
    this.routeGeometry = const [],
  });

  List<LocationData> get allPoints {
    final points = <LocationData>[startPoint, ...waypoints];
    if (endPoint != null) points.add(endPoint!);
    return points;
  }

  bool get hasGeometry => routeGeometry.length >= 2;
  bool get isValid => startPoint.latitude != 0 || startPoint.longitude != 0;

  RouteData copyWith({
    LocationData? startPoint,
    LocationData? endPoint,
    List<LocationData>? waypoints,
    double? totalDistanceKm,
    List<List<double>>? routeGeometry,
  }) {
    return RouteData(
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      waypoints: waypoints ?? this.waypoints,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      routeGeometry: routeGeometry ?? this.routeGeometry,
    );
  }

  /// routeGeometry'yi Firestore-uyumlu düz string'e encode et
  /// Format: "lat,lng;lat,lng;..."
  static String _encodeGeometry(List<List<double>> geometry) {
    if (geometry.isEmpty) return '';
    return geometry.map((pair) => '${pair[0]},${pair[1]}').join(';');
  }

  /// Firestore'dan okunan string'i routeGeometry'ye decode et
  static List<List<double>> _decodeGeometry(dynamic value) {
    if (value == null) return const [];
    if (value is String) {
      if (value.isEmpty) return const [];
      try {
        return value.split(';').map((pair) {
          final parts = pair.split(',');
          return [double.parse(parts[0]), double.parse(parts[1])];
        }).toList();
      } catch (_) {
        return const [];
      }
    }
    // Eski format uyumluluğu (List<List<double>>)
    if (value is List) {
      try {
        return value.map<List<double>>((item) {
          final pair = item as List<dynamic>;
          return [(pair[0] as num).toDouble(), (pair[1] as num).toDouble()];
        }).toList();
      } catch (_) {
        return const [];
      }
    }
    return const [];
  }

  Map<String, dynamic> toJson() {
    return {
      'startPoint': _locationToJson(startPoint),
      'endPoint': endPoint != null ? _locationToJson(endPoint!) : null,
      'waypoints': waypoints.map((w) => _locationToJson(w)).toList(),
      'totalDistanceKm': totalDistanceKm,
      'routeGeometry': _encodeGeometry(routeGeometry),
    };
  }

  factory RouteData.fromJson(Map<String, dynamic> json) {
    try {
      return RouteData(
        startPoint: _locationFromJson(json['startPoint'] as Map<String, dynamic>),
        endPoint: json['endPoint'] != null
            ? _locationFromJson(json['endPoint'] as Map<String, dynamic>)
            : null,
        waypoints: (json['waypoints'] as List<dynamic>?)
                ?.map((w) => _locationFromJson(w as Map<String, dynamic>))
                .toList() ??
            const [],
        totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
        routeGeometry: _decodeGeometry(json['routeGeometry']),
      );
    } catch (_) {
      rethrow;
    }
  }

  static RouteData? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      return RouteData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _locationToJson(LocationData loc) {
    return {
      'latitude': loc.latitude,
      'longitude': loc.longitude,
      'name': loc.name,
      'address': loc.address,
    };
  }

  static LocationData _locationFromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      name: json['name'] as String?,
      address: json['address'] as String?,
    );
  }
}
