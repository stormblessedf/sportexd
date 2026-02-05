import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/partnership_model.dart';
import '../models/partnership_suggestion_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';

class PartnershipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  CollectionReference get _partnersRef => _firestore.collection('partners');
  CollectionReference get _usersRef => _firestore.collection('users');
  CollectionReference get _meetupsRef => _firestore.collection('meetups');

  /// Generate consistent partnership ID from two user IDs
  static String generatePartnershipId(String uid1, String uid2) {
    return PartnershipModel.generateId(uid1, uid2);
  }

  /// Get shared completed meetup IDs between two users
  Future<List<String>> getSharedMeetupIds(String userId1, String userId2) async {
    try {
      // Query meetups where userId1 participated
      final meetups1 = await _meetupsRef
          .where('participantIds', arrayContains: userId1)
          .get();

      final sharedMeetupIds = <String>[];
      final now = DateTime.now();

      for (final doc in meetups1.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final participantIds = (data['participantIds'] as List<dynamic>?)?.cast<String>() ?? [];

        if (!participantIds.contains(userId2)) continue;

        // Parse start date
        DateTime? meetupDate;
        final dateValue = data['date'];
        if (dateValue is Timestamp) {
          meetupDate = dateValue.toDate();
        } else if (dateValue is String) {
          meetupDate = DateTime.tryParse(dateValue);
        }

        // Parse end date
        DateTime? endDate;
        final endDateValue = data['endDate'];
        if (endDateValue is Timestamp) {
          endDate = endDateValue.toDate();
        } else if (endDateValue is String) {
          endDate = DateTime.tryParse(endDateValue);
        }

        // Event counts as "past" if:
        // 1. endDate exists and is before now, OR
        // 2. start date is before now, OR
        // 3. event date (calendar day) is today or earlier
        bool isPast = false;
        if (endDate != null && endDate.isBefore(now)) {
          isPast = true;
        } else if (meetupDate != null && meetupDate.isBefore(now)) {
          isPast = true;
        } else if (meetupDate != null) {
          // Same calendar day check: if event is today, count it
          final meetupDay = DateTime(meetupDate.year, meetupDate.month, meetupDate.day);
          final today = DateTime(now.year, now.month, now.day);
          if (!meetupDay.isAfter(today)) {
            isPast = true;
          }
        }

        if (isPast) {
          sharedMeetupIds.add(doc.id);
        }
      }

      debugPrint('getSharedMeetupIds($userId1, $userId2): found ${sharedMeetupIds.length} shared meetups');
      return sharedMeetupIds;
    } catch (e) {
      debugPrint('Error getting shared meetup IDs: $e');
      return [];
    }
  }

  /// Check if two users have shared completed meetups
  Future<bool> hasSharedMeetups(String userId1, String userId2) async {
    final ids = await getSharedMeetupIds(userId1, userId2);
    return ids.isNotEmpty;
  }

  /// Get shared meetup count between two users
  Future<int> getSharedMeetupCount(String userId1, String userId2) async {
    final ids = await getSharedMeetupIds(userId1, userId2);
    return ids.length;
  }

  /// Get partnership status between two users
  Future<PartnershipModel?> getPartnershipStatus(String userId1, String userId2) async {
    try {
      final partnershipId = generatePartnershipId(userId1, userId2);
      final doc = await _partnersRef.doc(partnershipId).get();

      if (!doc.exists) return null;
      return PartnershipModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting partnership status: $e');
      return null;
    }
  }

  /// Send a partnership request
  Future<void> sendPartnershipRequest({
    required String requesterId,
    required String receiverId,
    required List<String> sharedMeetupIds,
  }) async {
    if (sharedMeetupIds.isEmpty) {
      throw ArgumentError('En az bir ortak etkinlik gerekli');
    }

    final partnershipId = generatePartnershipId(requesterId, receiverId);

    // Check for existing partnership
    final existing = await _partnersRef.doc(partnershipId).get();
    if (existing.exists) {
      final data = existing.data() as Map<String, dynamic>;
      final status = data['status'];
      if (status == 'blocked') {
        throw StateError('Bu kullanıcıya istek gönderemezsiniz');
      }
      if (status == 'pending' || status == 'accepted') {
        throw StateError('Bu kullanıcıyla zaten bir partner isteğiniz var');
      }
    }

    final now = DateTime.now();
    final partnership = PartnershipModel(
      id: partnershipId,
      userId: requesterId,
      partnerId: receiverId,
      status: PartnershipStatus.pending,
      sharedMeetupIds: sharedMeetupIds,
      requestedAt: now,
      createdAt: now,
    );

    await _partnersRef.doc(partnershipId).set(partnership.toJson());

    // Send notification to receiver
    try {
      final requesterDoc = await _usersRef.doc(requesterId).get();
      final requesterName = (requesterDoc.data() as Map<String, dynamic>?)?['username'] ?? 'Bir kullanıcı';

      await _notificationService.createNotification(
        userId: receiverId,
        type: NotificationType.partnershipRequest,
        title: 'Yeni Partner İsteği',
        message: '$requesterName seni spor partneri olarak eklemek istiyor',
        relatedId: partnershipId,
        metadata: {'requesterId': requesterId},
      );
    } catch (e) {
      debugPrint('Error sending partnership notification: $e');
    }
  }

  /// Accept a partnership request
  Future<void> acceptPartnershipRequest(String partnershipId) async {
    try {
      final doc = await _partnersRef.doc(partnershipId).get();
      if (!doc.exists) throw StateError('Partner isteği bulunamadı');

      final partnership = PartnershipModel.fromJson(doc.data() as Map<String, dynamic>);
      if (partnership.status != PartnershipStatus.pending) {
        throw StateError('Bu istek zaten yanıtlanmış');
      }

      final batch = _firestore.batch();

      // Update partnership status
      batch.update(_partnersRef.doc(partnershipId), {
        'status': 'accepted',
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update both users' partners arrays and counts
      batch.update(_usersRef.doc(partnership.userId), {
        'partners': FieldValue.arrayUnion([partnership.partnerId]),
        'partnersCount': FieldValue.increment(1),
      });
      batch.update(_usersRef.doc(partnership.partnerId), {
        'partners': FieldValue.arrayUnion([partnership.userId]),
        'partnersCount': FieldValue.increment(1),
      });

      await batch.commit();

      // Send notification to requester
      try {
        final accepterDoc = await _usersRef.doc(partnership.partnerId).get();
        final accepterName = (accepterDoc.data() as Map<String, dynamic>?)?['username'] ?? 'Bir kullanıcı';

        await _notificationService.createNotification(
          userId: partnership.userId,
          type: NotificationType.partnershipAccepted,
          title: 'Partner İsteği Kabul Edildi',
          message: '$accepterName partner isteğini kabul etti',
          relatedId: partnershipId,
          metadata: {'accepterId': partnership.partnerId},
        );
      } catch (e) {
        debugPrint('Error sending acceptance notification: $e');
      }
    } catch (e) {
      debugPrint('Error accepting partnership: $e');
      rethrow;
    }
  }

  /// Reject a partnership request
  Future<void> rejectPartnershipRequest(String partnershipId) async {
    try {
      await _partnersRef.doc(partnershipId).update({
        'status': 'rejected',
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error rejecting partnership: $e');
      rethrow;
    }
  }

  /// Block a partnership request
  Future<void> blockPartnershipRequest(String partnershipId) async {
    try {
      await _partnersRef.doc(partnershipId).update({
        'status': 'blocked',
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error blocking partnership: $e');
      rethrow;
    }
  }

  /// Delete a partnership
  Future<void> deletePartnership(String partnershipId) async {
    try {
      final doc = await _partnersRef.doc(partnershipId).get();
      if (!doc.exists) return;

      final partnership = PartnershipModel.fromJson(doc.data() as Map<String, dynamic>);

      final batch = _firestore.batch();

      // Remove partnership document
      batch.delete(_partnersRef.doc(partnershipId));

      // Update both users if partnership was accepted
      if (partnership.status == PartnershipStatus.accepted) {
        batch.update(_usersRef.doc(partnership.userId), {
          'partners': FieldValue.arrayRemove([partnership.partnerId]),
          'partnersCount': FieldValue.increment(-1),
        });
        batch.update(_usersRef.doc(partnership.partnerId), {
          'partners': FieldValue.arrayRemove([partnership.userId]),
          'partnersCount': FieldValue.increment(-1),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting partnership: $e');
      rethrow;
    }
  }

  /// Cancel a pending outgoing request
  Future<void> cancelRequest(String partnershipId) async {
    try {
      await _partnersRef.doc(partnershipId).delete();
    } catch (e) {
      debugPrint('Error cancelling request: $e');
      rethrow;
    }
  }

  /// Get all accepted partners for a user
  Future<List<UserModel>> getPartners(String userId) async {
    try {
      final userDoc = await _usersRef.doc(userId).get();
      if (!userDoc.exists) return [];

      final data = userDoc.data() as Map<String, dynamic>;
      final partnerIds = (data['partners'] as List<dynamic>?)?.cast<String>() ?? [];

      if (partnerIds.isEmpty) return [];

      final partners = <UserModel>[];
      // Fetch in batches of 10 (Firestore whereIn limit)
      for (var i = 0; i < partnerIds.length; i += 10) {
        final batchIds = partnerIds.sublist(i, (i + 10).clamp(0, partnerIds.length));
        final snapshot = await _usersRef.where(FieldPath.documentId, whereIn: batchIds).get();
        for (final doc in snapshot.docs) {
          partners.add(UserModel.fromJson(doc.data() as Map<String, dynamic>));
        }
      }

      return partners;
    } catch (e) {
      debugPrint('Error getting partners: $e');
      return [];
    }
  }

  /// Get pending incoming requests
  Future<List<PartnershipModel>> getIncomingRequests(String userId) async {
    try {
      final snapshot = await _partnersRef
          .where('partnerId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs
          .map((doc) => PartnershipModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting incoming requests: $e');
      return [];
    }
  }

  /// Get pending outgoing requests
  Future<List<PartnershipModel>> getOutgoingRequests(String userId) async {
    try {
      final snapshot = await _partnersRef
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs
          .map((doc) => PartnershipModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting outgoing requests: $e');
      return [];
    }
  }

  /// Get mutual partners between two users
  Future<List<UserModel>> getMutualPartners(String userId1, String userId2) async {
    try {
      final user1Doc = await _usersRef.doc(userId1).get();
      final user2Doc = await _usersRef.doc(userId2).get();

      if (!user1Doc.exists || !user2Doc.exists) return [];

      final partners1 = ((user1Doc.data() as Map<String, dynamic>)['partners'] as List<dynamic>?)?.cast<String>().toSet() ?? {};
      final partners2 = ((user2Doc.data() as Map<String, dynamic>)['partners'] as List<dynamic>?)?.cast<String>().toSet() ?? {};

      final mutualIds = partners1.intersection(partners2).take(3).toList();
      if (mutualIds.isEmpty) return [];

      final snapshot = await _usersRef.where(FieldPath.documentId, whereIn: mutualIds).get();
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting mutual partners: $e');
      return [];
    }
  }

  /// Check for partnership suggestion after rating
  Future<PartnershipSuggestionModel?> checkForSuggestion({
    required String raterId,
    required String ratedUserId,
    required String meetupId,
    required int stars,
    required bool attended,
  }) async {
    // Only suggest if attended and rated 4-5 stars
    if (!attended || stars < 4) return null;

    // Check if partnership already exists
    final existing = await getPartnershipStatus(raterId, ratedUserId);
    if (existing != null) {
      // Already accepted or pending - no need to suggest
      if (existing.status == PartnershipStatus.accepted ||
          existing.status == PartnershipStatus.pending) {
        debugPrint('Partnership already exists (${existing.status}), skipping suggestion');
        return null;
      }
      // If rejected or blocked, also skip
      if (existing.status == PartnershipStatus.blocked) {
        return null;
      }
      // If rejected, allow re-suggestion by deleting old rejected record
      if (existing.status == PartnershipStatus.rejected) {
        await _partnersRef.doc(existing.id).delete();
      }
    }

    // Get rated user's name
    try {
      final userDoc = await _usersRef.doc(ratedUserId).get();
      if (!userDoc.exists) return null;
      final userName = (userDoc.data() as Map<String, dynamic>)['username'] ?? '';

      return PartnershipSuggestionModel(
        suggestedUserId: ratedUserId,
        suggestedUserName: userName,
        meetupId: meetupId,
        stars: stars,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error checking for suggestion: $e');
      return null;
    }
  }

  /// Stream partnership document for real-time updates
  Stream<PartnershipModel?> streamPartnership(String userId1, String userId2) {
    final partnershipId = generatePartnershipId(userId1, userId2);
    return _partnersRef.doc(partnershipId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PartnershipModel.fromJson(doc.data() as Map<String, dynamic>);
    });
  }

  /// Get partnership details with user info for display
  Future<Map<String, dynamic>?> getPartnershipWithDetails(String partnershipId, String currentUserId) async {
    try {
      final doc = await _partnersRef.doc(partnershipId).get();
      if (!doc.exists) return null;

      final partnership = PartnershipModel.fromJson(doc.data() as Map<String, dynamic>);
      final otherUserId = partnership.getOtherUserId(currentUserId);
      final otherUserDoc = await _usersRef.doc(otherUserId).get();

      if (!otherUserDoc.exists) return null;

      final otherUser = UserModel.fromJson(otherUserDoc.data() as Map<String, dynamic>);
      final sharedMeetupCount = await getSharedMeetupCount(currentUserId, otherUserId);

      return {
        'partnership': partnership,
        'otherUser': otherUser,
        'sharedMeetupCount': sharedMeetupCount,
      };
    } catch (e) {
      debugPrint('Error getting partnership details: $e');
      return null;
    }
  }
}
