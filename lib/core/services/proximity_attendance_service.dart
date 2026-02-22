import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/attendance_record_model.dart';
import '../models/meetup_model.dart';
import 'reliability_service.dart';

class ProximityAttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ReliabilityService _reliabilityService = ReliabilityService();

  // ── Pure functions ──────────────────────────────────────────────────

  /// Haversine formula: returns distance in **meters** between two GPS points.
  double calculateDistanceMeters(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double earthRadiusMeters = 6371000;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  /// Returns true if [distanceMeters] is within [radiusMeters] (default 50m).
  bool isWithinRadius(double distanceMeters, {double radiusMeters = 50.0}) {
    return distanceMeters <= radiusMeters;
  }

  /// Cutoff = startTime + (endTime − startTime) / 2.
  /// If [endTime] is null, uses a default duration of 2 hours.
  DateTime calculateCutoffTime(DateTime startTime, DateTime? endTime) {
    final effectiveEnd = endTime ?? startTime.add(const Duration(hours: 2));
    final halfDuration = effectiveEnd.difference(startTime) ~/ 2;
    return startTime.add(halfDuration);
  }

  /// Returns true if [now] is at or past [cutoffTime].
  bool isCutoffReached(DateTime now, DateTime cutoffTime) {
    return !now.isBefore(cutoffTime);
  }

  /// GPS reading is acceptable if accuracy is 100 m or better.
  bool shouldAcceptGpsReading(double accuracyMeters) {
    return accuracyMeters <= 100.0;
  }

  // ── Firestore operations ────────────────────────────────────────────

  /// Marks participant as "attended" and writes record to Firestore.
  Future<void> markAttended({
    required String meetupId,
    required String userId,
    required double distanceMeters,
  }) async {
    try {
      // Idempotence check
      if (await hasAttendanceRecord(meetupId, userId)) {
        debugPrint('ProximityAttendance: $userId already has record for $meetupId, skipping');
        return;
      }

      final record = AttendanceRecordModel(
        userId: userId,
        status: 'attended',
        detectedAt: DateTime.now(),
        distanceMeters: distanceMeters,
        method: 'gps_proximity',
      );

      await _firestore
          .collection('meetups')
          .doc(meetupId)
          .collection('attendance_records')
          .doc(userId)
          .set(record.toJson());

      debugPrint('ProximityAttendance: Marked $userId as ATTENDED for $meetupId (${distanceMeters.toStringAsFixed(1)}m)');

      // Güvenilirlik puanını güncelle (non-blocking)
      try {
        await _reliabilityService.incrementJoinedAndRecalculate(userId);
      } catch (e) {
        debugPrint('ProximityAttendance: Reliability update failed (non-blocking): $e');
      }
    } catch (e) {
      debugPrint('ProximityAttendance: Error marking attended: $e');
    }
  }

  /// Marks participant as "not_attended" and writes record to Firestore.
  Future<void> markNotAttended({
    required String meetupId,
    required String userId,
  }) async {
    try {
      // Idempotence check
      if (await hasAttendanceRecord(meetupId, userId)) {
        debugPrint('ProximityAttendance: $userId already has record for $meetupId, skipping');
        return;
      }

      final record = AttendanceRecordModel(
        userId: userId,
        status: 'not_attended',
        detectedAt: DateTime.now(),
        method: 'gps_proximity',
      );

      await _firestore
          .collection('meetups')
          .doc(meetupId)
          .collection('attendance_records')
          .doc(userId)
          .set(record.toJson());

      debugPrint('ProximityAttendance: Marked $userId as NOT_ATTENDED for $meetupId');

      // Güvenilirlik puanını yeniden hesapla (joined artmaz, non-blocking)
      try {
        await _reliabilityService.recalculateFromCounters(userId);
      } catch (e) {
        debugPrint('ProximityAttendance: Reliability update failed (non-blocking): $e');
      }
    } catch (e) {
      debugPrint('ProximityAttendance: Error marking not attended: $e');
    }
  }

  /// Returns true if an attendance record already exists for this user+meetup.
  Future<bool> hasAttendanceRecord(String meetupId, String userId) async {
    try {
      final doc = await _firestore
          .collection('meetups')
          .doc(meetupId)
          .collection('attendance_records')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('ProximityAttendance: Error checking record: $e');
      return false;
    }
  }

  /// Gets all attendance records for a meetup.
  Future<List<AttendanceRecordModel>> getAttendanceRecords(String meetupId) async {
    try {
      final snapshot = await _firestore
          .collection('meetups')
          .doc(meetupId)
          .collection('attendance_records')
          .get();

      return snapshot.docs
          .map((doc) => AttendanceRecordModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('ProximityAttendance: Error getting records: $e');
      return [];
    }
  }

  /// Gets attendance history for a user (last 90 days).
  /// Returns list of {meetup: MeetupModel, didAttend: bool, record: AttendanceRecordModel?}
  Future<List<Map<String, dynamic>>> getAttendanceHistory(String userId) async {
    try {
      final now = DateTime.now();
      final maxLookback = now.subtract(const Duration(days: 90));

      // Get meetups where user participated
      final meetupsSnapshot = await _firestore
          .collection('meetups')
          .where('participantIds', arrayContains: userId)
          .get();

      final history = <Map<String, dynamic>>[];

      for (final meetupDoc in meetupsSnapshot.docs) {
        final meetup = MeetupModel.fromJson(meetupDoc.data());

        // Skip solo meetups
        if (meetup.participantIds.length < 2) continue;

        // Use effective end date for filtering
        final effectiveDate = meetup.endDate ?? meetup.date;
        if (effectiveDate.isAfter(now)) continue;
        if (effectiveDate.isBefore(maxLookback)) continue;

        // Check attendance record
        final recordDoc = await _firestore
            .collection('meetups')
            .doc(meetupDoc.id)
            .collection('attendance_records')
            .doc(userId)
            .get();

        AttendanceRecordModel? record;
        bool didAttend = false;
        if (recordDoc.exists) {
          record = AttendanceRecordModel.fromJson(recordDoc.data()!);
          didAttend = record.didAttend;
        }

        history.add({
          'meetup': meetup,
          'didAttend': didAttend,
          'record': record,
        });
      }

      // Sort by effective end date descending
      history.sort((a, b) {
        final meetupA = a['meetup'] as MeetupModel;
        final meetupB = b['meetup'] as MeetupModel;
        final dateA = meetupA.endDate ?? meetupA.date;
        final dateB = meetupB.endDate ?? meetupB.date;
        return dateB.compareTo(dateA);
      });

      if (history.length > 50) {
        return history.sublist(0, 50);
      }

      return history;
    } catch (e) {
      debugPrint('ProximityAttendance: Error getting history: $e');
      return [];
    }
  }

  /// Processes cutoff for active meetups: marks "not_attended" for participants
  /// who haven't shown up by the cutoff time.
  Future<void> processCutoffForActiveMeetups(String userId) async {
    try {
      final now = DateTime.now();
      final maxLookback = now.subtract(const Duration(days: 7));

      // Get recent meetups where user participated
      final meetupsSnapshot = await _firestore
          .collection('meetups')
          .where('participantIds', arrayContains: userId)
          .get();

      for (final meetupDoc in meetupsSnapshot.docs) {
        final meetup = MeetupModel.fromJson(meetupDoc.data());

        // Only process meetups that have started
        if (meetup.date.isAfter(now)) continue;

        // Skip very old meetups
        final effectiveDate = meetup.endDate ?? meetup.date;
        if (effectiveDate.isBefore(maxLookback)) continue;

        // Skip solo meetups
        if (meetup.participantIds.length < 2) continue;

        // Calculate cutoff
        final cutoff = calculateCutoffTime(meetup.date, meetup.endDate);

        // If cutoff reached and no record exists → mark not_attended
        if (isCutoffReached(now, cutoff)) {
          final hasRecord = await hasAttendanceRecord(meetupDoc.id, userId);
          if (!hasRecord) {
            await markNotAttended(meetupId: meetupDoc.id, userId: userId);
          }
        }
      }
    } catch (e) {
      debugPrint('ProximityAttendance: Error processing cutoffs: $e');
    }
  }
}
