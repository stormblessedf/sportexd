import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/profile_photo_model.dart';
import '../models/swipe_candidate_model.dart';
import '../models/swipe_invite_model.dart';
import '../models/user_model.dart';
import 'chat_service.dart';

class SwipeDecisionResult {
  final bool premiumRequired;
  final bool inviteCreated;
  final bool autoMatched;
  final SwipeInviteModel? invite;

  const SwipeDecisionResult({
    this.premiumRequired = false,
    this.inviteCreated = false,
    this.autoMatched = false,
    this.invite,
  });
}

class SwipeInviteService {
  final FirebaseFirestore _firestore;
  final ChatService _chatService;

  SwipeInviteService({FirebaseFirestore? firestore, ChatService? chatService})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _chatService = chatService ?? ChatService();

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _photosRef =>
      _firestore.collection('profile_photos');
  CollectionReference<Map<String, dynamic>> get _actionsRef =>
      _firestore.collection('swipe_actions');
  CollectionReference<Map<String, dynamic>> get _invitesRef =>
      _firestore.collection('swipe_invites');

  Future<bool> hasPremiumAccess(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    if (!doc.exists) return false;

    final data = doc.data() ?? {};
    final isPremium = data['isPremium'] == true;
    final premiumUntil = _parseDate(data['premiumUntil']);

    if (isPremium) return true;
    if (premiumUntil != null && premiumUntil.isAfter(DateTime.now())) {
      return true;
    }
    return false;
  }

