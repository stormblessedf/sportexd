import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReliabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _safeInt(dynamic value) {
    final parsed = (value as num?)?.toInt() ?? 0;
    return parsed < 0 ? 0 : parsed;
  }

  /// Formula: (totalMeetupsJoined / totalMeetupsRegistered) * 100
  /// If a user has no registrations yet, score is 100 by default.
  double calculateReliabilityScore(int joined, int registered) {
    if (registered == 0) return 100.0;
    if (joined < 0 || registered < 0) {
      throw ArgumentError('Meetup counts cannot be negative');
    }
    if (joined > registered) {
      debugPrint('Warning: joined > registered, clamping');
      joined = registered;
    }
    return (joined / registered) * 100;
  }

  /// Recomputes and writes reliabilityScore from persisted counters.
  Future<double> recalculateFromCounters(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return 100.0;

      final data = doc.data() ?? const <String, dynamic>{};
      final registered = (data['totalMeetupsRegistered'] as num?)?.toInt() ?? 0;
      final joined = (data['totalMeetupsJoined'] as num?)?.toInt() ?? 0;
      final score = calculateReliabilityScore(
        joined < 0 ? 0 : joined,
        registered < 0 ? 0 : registered,
      );

      await _firestore.collection('users').doc(userId).update({
        'reliabilityScore': score,
      });
      return score;
    } catch (e) {
      debugPrint('Error recalculating reliability from counters: $e');
      return 100.0;
    }
  }

  /// Called when attendance is confirmed: increment totalMeetupsJoined and recalculate score.
  Future<void> incrementJoinedAndRecalculate(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userRef);
        if (!doc.exists) return;

        final data = doc.data() ?? const <String, dynamic>{};
        final currentRegistered = _safeInt(data['totalMeetupsRegistered']);
        final currentJoined = _safeInt(data['totalMeetupsJoined']);
        final nextJoined = currentJoined + 1;
        final boundedJoined =
            nextJoined > currentRegistered ? currentRegistered : nextJoined;
        final score =
            calculateReliabilityScore(boundedJoined, currentRegistered);

        transaction.update(userRef, {
          'totalMeetupsJoined': boundedJoined,
          'reliabilityScore': score,
        });
      });
    } catch (e) {
      debugPrint('Error incrementing joined meetups: $e');
      rethrow;
    }
  }

  /// Called when user registers/joins a meetup.
  Future<void> incrementRegisteredMeetups(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userRef);
        if (!doc.exists) return;

        final data = doc.data() ?? const <String, dynamic>{};
        final currentRegistered = _safeInt(data['totalMeetupsRegistered']);
        final currentJoined = _safeInt(data['totalMeetupsJoined']);
        final nextRegistered = currentRegistered + 1;
        final boundedJoined = currentJoined > nextRegistered ? nextRegistered : currentJoined;
        final score = calculateReliabilityScore(boundedJoined, nextRegistered);

        transaction.update(userRef, {
          'totalMeetupsRegistered': nextRegistered,
          'totalMeetupsJoined': boundedJoined,
          'reliabilityScore': score,
        });
      });
    } catch (e) {
      debugPrint('Error incrementing registered meetups: $e');
      rethrow;
    }
  }

  /// Called when user leaves a meetup before it starts.
  Future<void> decrementRegisteredMeetups(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userRef);
        if (!doc.exists) return;

        final data = doc.data() ?? const <String, dynamic>{};
        final currentRegistered = _safeInt(data['totalMeetupsRegistered']);
        final currentJoined = _safeInt(data['totalMeetupsJoined']);
        final nextRegistered = currentRegistered > 0 ? currentRegistered - 1 : 0;
        final boundedJoined = currentJoined > nextRegistered ? nextRegistered : currentJoined;
        final score = calculateReliabilityScore(boundedJoined, nextRegistered);

        transaction.update(userRef, {
          'totalMeetupsRegistered': nextRegistered,
          'totalMeetupsJoined': boundedJoined,
          'reliabilityScore': score,
        });
      });
    } catch (e) {
      debugPrint('Error decrementing registered meetups: $e');
      rethrow;
    }
  }

  Future<double> getReliabilityScore(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return 100.0;
      return (doc.data()?['reliabilityScore'] as num?)?.toDouble() ?? 100.0;
    } catch (e) {
      debugPrint('Error getting reliability score: $e');
      return 100.0;
    }
  }
}
