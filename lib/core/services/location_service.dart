import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:js_interop';
import '../models/location_data.dart';

// Geocoder API
@JS('google.maps.Geocoder')
extension type GeocoderJS._(JSObject _) implements JSObject {
  external factory GeocoderJS();
  external JSPromise geocode(JSObject request);
}

@JS()
extension type GeocoderResponse._(JSObject _) implements JSObject {
  external JSArray? get results;
}

@JS()
extension type GeocoderResult._(JSObject _) implements JSObject {
  external String get formatted_address;
  external GeocoderGeometry get geometry;
}

@JS()
extension type GeocoderGeometry._(JSObject _) implements JSObject {
  external LatLngJS get location;
}

@JS()
extension type LatLngJS._(JSObject _) implements JSObject {
  external double lat();
  external double lng();
}

// Helper to create JS objects
@JS('Object.create')
external JSObject _objectCreate(JSObject? proto);

@JS('Reflect.set')
external void _setProperty(JSObject obj, String key, JSAny? value);

JSObject _createJsObject(Map<String, dynamic> map) {
  final obj = _objectCreate(null);
  for (final entry in map.entries) {
    _setProperty(obj, entry.key, _toJsValue(entry.value));
  }
  return obj;
}

JSAny? _toJsValue(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.toJS;
  if (value is num) return value.toJS;
  if (value is bool) return value.toJS;
  if (value is Map<String, dynamic>) {
    return _createJsObject(value);
  }
  return null;
}

class LocationService {
  static const double defaultLatitude = 41.0082;
  static const double defaultLongitude = 28.9784;

  GeocoderJS? _geocoder;

  void _initGeocoder() {
    if (_geocoder == null && kIsWeb) {
      try {
        _geocoder = GeocoderJS();
        debugPrint('LocationService: Geocoder initialized');
      } catch (e) {
        debugPrint('LocationService: Error initializing Geocoder: $e');
      }
    }
  }

  Future<bool> checkAndRequestPermission() async {
    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return permission == LocationPermission.whileInUse ||
             permission == LocationPermission.always;
    } catch (e) {
      debugPrint('Permission check error: $e');
      return false;
    }
  }

  Future<LocationData?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        debugPrint('Konum izni verilmedi');
        return null;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Konum servisi kapalı');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      debugPrint('Konum alınamadı: $e');
      return null;
    }
  }

  LocationData getDefaultLocation() {
    return const LocationData(
      latitude: defaultLatitude,
      longitude: defaultLongitude,
      name: 'İstanbul',
      address: 'İstanbul, Türkiye',
    );
  }

  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    if (kIsWeb) {
      return _getAddressFromCoordinatesWeb(latitude, longitude);
    }

    // For mobile, return a formatted coordinate string as fallback
    return '$latitude, $longitude';
  }

  Future<String?> _getAddressFromCoordinatesWeb(
    double latitude,
    double longitude,
  ) async {
    try {
      _initGeocoder();
      if (_geocoder == null) return null;

      final request = _createJsObject({
        'location': {
          'lat': latitude,
          'lng': longitude,
        },
      });

      final response = await _geocoder!.geocode(request).toDart as GeocoderResponse;
      final results = response.results?.toDart;

      if (results != null && results.isNotEmpty) {
        final firstResult = results.first as GeocoderResult;
        return firstResult.formatted_address;
      }

      return null;
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      return null;
    }
  }

  Future<LocationData?> getCoordinatesFromAddress(String address) async {
    if (kIsWeb) {
      return _getCoordinatesFromAddressWeb(address);
    }
    return null;
  }

  Future<LocationData?> _getCoordinatesFromAddressWeb(String address) async {
    try {
      _initGeocoder();
      if (_geocoder == null) return null;

      final request = _createJsObject({
        'address': address,
      });

      final response = await _geocoder!.geocode(request).toDart as GeocoderResponse;
      final results = response.results?.toDart;

      if (results != null && results.isNotEmpty) {
        final firstResult = results.first as GeocoderResult;
        final location = firstResult.geometry.location;
        return LocationData(
          latitude: location.lat(),
          longitude: location.lng(),
          address: firstResult.formatted_address,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Geocoding error: $e');
      return null;
    }
  }

  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371;

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

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}
