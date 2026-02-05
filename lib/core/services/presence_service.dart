import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _presenceTimer;

  static const int onlineThresholdMinutes = 5;
  static const int updateIntervalMinutes = 2;

  /// Sets user as online
  Future<void> setUserOnline(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'isOnline': true,
        'lastSeen': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error setting user online: $e');
    }
  }

  /// Sets user as offline
  Future<void> setUserOffline(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'isOnline': false,
        'lastSeen': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error setting user offline: $e');
    }
  }

  /// Updates last seen timestamp
  Future<void> updateLastSeen(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'lastSeen': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating last seen: $e');
    }
  }

  /// Checks if user is online (last seen within 5 minutes)
  bool isOnline(DateTime? lastSeen) {
    if (lastSeen == null) return false;

    // Handle future dates
    if (lastSeen.isAfter(DateTime.now())) {
      debugPrint('Warning: lastSeen is in the future');
      return true; // Assume online if time is ahead
    }

    final difference = DateTime.now().difference(lastSeen);
    return difference.inMinutes <= onlineThresholdMinutes;
  }

  /// Checks if a specific user is online
  Future<bool> isUserOnline(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final lastSeenStr = doc.data()?['lastSeen'];
      if (lastSeenStr == null) return false;

      final lastSeen = DateTime.parse(lastSeenStr);
      return isOnline(lastSeen);
    } catch (e) {
      debugPrint('Error checking if user is online: $e');
      return false;
    }
  }

  /// Watches user's online status in realtime
  Stream<bool> watchUserOnlineStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;

      final lastSeenStr = snapshot.data()?['lastSeen'];
      if (lastSeenStr == null) return false;

      try {
        final lastSeen = DateTime.parse(lastSeenStr);
        return isOnline(lastSeen);
      } catch (e) {
        return false;
      }
    });
  }

  /// Starts periodic presence updates
  void startPresenceUpdates(String userId) {
    // Initial update
    setUserOnline(userId);

    // Cancel existing timer
    _presenceTimer?.cancel();

    // Start periodic updates
    _presenceTimer = Timer.periodic(
      const Duration(minutes: updateIntervalMinutes),
      (_) => updateLastSeen(userId),
    );
  }

  /// Stops presence updates
  void stopPresenceUpdates(String userId) {
    _presenceTimer?.cancel();
    _presenceTimer = null;
    setUserOffline(userId);
  }

  /// Disposes resources
  void dispose() {
    _presenceTimer?.cancel();
    _presenceTimer = null;
  }
}
