import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_data.dart';
import 'nominatim_service.dart';

class LocationService {
  static const double defaultLatitude = 41.0082;
  static const double defaultLongitude = 28.9784;

  final NominatimService _nominatimService = NominatimService();

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
    // Use Nominatim for all platforms
    final address = await _nominatimService.getAddressFromCoordinates(
      latitude,
      longitude,
    );

    // Fallback to coordinate string if Nominatim fails
    return address ?? '$latitude, $longitude';
  }

  Future<LocationData?> getCoordinatesFromAddress(String address) async {
    return _nominatimService.getCoordinatesFromAddress(address);
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
