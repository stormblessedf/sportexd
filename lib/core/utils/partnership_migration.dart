import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/partnership_model.dart';

/// Migration utility to transition from follower/following to partnership system.
/// Scans past meetups and auto-creates ACCEPTED partnerships for users
/// who have completed events together.
class PartnershipMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Full migration:
  /// 1. Clean old follower/following fields from all users
  /// 2. Scan all past meetups and find user pairs who attended together
  /// 3. Create ACCEPTED partnerships for each pair
  /// 4. Update user partner arrays and counts
  Future<void> migrate() async {
    debugPrint('=== Partnership Migration Started ===');

    try {
      // Step 1: Clean old fields
      await _cleanOldFields();

      // Step 2: Scan meetups and create partnerships
      await _createPartnershipsFromMeetups();

      // Step 3: Sync partnersCount with actual partners array length
      await _syncPartnerCounts();

      debugPrint('=== Partnership Migration Complete ===');
    } catch (e) {
      debugPrint('Migration error: $e');
      rethrow;
    }
  }

  /// Step 1: Remove old follower/following fields, initialize partners
  Future<void> _cleanOldFields() async {
    debugPrint('Step 1: Cleaning old follower/following fields...');
    final usersSnapshot = await _firestore.collection('users').get();
    int cleanedCount = 0;

    for (final userDoc in usersSnapshot.docs) {
      final data = userDoc.data();

      final hasOldFields = data.containsKey('followers') ||
          data.containsKey('following') ||
          data.containsKey('followersCount') ||
          data.containsKey('followingCount');

      if (hasOldFields) {
        await _firestore.collection('users').doc(userDoc.id).update({
          'followers': FieldValue.delete(),
          'following': FieldValue.delete(),
          'followersCount': FieldValue.delete(),
          'followingCount': FieldValue.delete(),
        });
        cleanedCount++;
      }

      // Ensure partners fields exist
      if (!data.containsKey('partners')) {
        await _firestore.collection('users').doc(userDoc.id).update({
          'partners': [],
          'partnersCount': 0,
        });
      }
    }

    debugPrint('  Cleaned $cleanedCount users with old fields.');
  }

  /// Step 2: Scan all past meetups and create ACCEPTED partnerships
  /// for every pair of users who attended the same event.
  Future<void> _createPartnershipsFromMeetups() async {
    debugPrint('Step 2: Scanning past meetups for shared participants...');

    final now = DateTime.now();
    final meetupsSnapshot = await _firestore.collection('meetups').get();

    // Collect all user pairs and their shared meetup IDs
    final Map<String, Set<String>> pairMeetups = {};

    for (final meetupDoc in meetupsSnapshot.docs) {
      final data = meetupDoc.data();
      final participantIds =
          (data['participantIds'] as List<dynamic>?)?.cast<String>() ?? [];

      // Check if meetup is in the past (use endDate if available)
      DateTime? meetupDate;
      final dateValue = data['date'];
      if (dateValue is Timestamp) {
        meetupDate = dateValue.toDate();
      } else if (dateValue is String) {
        meetupDate = DateTime.tryParse(dateValue);
      }

      DateTime? endDate;
      final endDateValue = data['endDate'];
      if (endDateValue is Timestamp) {
        endDate = endDateValue.toDate();
      } else if (endDateValue is String) {
        endDate = DateTime.tryParse(endDateValue);
      }

      // Consider past if endDate or date is before now, or date is today
      final effectiveDate = endDate ?? meetupDate;
      if (effectiveDate == null) continue;
      final eventDay = DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day);
      final today = DateTime(now.year, now.month, now.day);
      if (eventDay.isAfter(today)) continue;
      if (participantIds.length < 2) continue;

      // Generate all unique pairs from participants
      for (int i = 0; i < participantIds.length; i++) {
        for (int j = i + 1; j < participantIds.length; j++) {
          final pairId =
              PartnershipModel.generateId(participantIds[i], participantIds[j]);
          pairMeetups.putIfAbsent(pairId, () => {});
          pairMeetups[pairId]!.add(meetupDoc.id);
        }
      }
    }

    debugPrint('  Found ${pairMeetups.length} unique user pairs from past meetups.');

    // Create partnerships for each pair
    int createdCount = 0;
    int skippedCount = 0;

    for (final entry in pairMeetups.entries) {
      final partnershipId = entry.key;
      final sharedMeetupIds = entry.value.toList();

      // Check if partnership already exists
      final existingDoc =
          await _firestore.collection('partners').doc(partnershipId).get();
      if (existingDoc.exists) {
        skippedCount++;
        continue;
      }

      // Extract user IDs from partnership ID (format: uid1_uid2)
      final parts = partnershipId.split('_');
      if (parts.length != 2) continue;
      final userId = parts[0];
      final partnerId = parts[1];

      // Create ACCEPTED partnership
      final partnership = PartnershipModel(
        id: partnershipId,
        userId: userId,
        partnerId: partnerId,
        status: PartnershipStatus.accepted,
        sharedMeetupIds: sharedMeetupIds,
        requestedAt: now,
        respondedAt: now,
        createdAt: now,
      );

      final batch = _firestore.batch();

      // Create partnership document
      batch.set(
        _firestore.collection('partners').doc(partnershipId),
        partnership.toJson(),
      );

      // Update both users' partners arrays and counts
      batch.update(_firestore.collection('users').doc(userId), {
        'partners': FieldValue.arrayUnion([partnerId]),
        'partnersCount': FieldValue.increment(1),
      });
      batch.update(_firestore.collection('users').doc(partnerId), {
        'partners': FieldValue.arrayUnion([userId]),
        'partnersCount': FieldValue.increment(1),
      });

      await batch.commit();
      createdCount++;
    }

    debugPrint(
        '  Created $createdCount partnerships, skipped $skippedCount existing.');
  }

  /// Step 3: Ensure partnersCount matches partners array length for all users
  Future<void> _syncPartnerCounts() async {
    debugPrint('Step 3: Syncing partner counts...');
    final usersSnapshot = await _firestore.collection('users').get();
    int fixedCount = 0;

    for (final userDoc in usersSnapshot.docs) {
      final data = userDoc.data();
      final partners =
          (data['partners'] as List<dynamic>?)?.cast<String>() ?? [];
      final storedCount = (data['partnersCount'] as num?)?.toInt() ?? 0;

      if (storedCount != partners.length) {
        await _firestore.collection('users').doc(userDoc.id).update({
          'partnersCount': partners.length,
        });
        fixedCount++;
      }
    }

    debugPrint('  Fixed $fixedCount users with mismatched partner counts.');
  }
}
