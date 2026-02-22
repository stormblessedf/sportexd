import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/models.dart';

/// Canlı yayın servisi - Firebase Firestore tabanlı
class LiveBroadcastService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  LiveBroadcastService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Collections
  CollectionReference<Map<String, dynamic>> get _streamsCollection =>
      _firestore.collection('streams');

  CollectionReference<Map<String, dynamic>> _messagesCollection(
          String streamId) =>
      _streamsCollection.doc(streamId).collection('messages');

  CollectionReference<Map<String, dynamic>> _reactionsCollection(
          String streamId) =>
      _streamsCollection.doc(streamId).collection('reactions');

  CollectionReference<Map<String, dynamic>> _viewersCollection(
          String streamId) =>
      _streamsCollection.doc(streamId).collection('viewers');

  // ========== STREAM OPERATIONS ==========

  /// Yeni yayın oluştur
  Future<StreamSession> createStream({
    required String eventId,
    required String eventName,
    required StreamQuality quality,
    required PrivacyLevel privacy,
    bool isRecordingEnabled = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[LiveBroadcastService] ERROR: No user logged in');
      throw Exception('Kullanıcı oturumu açık değil');
    }

    debugPrint('[LiveBroadcastService] Creating stream for user: ${user.uid}');

    // Kullanıcı bilgilerini al
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    debugPrint('[LiveBroadcastService] User data: $userData');

    final docRef = _streamsCollection.doc();
    final broadcasterName = userData['username'] ?? userData['displayName'] ?? user.displayName ?? 'Anonim';

    final stream = StreamSession(
      id: docRef.id,
      broadcasterId: user.uid,
      broadcasterName: broadcasterName,
      broadcasterAvatar: userData['profileImageUrl'] ?? user.photoURL ?? '',
      eventId: eventId,
      eventName: eventName,
      quality: quality,
      privacy: privacy,
      status: StreamStatus.starting,
      startedAt: DateTime.now(),
      isRecordingEnabled: isRecordingEnabled,
    );

    debugPrint('[LiveBroadcastService] Saving stream to Firestore: ${stream.id}');
    debugPrint('[LiveBroadcastService] Stream JSON: ${stream.toJson()}');

    await docRef.set(stream.toJson());

    debugPrint('[LiveBroadcastService] Stream saved successfully');
    return stream;
  }

  /// Yayını canlı yap
  Future<StreamSession> startStream(String streamId) async {
    debugPrint('[LiveBroadcastService] Setting stream $streamId to LIVE');

    // Agora uses streamId as channel name, no URL needed
    await _streamsCollection.doc(streamId).update({
      'status': StreamStatus.live.name,
      'channelName': streamId,
    });

    debugPrint('[LiveBroadcastService] Stream status updated to live');

    final doc = await _streamsCollection.doc(streamId).get();
    final result = StreamSession.fromJson({...doc.data()!, 'id': doc.id});

    debugPrint('[LiveBroadcastService] Stream is now live: ${result.status}');
    return result;
  }

  /// Yayını sonlandır
  Future<StreamStatistics> endStream(String streamId) async {
    final streamDoc = await _streamsCollection.doc(streamId).get();
    final stream = StreamSession.fromJson({...streamDoc.data()!, 'id': streamDoc.id});

    final endedAt = DateTime.now();
    final duration = endedAt.difference(stream.startedAt);

    // Mesaj sayısını al
    final messagesCount =
        await _messagesCollection(streamId).count().get();

    // İstatistikleri kaydet
    final statistics = StreamStatistics(
      streamId: streamId,
      duration: duration,
      totalViewers: stream.currentViewers,
      peakViewers: stream.peakViewers,
      totalMessages: messagesCount.count ?? 0,
      totalReactions: stream.totalReactions,
      viewersByMinute: {},
      recordedAt: endedAt,
    );

    // Yayını güncelle
    await _streamsCollection.doc(streamId).update({
      'status': StreamStatus.ended.name,
      'endedAt': Timestamp.fromDate(endedAt),
    });

    // İstatistikleri kaydet
    await _streamsCollection
        .doc(streamId)
        .collection('statistics')
        .doc('final')
        .set(statistics.toJson());

    // Bitmis yayini Firestore'dan sil (listede gozukmemesi icin)
    await deleteStream(streamId);

    return statistics;
  }

  /// Yayını sil
  Future<void> deleteStream(String streamId) async {
    // Alt koleksiyonları sil
    final messages = await _messagesCollection(streamId).get();
    for (final doc in messages.docs) {
      await doc.reference.delete();
    }

    final reactions = await _reactionsCollection(streamId).get();
    for (final doc in reactions.docs) {
      await doc.reference.delete();
    }

    final viewers = await _viewersCollection(streamId).get();
    for (final doc in viewers.docs) {
      await doc.reference.delete();
    }

    // Ana dokümanı sil
    await _streamsCollection.doc(streamId).delete();
  }

  /// Yayını getir
  Future<StreamSession?> getStream(String streamId) async {
    final doc = await _streamsCollection.doc(streamId).get();
    if (!doc.exists) return null;
    return StreamSession.fromJson({...doc.data()!, 'id': doc.id});
  }

  /// Aktif yayınları getir
  Future<List<StreamSession>> getActiveStreams() async {
    final snapshot = await _streamsCollection
        .where('status', isEqualTo: StreamStatus.live.name)
        .orderBy('startedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => StreamSession.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// Yayını dinle
  Stream<StreamSession?> watchStream(String streamId) {
    return _streamsCollection.doc(streamId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return StreamSession.fromJson({...doc.data()!, 'id': doc.id});
    });
  }

  /// Aktif yayınları dinle
  Stream<List<StreamSession>> watchActiveStreams() {
    debugPrint('[LiveBroadcastService] Watching active streams with status: ${StreamStatus.live.name}');

    return _streamsCollection
        .where('status', isEqualTo: StreamStatus.live.name)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('[LiveBroadcastService] Active streams query result: ${snapshot.docs.length} streams');
          for (final doc in snapshot.docs) {
            debugPrint('[LiveBroadcastService] Stream: ${doc.id}, status: ${doc.data()['status']}');
          }
          return snapshot.docs
              .map((doc) => StreamSession.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  /// Kullanıcının yayın geçmişini getir
  Future<List<StreamSession>> getUserStreamHistory(String userId) async {
    final snapshot = await _streamsCollection
        .where('broadcasterId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => StreamSession.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// Gizlilik ayarını güncelle
  Future<void> updatePrivacy(String streamId, PrivacyLevel privacy) async {
    await _streamsCollection.doc(streamId).update({
      'privacy': privacy.name,
    });
  }

  /// Kalite ayarını güncelle
  Future<void> updateQuality(String streamId, StreamQuality quality) async {
    await _streamsCollection.doc(streamId).update({
      'quality': quality.name,
    });
  }

  // ========== CHAT OPERATIONS ==========

  /// Mesaj gönder
  Future<ChatMessage> sendMessage({
    required String streamId,
    required String message,
  }) async {
    debugPrint('[LiveBroadcastService] sendMessage: streamId=$streamId, message="$message"');

    if (!ChatMessage.isValidMessage(message)) {
      throw Exception('Mesaj boş olamaz');
    }

    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[LiveBroadcastService] ERROR: No user logged in');
      throw Exception('Kullanıcı oturumu açık değil');
    }

    debugPrint('[LiveBroadcastService] Sending as user: ${user.uid}');

    // Kullanıcı bilgilerini al
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    debugPrint('[LiveBroadcastService] User data loaded: username=${userData['username']}');

    // Yayıncı kontrolü
    final streamDoc = await _streamsCollection.doc(streamId).get();
    final isFromBroadcaster =
        streamDoc.data()?['broadcasterId'] == user.uid;
    debugPrint('[LiveBroadcastService] isFromBroadcaster=$isFromBroadcaster');

    final docRef = _messagesCollection(streamId).doc();
    final chatMessage = ChatMessage(
      id: docRef.id,
      streamId: streamId,
      userId: user.uid,
      userName: userData['username'] ?? userData['displayName'] ?? user.displayName ?? 'Anonim',
      userAvatar: userData['profileImageUrl'] ?? user.photoURL ?? '',
      message: message.trim(),
      timestamp: DateTime.now(),
      isFromBroadcaster: isFromBroadcaster,
    );

    debugPrint('[LiveBroadcastService] Writing message to Firestore: ${docRef.path}');
    await docRef.set(chatMessage.toJson());
    debugPrint('[LiveBroadcastService] Message written successfully');
    return chatMessage;
  }

  /// Mesajları dinle
  Stream<List<ChatMessage>> watchMessages(String streamId) {
    return _messagesCollection(streamId)
        .orderBy('timestamp', descending: false)
        .limitToLast(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Mesaj geçmişini yükle
  Future<List<ChatMessage>> loadChatHistory(
    String streamId, {
    int limit = 50,
  }) async {
    final snapshot = await _messagesCollection(streamId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ChatMessage.fromJson({...doc.data(), 'id': doc.id}))
        .toList()
        .reversed
        .toList();
  }

  // ========== REACTION OPERATIONS ==========

  /// Tepki gönder
  Future<Reaction> sendReaction({
    required String streamId,
    ReactionType type = ReactionType.heart,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu açık değil');
    }

    final docRef = _reactionsCollection(streamId).doc();
    final reaction = Reaction(
      id: docRef.id,
      streamId: streamId,
      userId: user.uid,
      type: type,
      timestamp: DateTime.now(),
    );

    await docRef.set(reaction.toJson());

    // Toplam tepki sayısını artır
    await _streamsCollection.doc(streamId).update({
      'totalReactions': FieldValue.increment(1),
    });

    return reaction;
  }

  /// Tepkileri dinle
  Stream<List<Reaction>> watchReactions(String streamId) {
    return _reactionsCollection(streamId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reaction.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // ========== VIEWER OPERATIONS ==========

  /// İzleyici olarak katıl
  Future<void> joinAsViewer(String streamId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu açık değil');
    }

    // İzleyiciyi ekle
    await _viewersCollection(streamId).doc(user.uid).set({
      'userId': user.uid,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // İzleyici sayısını güncelle
    final stream = await getStream(streamId);
    if (stream != null) {
      final newCount = stream.currentViewers + 1;
      final newPeak =
          newCount > stream.peakViewers ? newCount : stream.peakViewers;

      await _streamsCollection.doc(streamId).update({
        'currentViewers': newCount,
        'peakViewers': newPeak,
      });
    }
  }

  /// İzleyici olarak ayrıl
  Future<void> leaveAsViewer(String streamId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // İzleyiciyi kaldır
    await _viewersCollection(streamId).doc(user.uid).delete();

    // İzleyici sayısını güncelle
    final stream = await getStream(streamId);
    if (stream != null && stream.currentViewers > 0) {
      await _streamsCollection.doc(streamId).update({
        'currentViewers': FieldValue.increment(-1),
      });
    }
  }

  /// İzleyici sayısını dinle
  Stream<int> watchViewerCount(String streamId) {
    return _streamsCollection.doc(streamId).snapshots().map((doc) {
      return doc.data()?['currentViewers'] as int? ?? 0;
    });
  }

  // ========== FOLLOW OPERATIONS ==========

  /// Yayıncıyı takip et
  Future<void> followBroadcaster(String broadcasterId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu açık değil');
    }

    await _firestore
        .collection('users')
        .doc(broadcasterId)
        .collection('followers')
        .doc(user.uid)
        .set({
      'followerId': user.uid,
      'followedAt': FieldValue.serverTimestamp(),
    });

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .doc(broadcasterId)
        .set({
      'followingId': broadcasterId,
      'followedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Takipten çık
  Future<void> unfollowBroadcaster(String broadcasterId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu açık değil');
    }

    await _firestore
        .collection('users')
        .doc(broadcasterId)
        .collection('followers')
        .doc(user.uid)
        .delete();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .doc(broadcasterId)
        .delete();
  }

  /// Takip durumunu kontrol et
  Future<bool> isFollowing(String broadcasterId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .doc(broadcasterId)
        .get();

    return doc.exists;
  }

  /// Takip durumunu dinle
  Stream<bool> watchFollowStatus(String broadcasterId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .doc(broadcasterId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // ========== ACCESS CONTROL ==========

  /// Yayına erişim kontrolü
  Future<bool> canAccessStream(String streamId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final stream = await getStream(streamId);
    if (stream == null) return false;

    // Yayıncı her zaman erişebilir
    if (stream.broadcasterId == user.uid) return true;

    switch (stream.privacy) {
      case PrivacyLevel.public:
        return true;

      case PrivacyLevel.followersOnly:
        return await isFollowing(stream.broadcasterId);

      case PrivacyLevel.participantsOnly:
        // Etkinlik katılımcısı mı kontrol et
        final eventDoc = await _firestore
            .collection('meetups')
            .doc(stream.eventId)
            .get();

        if (!eventDoc.exists) return false;

        final participants =
            List<String>.from(eventDoc.data()?['participants'] ?? []);
        return participants.contains(user.uid);
    }
  }

  // ========== STATISTICS ==========

  /// Yayın istatistiklerini getir
  Future<StreamStatistics?> getStreamStatistics(String streamId) async {
    final doc = await _streamsCollection
        .doc(streamId)
        .collection('statistics')
        .doc('final')
        .get();

    if (!doc.exists) return null;
    return StreamStatistics.fromJson({...doc.data()!, 'streamId': streamId});
  }
}
