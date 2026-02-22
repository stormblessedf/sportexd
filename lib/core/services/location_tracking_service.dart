import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/meetup_model.dart';
import '../models/organizer_location_model.dart';
import 'location_service.dart';
import 'proximity_attendance_service.dart';

/// Manages location tracking during active meetups.
/// - Organizer: broadcasts GPS to Firestore every 30s
/// - Participant: checks proximity to organizer every 30s
class LocationTrackingService {
  final LocationService _locationService = LocationService();
  final ProximityAttendanceService _proximityService = ProximityAttendanceService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Timer? _trackingTimer;
  String? _currentUserId;
  List<MeetupModel> _activeMeetups = [];

  /// Track which meetups this user has already been marked as attended for
  /// to avoid repeated proximity checks.
  final Set<String> _attendedMeetupIds = {};

  bool get isTracking => _trackingTimer != null && _trackingTimer!.isActive;

  /// Starts 30-second polling for active meetups.
  Future<void> startTracking({
    required String userId,
    required List<MeetupModel> activeMeetups,
  }) async {
    if (activeMeetups.isEmpty) {
      debugPrint('LocationTracking: No active meetups, not starting');
      return;
    }

    if (_currentUserId != null && _currentUserId != userId) {
      _attendedMeetupIds.clear();
    }
    _currentUserId = userId;
    _activeMeetups = activeMeetups;

    // Cancel existing timer
    stopTracking();

    debugPrint('LocationTracking: Starting tracking for ${activeMeetups.length} meetups');

    // Do an immediate check
    await _performTrackingCycle();

    // Then poll every 30 seconds
    _trackingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _performTrackingCycle();
    });
  }

  /// Stops all location tracking.
  void stopTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    debugPrint('LocationTracking: Stopped');
  }

  /// Clears in-memory tracking state (used on logout/user switch).
  void resetTrackingState() {
    stopTracking();
    _currentUserId = null;
    _activeMeetups = [];
    _attendedMeetupIds.clear();
  }

  /// Disposes resources.
  void dispose() {
    resetTrackingState();
  }

  /// Performs one tracking cycle: get location, broadcast/check for each meetup.
  Future<void> _performTrackingCycle() async {
    if (_currentUserId == null || _activeMeetups.isEmpty) return;

    try {
      // Get current GPS position with accuracy
      final position = await _getCurrentPosition();
      if (position == null) return;

      // Filter out GPS readings with accuracy worse than 100m
      if (!_proximityService.shouldAcceptGpsReading(position.accuracy)) {
        debugPrint('LocationTracking: GPS accuracy too low (${position.accuracy}m), skipping');
        return;
      }

      final now = DateTime.now();
      final metupsToRemove = <String>[];

      for (final meetup in _activeMeetups) {
        // Skip if already attended
        if (_attendedMeetupIds.contains(meetup.id)) {
          metupsToRemove.add(meetup.id);
          continue;
        }

        final cutoff = _proximityService.calculateCutoffTime(meetup.date, meetup.endDate);

        // If cutoff reached, stop tracking this meetup
        if (_proximityService.isCutoffReached(now, cutoff)) {
          metupsToRemove.add(meetup.id);
          continue;
        }

        // Am I the organizer?
        final isOrganizer = meetup.organizerId == _currentUserId;

        if (isOrganizer) {
          // ÖNCE organizatör konumunu Firestore'a yayınla
          // await ile sıralı çalışır — yakınlık kontrolünden önce tamamlanır (Req 2.1, 2.3)
          await broadcastOrganizerLocation(
            meetupId: meetup.id,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }

        // SONRA yakınlık kontrolü yap (organizatör dahil)
        // Hata durumunda buluşma aktif listeden çıkarılmaz — sonraki döngüde tekrar denenir (Req 4.3)
        try {
          await checkProximityForParticipant(
            meetup: meetup,
            participantId: _currentUserId!,
            participantLat: position.latitude,
            participantLon: position.longitude,
          );
        } catch (e) {
          debugPrint('LocationTracking: Proximity check failed for ${meetup.id}, will retry next cycle: $e');
        }
      }

      // Remove completed/expired meetups from active list
      if (metupsToRemove.isNotEmpty) {
        _activeMeetups.removeWhere((m) => metupsToRemove.contains(m.id));
        if (_activeMeetups.isEmpty) {
          stopTracking();
        }
      }
    } catch (e) {
      debugPrint('LocationTracking: Error in tracking cycle: $e');
    }
  }

  /// Gets current GPS position using Geolocator directly for accuracy info.
  Future<Position?> _getCurrentPosition() async {
    try {
      final hasPermission = await _locationService.checkAndRequestPermission();
      if (!hasPermission) {
        debugPrint('LocationTracking: No location permission');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('LocationTracking: Error getting position: $e');
      return null;
    }
  }

  /// Writes organizer's GPS coordinates to Firestore.
  Future<void> broadcastOrganizerLocation({
    required String meetupId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final location = OrganizerLocationModel(
        latitude: latitude,
        longitude: longitude,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('meetups')
          .doc(meetupId)
          .collection('organizer_location')
          .doc('current')
          .set(location.toJson());
    } catch (e) {
      debugPrint('LocationTracking: Error broadcasting organizer location: $e');
    }
  }

  /// Gets the organizer's current location.
  /// Falls back to meetup's static coordinates if live location not available.
  /// Returns null if no valid coordinates are available.
  Future<({double latitude, double longitude})?> getOrganizerLocation(
    MeetupModel meetup,
  ) async {
    // 1. Firestore'dan canlı konum oku
    try {
      final doc = await _firestore
          .collection('meetups')
          .doc(meetup.id)
          .collection('organizer_location')
          .doc('current')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lon = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null && !_isInvalidCoordinate(lat, lon)) {
          return (latitude: lat, longitude: lon);
        }
      }
    } catch (e) {
      debugPrint('LocationTracking: Error reading organizer location: $e');
    }

    // 2. Fallback: statik koordinatlar
    if (meetup.hasCoordinates) {
      final lat = meetup.latitude!;
      final lon = meetup.longitude!;
      if (!_isInvalidCoordinate(lat, lon)) {
        return (latitude: lat, longitude: lon);
      }
    }

    // 3. Hiçbir geçerli koordinat yok → null döndür
    debugPrint('LocationTracking: No valid coordinates for meetup ${meetup.id}');
    return null;
  }

  /// (0.0, 0.0) koordinatlarını geçersiz kabul et
  bool _isInvalidCoordinate(double lat, double lon) {
    return lat == 0.0 && lon == 0.0;
  }

  /// Checks proximity of a participant to the organizer for a specific meetup.
  Future<void> checkProximityForParticipant({
    required MeetupModel meetup,
    required String participantId,
    required double participantLat,
    required double participantLon,
  }) async {
    try {
      // Already recorded?
      final hasRecord = await _proximityService.hasAttendanceRecord(meetup.id, participantId);
      if (hasRecord) {
        _attendedMeetupIds.add(meetup.id);
        return;
      }

      // Get organizer reference location
      final orgLoc = await getOrganizerLocation(meetup);
      if (orgLoc == null) {
        debugPrint('LocationTracking: No valid organizer location, will retry next cycle');
        return;
      }

      // Calculate distance
      final distance = _proximityService.calculateDistanceMeters(
        participantLat, participantLon,
        orgLoc.latitude, orgLoc.longitude,
      );

      debugPrint('LocationTracking: ${meetup.title} - Distance: ${distance.toStringAsFixed(1)}m');

      // Check if within radius
      if (_proximityService.isWithinRadius(distance)) {
        await _proximityService.markAttended(
          meetupId: meetup.id,
          userId: participantId,
          distanceMeters: distance,
        );
        _attendedMeetupIds.add(meetup.id);
        debugPrint('LocationTracking: AUTO-ATTENDED ${meetup.title}');
      }
    } catch (e) {
      debugPrint('LocationTracking: Error checking proximity: $e');
    }
  }

  /// Gets active meetups for a user (started but cutoff not yet reached).
  Future<List<MeetupModel>> getActiveMeetups(String userId) async {
    try {
      final now = DateTime.now();

      final snapshot = await _firestore
          .collection('meetups')
          .where('participantIds', arrayContains: userId)
          .get();

      final active = <MeetupModel>[];

      for (final doc in snapshot.docs) {
        final meetup = MeetupModel.fromJson(doc.data());

        // Must have started
        if (meetup.date.isAfter(now)) continue;

        // Cutoff must not have been reached
        final cutoff = _proximityService.calculateCutoffTime(meetup.date, meetup.endDate);
        if (_proximityService.isCutoffReached(now, cutoff)) continue;

        // Skip if already has attendance record
        if (_attendedMeetupIds.contains(meetup.id)) continue;

        active.add(meetup);
      }

      return active;
    } catch (e) {
      debugPrint('LocationTracking: Error getting active meetups: $e');
      return [];
    }
  }
}
