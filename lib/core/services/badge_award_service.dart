import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sporsal/core/models/user_model.dart';
import 'package:sporsal/features/profile/presentation/models/trophy_definition.dart';
import 'badge_criteria_evaluator.dart';

class BadgeAwardService {
  final FirebaseFirestore _firestore;
  final BadgeCriteriaEvaluator _evaluator;

  BadgeAwardService({
    FirebaseFirestore? firestore,
    BadgeCriteriaEvaluator? evaluator,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _evaluator = evaluator ?? BadgeCriteriaEvaluator();

  Future<List<Badge>> evaluateAndAwardBadges(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return [];

    final user = UserModel.fromJson({...userDoc.data()!, 'id': userId});
    final existingBadgeIds = user.badges.map((b) => b.id).toSet();
    final newBadges = <Badge>[];

    // organizer
    if (!existingBadgeIds.contains('organizer')) {
      final count = await _countOrganizedMeetups(userId);
      if (_evaluator.evaluateOrganizer(count)) {
        newBadges.add(_createBadge('organizer'));
      }
    }

    // loyal
    if (!existingBadgeIds.contains('loyal')) {
      final flags = await _getLastFiveAttendanceFlags(userId);
      if (_evaluator.evaluateLoyal(flags)) {
        newBadges.add(_createBadge('loyal'));
      }
    }

    // streak10
    if (!existingBadgeIds.contains('streak10')) {
      final flags = await _getChronologicalAttendanceFlags(userId);
      if (_evaluator.evaluateStreak10(flags)) {
        newBadges.add(_createBadge('streak10'));
      }
    }

    // social
    if (!existingBadgeIds.contains('social')) {
      if (_evaluator.evaluateSocial(user.partners.length)) {
        newBadges.add(_createBadge('social'));
      }
    }

    // fivestar
    if (!existingBadgeIds.contains('fivestar')) {
      if (_evaluator.evaluateFivestar(user.averageRating, user.totalRatings)) {
        newBadges.add(_createBadge('fivestar'));
      }
    }

    // versatile
    if (!existingBadgeIds.contains('versatile')) {
      final count = await _countUniqueSports(userId);
      if (_evaluator.evaluateVersatile(count)) {
        newBadges.add(_createBadge('versatile'));
      }
    }

    // earlybird
    if (!existingBadgeIds.contains('earlybird')) {
      final count = await _countEarlyBirdMeetups(userId);
      if (_evaluator.evaluateEarlybird(count)) {
        newBadges.add(_createBadge('earlybird'));
      }
    }

    // reliable
    if (!existingBadgeIds.contains('reliable')) {
      if (_evaluator.evaluateReliable(user.reliabilityScore, user.totalMeetupsRegistered)) {
        newBadges.add(_createBadge('reliable'));
      }
    }

    // focused
    if (!existingBadgeIds.contains('focused')) {
      if (_evaluator.evaluateFocused(user.totalMeetupsJoined)) {
        newBadges.add(_createBadge('focused'));
      }
    }

    if (newBadges.isNotEmpty) {
      await _writeBadges(userId, newBadges);
    }

    return newBadges;
  }

  // Task 2.4: Firestore transaction write
  Future<void> _writeBadges(String userId, List<Badge> newBadges) async {
    final userRef = _firestore.collection('users').doc(userId);
    try {
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userRef);
        if (!doc.exists) return;

        final currentBadges = (doc.data()?['badges'] as List<dynamic>?)
                ?.map((e) => Badge.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        final currentIds = currentBadges.map((b) => b.id).toSet();
        final toAdd = newBadges.where((b) => !currentIds.contains(b.id)).toList();

        if (toAdd.isEmpty) return;

        final updatedBadges = [...currentBadges, ...toAdd];
        transaction.update(userRef, {
          'badges': updatedBadges.map((b) => b.toJson()).toList(),
        });
      });
    } catch (e) {
      log('BadgeAwardService: Failed to write badges for $userId: $e');
      rethrow;
    }
  }

  // Task 2.3: TrophyDefinition → Badge conversion
  Badge _createBadge(String trophyId) {
    final trophy = allTrophyDefinitions.firstWhere((t) => t.id == trophyId);
    return Badge(
      id: trophy.id,
      name: trophy.name,
      description: trophy.description,
      iconPath: trophy.emoji,
      type: _mapBadgeType(trophy.id),
    );
  }

  BadgeType _mapBadgeType(String trophyId) {
    switch (trophyId) {
      case 'organizer':
        return BadgeType.organizer;
      case 'loyal':
      case 'streak10':
      case 'focused':
        return BadgeType.participant;
      case 'fivestar':
      case 'reliable':
        return BadgeType.achievement;
      case 'social':
      case 'versatile':
      case 'earlybird':
        return BadgeType.milestone;
      default:
        return BadgeType.participant;
    }
  }

  // Task 2.2: Firestore query helpers
  Future<int> _countOrganizedMeetups(String userId) async {
    final snapshot = await _firestore
        .collection('meetups')
        .where('organizerId', isEqualTo: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _countUniqueSports(String userId) async {
    final snapshot = await _firestore
        .collection('meetups')
        .where('participantIds', arrayContains: userId)
        .get();
    final types = snapshot.docs
        .map((d) => d.data()['type'] as String?)
        .where((t) => t != null)
        .toSet();
    return types.length;
  }

  Future<int> _countEarlyBirdMeetups(String userId) async {
    final snapshot = await _firestore
        .collection('meetups')
        .where('participantIds', arrayContains: userId)
        .get();

    int earlyCount = 0;
    for (final meetupDoc in snapshot.docs) {
      final participantsSnapshot = await meetupDoc.reference
          .collection('participants')
          .orderBy('joinedAt')
          .limit(3)
          .get();
      final earlyIds = participantsSnapshot.docs.map((d) => d.id).toSet();
      if (earlyIds.contains(userId)) earlyCount++;
    }
    return earlyCount;
  }

  Future<List<bool>> _getLastFiveAttendanceFlags(String userId) async {
    final snapshot = await _firestore
        .collection('meetups')
        .where('participantIds', arrayContains: userId)
        .orderBy('date', descending: true)
        .limit(5)
        .get();

    final now = DateTime.now();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
      final participantIds = List<String>.from(data['participantIds'] ?? []);
      return date.isBefore(now) && participantIds.contains(userId);
    }).toList();
  }

  Future<List<bool>> _getChronologicalAttendanceFlags(String userId) async {
    final snapshot = await _firestore
        .collection('meetups')
        .where('participantIds', arrayContains: userId)
        .orderBy('date')
        .get();

    final now = DateTime.now();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
      final participantIds = List<String>.from(data['participantIds'] ?? []);
      return date.isBefore(now) && participantIds.contains(userId);
    }).toList();
  }
}
