import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/meetup_model.dart';
import '../models/profile_photo_model.dart';
import '../models/swipe_candidate_model.dart';
import '../models/swipe_invite_model.dart';
import '../models/user_model.dart';
import 'chat_service.dart';
import 'meetup_service.dart';

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
  static const List<String> _blockingInviteStatuses = <String>[
    'pending',
    'accepted',
  ];

  final FirebaseFirestore _firestore;
  final ChatService _chatService;
  final MeetupService _meetupService;

  SwipeInviteService({
    FirebaseFirestore? firestore,
    ChatService? chatService,
    MeetupService? meetupService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _chatService = chatService ?? ChatService(),
        _meetupService = meetupService ?? MeetupService();

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

  Future<List<MeetupModel>> fetchOrganizerMeetups(String userId) async {
    try {
      final snap = await _firestore
          .collection('meetups')
          .where('organizerId', isEqualTo: userId)
          .orderBy('date', descending: false)
          .limit(20)
          .get();
      final now = DateTime.now();
      return snap.docs
          .map((d) {
            try {
              return MeetupModel.fromJson({...d.data(), 'id': d.id});
            } catch (_) {
              return null;
            }
          })
          .whereType<MeetupModel>()
          .where((m) => m.date.isAfter(now.subtract(const Duration(hours: 2))))
          .toList();
    } catch (e) {
      debugPrint('fetchOrganizerMeetups error: $e');
      return [];
    }
  }

  Future<List<SwipeCandidateModel>> fetchCandidates({
    required String currentUserId,
    MeetupType? sportFilter,
    String? genderFilter,
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

    final excludedIds = await _loadExcludedCandidateIds(currentUserId);

    final candidateUsers = await _loadCandidateUsers(
      excludedIds: excludedIds,
      sportFilter: sportFilter,
      currentSports: currentSports,
      genderFilter: genderFilter,
      limit: limit,
    );

    final rankedCandidates = candidateUsers
        .map((user) {
        final sports = (user.interestedSports ?? <SportType>[])
            .map((e) => e.name)
            .toSet();
        final commonSportsCount = currentSports.intersection(sports).length;

        final reliabilityPart =
            (user.reliabilityScore / 100.0).clamp(0.0, 1.0);
        final onlineBoost = user.isCurrentlyOnline ? 1.0 : 0.0;
        final sportBoost = (sportFilter != null &&
                (user.interestedSports ?? [])
                    .any((s) => s.name == sportFilter.name))
            ? 5.0
            : 0.0;
        final score = (commonSportsCount * 10) +
            (reliabilityPart * 5) +
            onlineBoost +
            sportBoost;

        return SwipeCandidateModel(
          user: user,
          commonSportsCount: commonSportsCount,
          score: score,
        );
      })
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final topCandidates = rankedCandidates.take(limit).toList();
    final photoEnrichmentCount =
        topCandidates.length < 12 ? topCandidates.length : 12;

    final enrichedTopCandidates = await Future.wait(
      topCandidates.take(photoEnrichmentCount).map((candidate) async {
        try {
          final photos = await getUserPhotos(candidate.user.id, limit: 1);
          return SwipeCandidateModel(
            user: candidate.user,
            photos: photos,
            commonSportsCount: candidate.commonSportsCount,
            score: candidate.score,
          );
        } catch (_) {
          return candidate;
        }
      }),
    );

    return [
      ...enrichedTopCandidates,
      ...topCandidates.skip(photoEnrichmentCount),
    ];
  }

  Future<Set<String>> _loadExcludedCandidateIds(String currentUserId) async {
    final excludedIds = <String>{currentUserId};

    try {
      final results = await Future.wait([
        _actionsRef
            .where('actorId', isEqualTo: currentUserId)
            .orderBy('createdAt', descending: true)
            .limit(300)
            .get(),
        _invitesRef
            .where('senderId', isEqualTo: currentUserId)
            .where('status', whereIn: _blockingInviteStatuses)
            .orderBy('updatedAt', descending: true)
            .limit(120)
            .get(),
        _invitesRef
            .where('receiverId', isEqualTo: currentUserId)
            .where('status', whereIn: _blockingInviteStatuses)
            .orderBy('updatedAt', descending: true)
            .limit(120)
            .get(),
      ]);

      final actionsSnapshot = results[0];
      final sentInvitesSnapshot = results[1];
      final receivedInvitesSnapshot = results[2];

      for (final doc in actionsSnapshot.docs) {
        final targetId = (doc.data()['targetId'] as String?)?.trim();
        if (targetId != null && targetId.isNotEmpty) {
          excludedIds.add(targetId);
        }
      }

      for (final snapshot in [sentInvitesSnapshot, receivedInvitesSnapshot]) {
        for (final doc in snapshot.docs) {
          try {
            final invite = SwipeInviteModel.fromJson(doc.data(), doc.id);
            excludedIds.add(invite.otherUserId(currentUserId));
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('fetchCandidates: exclusion queries failed: $e');
    }

    return excludedIds;
  }

  Future<List<UserModel>> _loadCandidateUsers({
    required Set<String> excludedIds,
    required MeetupType? sportFilter,
    required Set<String> currentSports,
    required String? genderFilter,
    required int limit,
  }) async {
    final prioritizedSports = <String>[
      if (sportFilter != null) sportFilter.name,
      ...currentSports,
    ].toSet().take(10).toList();

    final stagedFetchLimit = (limit * 2).clamp(30, 80).toInt();
    final broadFetchLimit = (limit * 3).clamp(45, 120).toInt();
    final queries = <Query<Map<String, dynamic>>>[];

    if (sportFilter != null) {
      queries.add(
        _usersRef
            .where('interestedSports', arrayContains: sportFilter.name)
            .limit(stagedFetchLimit),
      );
    }
    if (prioritizedSports.length == 1) {
      queries.add(
        _usersRef
            .where('interestedSports', arrayContains: prioritizedSports.first)
            .limit(stagedFetchLimit),
      );
    } else if (prioritizedSports.length > 1) {
      queries.add(
        _usersRef
            .where('interestedSports', arrayContainsAny: prioritizedSports)
            .limit(broadFetchLimit),
      );
    }
    queries.add(_usersRef.limit(broadFetchLimit));

    final candidatesById = <String, UserModel>{};
    for (final query in queries) {
      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        if (excludedIds.contains(doc.id) || candidatesById.containsKey(doc.id)) {
          continue;
        }

        try {
          final user = _userFromJson(doc.data(), fallbackId: doc.id);
          if (!_matchesCandidateFilters(
            user: user,
            sportFilter: sportFilter,
            genderFilter: genderFilter,
          )) {
            continue;
          }
          candidatesById[user.id] = user;
        } catch (_) {}
      }

      if (candidatesById.length >= limit * 3) {
        break;
      }
    }

    return candidatesById.values.toList();
  }

  bool _matchesCandidateFilters({
    required UserModel user,
    required MeetupType? sportFilter,
    required String? genderFilter,
  }) {
    if (genderFilter != null && genderFilter.isNotEmpty) {
      final normalizedGender = (user.gender ?? '').toLowerCase().trim();
      if (normalizedGender != genderFilter.toLowerCase().trim()) {
        return false;
      }
    }

    if (sportFilter != null) {
      final sports = (user.interestedSports ?? <SportType>[])
          .map((e) => e.name)
          .toSet();
      if (!sports.contains(sportFilter.name)) {
        return false;
      }
    }

    return true;
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
    required String senderName,
    String? senderImageUrl,
    SwipeInviteContext inviteContext = SwipeInviteContext.sport,
    String? sportType,
    String? meetupId,
    String? meetupTitle,
  }) async {
    if (actorId == targetId) {
      return const SwipeDecisionResult();
    }

    await _writeSwipeAction(
      actorId: actorId,
      targetId: targetId,
      decision: 'right',
    );

    return _createOrUpdateInvite(
      actorId: actorId,
      targetId: targetId,
      senderName: senderName,
      senderImageUrl: senderImageUrl,
      inviteContext: inviteContext,
      sportType: sportType,
      meetupId: meetupId,
      meetupTitle: meetupTitle,
    );
  }

  Future<SwipeDecisionResult> sendInvite({
    required String actorId,
    required String targetId,
    required String senderName,
    String? senderImageUrl,
    SwipeInviteContext inviteContext = SwipeInviteContext.sport,
    String? sportType,
    String? meetupId,
    String? meetupTitle,
  }) async {
    if (actorId == targetId) {
      return const SwipeDecisionResult();
    }

    return _createOrUpdateInvite(
      actorId: actorId,
      targetId: targetId,
      senderName: senderName,
      senderImageUrl: senderImageUrl,
      inviteContext: inviteContext,
      sportType: sportType,
      meetupId: meetupId,
      meetupTitle: meetupTitle,
    );
  }

  Future<SwipeDecisionResult> _createOrUpdateInvite({
    required String actorId,
    required String targetId,
    required String senderName,
    String? senderImageUrl,
    SwipeInviteContext inviteContext = SwipeInviteContext.sport,
    String? sportType,
    String? meetupId,
    String? meetupTitle,
  }) async {
    final pairId = SwipeInviteModel.generatePairId(actorId, targetId);
    final inviteRef = _invitesRef.doc(pairId);

    final txResult = <String, bool>{'stateChanged': false, 'autoMatched': false};

    await _firestore.runTransaction((tx) async {
      txResult['stateChanged'] = false;
      txResult['autoMatched'] = false;

      final existing = await tx.get(inviteRef);
      final nowTs = Timestamp.fromDate(DateTime.now());

      if (!existing.exists) {
        txResult['stateChanged'] = true;
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
          'inviteContext':
              inviteContext == SwipeInviteContext.meetup ? 'meetup' : 'sport',
          'sportType': sportType,
          'meetupId': meetupId,
          'meetupTitle': meetupTitle,
          'senderName': senderName,
          'senderImageUrl': senderImageUrl,
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
        txResult['stateChanged'] = true;
        txResult['autoMatched'] = true;
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
        txResult['stateChanged'] = true;
        tx.update(inviteRef, {
          'senderId': actorId,
          'receiverId': targetId,
          'status': SwipeInviteStatus.pending.value,
          'updatedAt': nowTs,
          'acceptedAt': null,
          'rejectedAt': null,
          'chatId': null,
          'inviteContext':
              inviteContext == SwipeInviteContext.meetup ? 'meetup' : 'sport',
          'sportType': sportType,
          'meetupId': meetupId,
          'meetupTitle': meetupTitle,
          'senderName': senderName,
          'senderImageUrl': senderImageUrl,
        });
      }
    });

    final inviteStateChanged = txResult['stateChanged']!;
    final autoMatched = txResult['autoMatched']!;

    final finalDoc = await inviteRef.get();
    if (!finalDoc.exists) {
      return const SwipeDecisionResult();
    }

    final invite = SwipeInviteModel.fromJson(finalDoc.data()!, finalDoc.id);
    if (invite.status == SwipeInviteStatus.accepted) {
      await _handleAcceptedInvite(invite: invite, currentUserId: actorId);
    }

    return SwipeDecisionResult(
      inviteCreated: inviteStateChanged,
      autoMatched: autoMatched,
      invite: invite,
    );
  }

  Stream<List<SwipeInviteModel>> watchIncomingInvites(String userId) async* {
    try {
      await for (final snapshot
          in _invitesRef
              .where('receiverId', isEqualTo: userId)
              .where('status', isEqualTo: SwipeInviteStatus.pending.value)
              .orderBy('updatedAt', descending: true)
              .snapshots()) {
        final items = snapshot.docs
            .map((doc) {
              try {
                return SwipeInviteModel.fromJson(doc.data(), doc.id);
              } catch (_) {
                return null;
              }
            })
            .whereType<SwipeInviteModel>()
            .toList();
        yield items;
      }
    } catch (e) {
      debugPrint('watchIncomingInvites error: $e');
      yield const [];
    }
  }

  Stream<List<SwipeInviteModel>> watchAcceptedInvites(String userId) async* {
    final sentStream = _invitesRef
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: SwipeInviteStatus.accepted.value)
        .orderBy('updatedAt', descending: true)
        .snapshots();
    final receivedStream = _invitesRef
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: SwipeInviteStatus.accepted.value)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    yield* Stream<List<SwipeInviteModel>>.multi((controller) {
      List<SwipeInviteModel> sent = const [];
      List<SwipeInviteModel> received = const [];

      void emitMerged() {
        final mergedById = <String, SwipeInviteModel>{};
        for (final invite in [...sent, ...received]) {
          mergedById[invite.id] = invite;
        }

        final merged = mergedById.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        controller.add(merged);
      }

      final sentSub = sentStream.listen(
        (snapshot) {
          sent = snapshot.docs
              .map((doc) {
                try {
                  return SwipeInviteModel.fromJson(doc.data(), doc.id);
                } catch (_) {
                  return null;
                }
              })
              .whereType<SwipeInviteModel>()
              .toList();
          emitMerged();
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('watchAcceptedInvites sent stream error: $error');
          controller.add(const []);
        },
      );

      final receivedSub = receivedStream.listen(
        (snapshot) {
          received = snapshot.docs
              .map((doc) {
                try {
                  return SwipeInviteModel.fromJson(doc.data(), doc.id);
                } catch (_) {
                  return null;
                }
              })
              .whereType<SwipeInviteModel>()
              .toList();
          emitMerged();
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('watchAcceptedInvites received stream error: $error');
          controller.add(const []);
        },
      );

      controller.onCancel = () async {
        await sentSub.cancel();
        await receivedSub.cancel();
      };
    });
  }

  Future<SwipeInviteModel?> acceptInvite({
    required String inviteId,
    required String currentUserId,
  }) async {
    final ref = _invitesRef.doc(inviteId);

    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) throw StateError('Invite not found');

      final data = doc.data()!;
      final receiverId = (data['receiverId'] ?? '') as String;
      final status = SwipeInviteStatusX.fromValue(
        (data['status'] ?? 'pending') as String,
      );

      if (receiverId != currentUserId) {
        throw StateError('Only receiver can accept invite');
      }
      if (status != SwipeInviteStatus.pending) return;

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
    await _handleAcceptedInvite(invite: invite, currentUserId: currentUserId);
    return invite;
  }

  Future<void> rejectInvite({
    required String inviteId,
    required String currentUserId,
  }) async {
    final ref = _invitesRef.doc(inviteId);

    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) throw StateError('Invite not found');

      final data = doc.data()!;
      final receiverId = (data['receiverId'] ?? '') as String;
      final status = SwipeInviteStatusX.fromValue(
        (data['status'] ?? 'pending') as String,
      );

      if (receiverId != currentUserId) {
        throw StateError('Only receiver can reject invite');
      }
      if (status != SwipeInviteStatus.pending) return;

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
      debugPrint('getUserPhotos: indexed query failed for $userId: $e');
    }

    try {
      final snapshot = await _photosRef
          .where('userId', isEqualTo: userId)
          .limit(limit * 2)
          .get();
      return _mapPhotos(snapshot.docs, limit: limit);
    } catch (e) {
      debugPrint('getUserPhotos: fallback failed for $userId: $e');
      return const [];
    }
  }

  Future<String?> startChatFromInvite({
    required SwipeInviteModel invite,
    required String currentUserId,
  }) async {
    if (!invite.involves(currentUserId)) throw StateError('Not part of invite');
    if (invite.status != SwipeInviteStatus.accepted) return null;

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

  Future<void> _handleAcceptedInvite({
    required SwipeInviteModel invite,
    required String currentUserId,
  }) async {
    await _joinMeetupIfNeeded(invite: invite, currentUserId: currentUserId);
    await startChatFromInvite(invite: invite, currentUserId: currentUserId);
  }

  Future<void> _joinMeetupIfNeeded({
    required SwipeInviteModel invite,
    required String currentUserId,
  }) async {
    if (invite.inviteContext != SwipeInviteContext.meetup) {
      return;
    }

    final meetupId = invite.meetupId;
    if (meetupId == null || meetupId.isEmpty) {
      return;
    }

    try {
      final meetup = await _meetupService.getMeetupById(meetupId);
      if (meetup == null || meetup.participantIds.contains(currentUserId)) {
        return;
      }
      if (meetup.currentParticipants >= meetup.maxParticipants) {
        debugPrint('_joinMeetupIfNeeded skipped, meetup is full: $meetupId');
        return;
      }
      await _meetupService.joinMeetup(meetupId, currentUserId);
    } catch (e) {
      debugPrint('_joinMeetupIfNeeded error for $meetupId: $e');
    }
  }

  Future<void> _writeSwipeAction({
    required String actorId,
    required String targetId,
    required String decision,
  }) async {
    final actionId = '${actorId}_$targetId';
    try {
      final doc = await _actionsRef.doc(actionId).get();
      if (!doc.exists) {
        await _actionsRef.doc(actionId).set({
          'actorId': actorId,
          'targetId': targetId,
          'decision': decision,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('_writeSwipeAction ignored: $e');
    }
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