  Future<List<SwipeCandidateModel>> fetchCandidates({
    required String currentUserId,
    int limit = 25,
  }) async {
    final currentUserDoc = await _usersRef.doc(currentUserId).get();
    if (!currentUserDoc.exists) return [];

    final currentUser = _userFromJson(
      currentUserDoc.data()!,
      fallbackId: currentUserDoc.id,
    );
    final currentSports = (currentUser.interestedSports ?? <SportType>[])
        .map((e) => e.name)
        .toSet();

    // Already-swiped IDs â€” non-fatal if the query fails
    var swipedIds = <String>{};
    try {
      final swipedSnapshot = await _actionsRef
          .where('actorId', isEqualTo: currentUserId)
          .limit(400)
          .get();
      swipedIds = swipedSnapshot.docs
          .map((d) => (d.data()['targetId'] ?? '') as String)
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint(
        'fetchCandidates: swipe_actions query failed (skipping filter): $e',
      );
    }

    // Already-invited IDs â€” non-fatal if the query fails
    final relatedInviteUserIds = <String>{};
    try {
      final inviteSnapshot = await _invitesRef
          .where('participantIds', arrayContains: currentUserId)
          .limit(400)
          .get();
      for (final doc in inviteSnapshot.docs) {
        try {
          final invite = SwipeInviteModel.fromJson(doc.data(), doc.id);
          if (invite.status == SwipeInviteStatus.pending ||
              invite.status == SwipeInviteStatus.accepted) {
            relatedInviteUserIds.add(invite.otherUserId(currentUserId));
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint(
        'fetchCandidates: swipe_invites query failed (skipping filter): $e',
      );
    }

    final usersSnapshot = await _usersRef.limit(200).get();
    final candidates = usersSnapshot.docs
        .where((doc) {
          if (doc.id == currentUserId) return false;
          if (swipedIds.contains(doc.id)) return false;
          if (relatedInviteUserIds.contains(doc.id)) return false;
          return true;
        })
        .map((doc) {
          try {
            return _userFromJson(doc.data(), fallbackId: doc.id);
          } catch (_) {
            return null;
          }
        })
        .whereType<UserModel>()
        .toList();

    final candidateModels = await Future.wait(
      candidates.map((user) async {
        final sports = (user.interestedSports ?? <SportType>[])
            .map((e) => e.name)
            .toSet();
        final commonSportsCount = currentSports.intersection(sports).length;

        List<ProfilePhotoModel> photos = const [];
        try {
          photos = await getUserPhotos(user.id, limit: 4);
        } catch (_) {
          // photos index may not be ready yet â€” proceed without photos
        }
        final reliabilityPart = (user.reliabilityScore / 100.0).clamp(0.0, 1.0);
        final onlineBoost = user.isCurrentlyOnline ? 1.0 : 0.0;
        final score =
            (commonSportsCount * 10) + (reliabilityPart * 5) + onlineBoost;

        return SwipeCandidateModel(
          user: user,
          photos: photos,
          commonSportsCount: commonSportsCount,
          score: score,
        );
      }),
    );

    candidateModels.sort((a, b) => b.score.compareTo(a.score));
    return candidateModels.take(limit).toList();
  }

  Future<void> swipeLeft({
    required String actorId,
    required String targetId,
  }) async {
    await _writeSwipeAction(
      actorId: actorId,
      targetId: targetId,
      decision: 'left',
    );
  }

  Future<SwipeDecisionResult> swipeRight({
    required String actorId,
    required String targetId,
  }) async {
    if (actorId == targetId) {
      return const SwipeDecisionResult();
    }

    final premium = await hasPremiumAccess(actorId);
    if (!premium) {
      return const SwipeDecisionResult(premiumRequired: true);
    }

    await _writeSwipeAction(
      actorId: actorId,
      targetId: targetId,
      decision: 'right',
    );

    final pairId = SwipeInviteModel.generatePairId(actorId, targetId);
    final inviteRef = _invitesRef.doc(pairId);
    var inviteStateChanged = false;
    var autoMatched = false;

    await _firestore.runTransaction((tx) async {
      final existing = await tx.get(inviteRef);
      final nowTs = Timestamp.fromDate(DateTime.now());

      if (!existing.exists) {
        inviteStateChanged = true;
        tx.set(inviteRef, {
          'id': pairId,
          'pairId': pairId,
          'senderId': actorId,
          'receiverId': targetId,
          'participantIds': [actorId, targetId],
          'status': SwipeInviteStatus.pending.value,
          'createdAt': nowTs,
          'updatedAt': nowTs,
          'acceptedAt': null,
          'rejectedAt': null,
          'chatId': null,
        });
        return;
      }

      final data = existing.data()!;
      final status = SwipeInviteStatusX.fromValue(
        (data['status'] ?? 'pending') as String,
      );
      final senderId = (data['senderId'] ?? '') as String;
      final receiverId = (data['receiverId'] ?? '') as String;

      if (status == SwipeInviteStatus.pending &&
          senderId == targetId &&
          receiverId == actorId) {
        inviteStateChanged = true;
        autoMatched = true;
        tx.update(inviteRef, {
          'status': SwipeInviteStatus.accepted.value,
          'updatedAt': nowTs,
          'acceptedAt': nowTs,
          'rejectedAt': null,
        });
        return;
      }

      if (status == SwipeInviteStatus.rejected ||
          status == SwipeInviteStatus.canceled) {
        inviteStateChanged = true;
        tx.update(inviteRef, {
          'senderId': actorId,
          'receiverId': targetId,
          'status': SwipeInviteStatus.pending.value,
          'updatedAt': nowTs,
          'acceptedAt': null,
          'rejectedAt': null,
          'chatId': null,
        });
      }
    });

    final finalDoc = await inviteRef.get();
    if (!finalDoc.exists) {
      return const SwipeDecisionResult();
    }

    final invite = SwipeInviteModel.fromJson(finalDoc.data()!, finalDoc.id);
    if (invite.status == SwipeInviteStatus.accepted) {
      await startChatFromInvite(invite: invite, currentUserId: actorId);
    }

    return SwipeDecisionResult(
      inviteCreated: inviteStateChanged,
      autoMatched: autoMatched,
      invite: invite,
    );
  }

  Stream<List<SwipeInviteModel>> watchIncomingInvites(String userId) {
    return _invitesRef
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: SwipeInviteStatus.pending.value)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => SwipeInviteModel.fromJson(doc.data(), doc.id))
              .toList();
          items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return items;
        });
  }

  Stream<List<SwipeInviteModel>> watchAcceptedInvites(String userId) {
    return _invitesRef
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => SwipeInviteModel.fromJson(doc.data(), doc.id))
              .where((invite) => invite.status == SwipeInviteStatus.accepted)
              .toList();
          items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return items;
        });
  }

  Future<SwipeInviteModel?> acceptInvite({
    required String inviteId,
    required String currentUserId,
  }) async {
    final ref = _invitesRef.doc(inviteId);

    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) {
        throw StateError('Invite not found');
      }

      final data = doc.data()!;
      final receiverId = (data['receiverId'] ?? '') as String;
      final status = SwipeInviteStatusX.fromValue(
        (data['status'] ?? 'pending') as String,
      );

      if (receiverId != currentUserId) {
        throw StateError('Only receiver can accept invite');
      }
      if (status != SwipeInviteStatus.pending) {
        return;
      }

      final nowTs = Timestamp.fromDate(DateTime.now());
      tx.update(ref, {
        'status': SwipeInviteStatus.accepted.value,
        'updatedAt': nowTs,
        'acceptedAt': nowTs,
        'rejectedAt': null,
      });
    });

    final updated = await ref.get();
    if (!updated.exists) return null;
    final invite = SwipeInviteModel.fromJson(updated.data()!, updated.id);
    await startChatFromInvite(invite: invite, currentUserId: currentUserId);
    return invite;
  }

  Future<void> rejectInvite({
    required String inviteId,
    required String currentUserId,
  }) async {
    final ref = _invitesRef.doc(inviteId);

    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) {
        throw StateError('Invite not found');
      }

      final data = doc.data()!;
      final receiverId = (data['receiverId'] ?? '') as String;
      final status = SwipeInviteStatusX.fromValue(
        (data['status'] ?? 'pending') as String,
      );

      if (receiverId != currentUserId) {
        throw StateError('Only receiver can reject invite');
      }
      if (status != SwipeInviteStatus.pending) {
        return;
      }

      final nowTs = Timestamp.fromDate(DateTime.now());
      tx.update(ref, {
        'status': SwipeInviteStatus.rejected.value,
        'updatedAt': nowTs,
        'rejectedAt': nowTs,
      });
    });
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    if (!doc.exists) return null;
    return _userFromJson(doc.data()!, fallbackId: doc.id);
  }

  Future<List<ProfilePhotoModel>> getUserPhotos(
    String userId, {
    int limit = 4,
  }) async {
    if (userId.isEmpty) return const [];

    try {
      final snapshot = await _photosRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return _mapPhotos(snapshot.docs, limit: limit);
    } catch (e) {
      debugPrint(
        'getUserPhotos: indexed query failed for $userId, falling back: $e',
      );
    }

    try {
      final snapshot = await _photosRef
          .where('userId', isEqualTo: userId)
          .limit(limit * 2)
          .get();

      return _mapPhotos(snapshot.docs, limit: limit);
    } catch (e) {
      debugPrint('getUserPhotos: fallback query failed for $userId: $e');
      return const [];
    }
  }

  Future<String?> startChatFromInvite({
    required SwipeInviteModel invite,
    required String currentUserId,
  }) async {
    if (!invite.involves(currentUserId)) {
      throw StateError('Not part of invite');
    }

    if (invite.status != SwipeInviteStatus.accepted) {
      return null;
    }

    final senderDoc = await _usersRef.doc(invite.senderId).get();
    final receiverDoc = await _usersRef.doc(invite.receiverId).get();

    if (!senderDoc.exists || !receiverDoc.exists) {
      throw StateError('User not found for chat');
    }

    final senderName = (senderDoc.data()!['username'] ?? 'User') as String;
    final receiverName = (receiverDoc.data()!['username'] ?? 'User') as String;

    final chatId = await _chatService.getOrCreateDirectChat(
      userId1: invite.senderId,
      userId2: invite.receiverId,
      user1Name: senderName,
      user2Name: receiverName,
    );

    if (invite.chatId == null || invite.chatId!.isEmpty) {
      await _invitesRef.doc(invite.id).set({
        'chatId': chatId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return chatId;
  }

  Future<void> _writeSwipeAction({
    required String actorId,
    required String targetId,
    required String decision,
  }) async {
    final actionId = '${actorId}_$targetId';
    await _actionsRef.doc(actionId).set({
      'actorId': actorId,
      'targetId': targetId,
      'decision': decision,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  UserModel _userFromJson(
    Map<String, dynamic> data, {
    required String fallbackId,
  }) {
    final normalized = Map<String, dynamic>.from(data);
    if ((normalized['id'] as String?)?.isNotEmpty != true) {
      normalized['id'] = fallbackId;
    }
    return UserModel.fromJson(normalized);
  }

  List<ProfilePhotoModel> _mapPhotos(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required int limit,
  }) {
    final items = docs
        .map((doc) {
          final normalized = Map<String, dynamic>.from(doc.data());
          if ((normalized['photoId'] as String?)?.isNotEmpty != true) {
            normalized['photoId'] = doc.id;
          }
          return ProfilePhotoModel.fromJson(normalized);
        })
        .where((photo) => photo.photoUrl.trim().isNotEmpty)
        .toList();

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList();
  }
}
