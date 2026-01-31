import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReliabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculates reliability score
  /// Formula: (totalMeetupsJoined / totalMeetupsRegistered) * 100
  /// New users: 100.0
  double calculateReliabilityScore(int joined, int registered) {
    if (registered == 0) return 100.0;
    if (joined < 0 || registered < 0) {
      throw ArgumentError('Meetup counts cannot be negative');
    }
    if (joined > registered) {
      debugPrint('Warning: joined > registered, fixing data');
      joined = registered;
    }
    return (joined / registered) * 100;
  }

  /// Called when user registers for a meetup
  Future<void> incrementRegisteredMeetups(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) return;

        final data = userDoc.data()!;
        final currentRegistered = data['totalMeetupsRegistered'] ?? 0;
        final currentJoined = data['totalMeetupsJoined'] ?? 0;
        final newRegistered = currentRegistered + 1;

        final newScore = calculateReliabilityScore(currentJoined, newRegistered);

        transaction.update(userRef, {
          'totalMeetupsRegistered': newRegistered,
          'reliabilityScore': newScore,
        });
      });
    } catch (e) {
      debugPrint('Error incrementing registered meetups: $e');
      rethrow;
    }
  }

  /// Called when user actually attends a meetup
  Future<void> incrementJoinedMeetups(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) return;

        final data = userDoc.data()!;
        final currentJoined = data['totalMeetupsJoined'] ?? 0;
        final currentRegistered = data['totalMeetupsRegistered'] ?? 0;
        final newJoined = currentJoined + 1;

        final newScore = calculateReliabilityScore(newJoined, currentRegistered);

        transaction.update(userRef, {
          'totalMeetupsJoined': newJoined,
          'reliabilityScore': newScore,
        });
      });
    } catch (e) {
      debugPrint('Error incrementing joined meetups: $e');
      rethrow;
    }
  }

  /// Called when user misses a meetup (no-show)
  /// This recalculates the score since registered was already incremented
  Future<void> handleMissedMeetup(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) return;

        final data = userDoc.data()!;
        final currentJoined = data['totalMeetupsJoined'] ?? 0;
        final currentRegistered = data['totalMeetupsRegistered'] ?? 0;

        final newScore = calculateReliabilityScore(currentJoined, currentRegistered);

        transaction.update(userRef, {
          'reliabilityScore': newScore,
        });
      });
    } catch (e) {
      debugPrint('Error handling missed meetup: $e');
      rethrow;
    }
  }

  /// Updates reliability score directly
  Future<void> updateReliabilityScore(String userId, double newScore) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'reliabilityScore': newScore.clamp(0.0, 100.0),
      });
    } catch (e) {
      debugPrint('Error updating reliability score: $e');
      rethrow;
    }
  }

  /// Gets user's current reliability score
  Future<double> getReliabilityScore(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return 100.0;
      return (doc.data()?['reliabilityScore'] ?? 100.0).toDouble();
    } catch (e) {
      debugPrint('Error getting reliability score: $e');
      return 100.0;
    }
  }
}
