import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/meetup_chat_summary_model.dart';
import '../models/message_model.dart';
import '../models/chat_update_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // In-memory cache for last messages
  final Map<String, MessageModel?> _lastMessageCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Collection Reference
  CollectionReference<Map<String, dynamic>> get _chatsRef =>
      _firestore.collection('chats');
  // Send Message
  Future<bool> sendMessage({
    required String chatId, // This will be the meetupId
    required String senderId,
    required String senderName,
    String? senderImageUrl,
    required String text,
    MessageType type = MessageType.text,
    String? replyToId,
    String? replyToText,
    String? replyToSenderName,
  }) async {
    try {
      final messagesRef = _chatsRef.doc(chatId).collection('messages');
      final docRef = messagesRef.doc();

      final message = MessageModel(
        id: docRef.id,
        senderId: senderId,
        senderName: senderName,
        senderImageUrl: senderImageUrl,
        text: text,
        type: type,
        timestamp: DateTime.now(),
        replyToId: replyToId,
        replyToText: replyToText,
        replyToSenderName: replyToSenderName,
      );

      await docRef.set(message.toJson());

      // Update last message in chat document for list previews (optional but good practice)
      await _chatsRef.doc(chatId).set({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'lastMessageSenderName': senderName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Message sent successfully to chat: $chatId');
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  // Edit Message
  Future<bool> editMessage({
    required String chatId,
    required String messageId,
    required String senderId,
    required String newText,
  }) async {
    try {
      final messageRef = _chatsRef
          .doc(chatId)
          .collection('messages')
          .doc(messageId);
      final messageDoc = await messageRef.get();

      if (!messageDoc.exists) {
        debugPrint('Message not found');
        return false;
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      if (messageData['senderId'] != senderId) {
        debugPrint('User is not the sender of this message');
        return false;
      }

      await messageRef.update({
        'text': newText,
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });
      await _syncChatPreview(chatId);

      debugPrint('Message edited successfully');
      return true;
    } catch (e) {
      debugPrint('Error editing message: $e');
      return false;
    }
  }

  // Delete Message (soft delete)
  Future<bool> deleteMessage({
    required String chatId,
    required String messageId,
    required String senderId,
  }) async {
    try {
      final messageRef = _chatsRef
          .doc(chatId)
          .collection('messages')
          .doc(messageId);
      final messageDoc = await messageRef.get();

      if (!messageDoc.exists) {
        debugPrint('Message not found');
        return false;
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      if (messageData['senderId'] != senderId) {
        debugPrint('User is not the sender of this message');
        return false;
      }

      await messageRef.update({'text': 'Bu mesaj silindi', 'isDeleted': true});
      await _syncChatPreview(chatId);

      debugPrint('Message deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  // Get Messages Stream (paginated — latest 50 by default)
  Stream<List<MessageModel>> getMessages(String chatId, {int limit = 50}) {
    return _chatsRef
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel.fromJson(doc.data());
          }).toList();
        });
  }

  // Load older messages for pagination
  Future<List<MessageModel>> loadOlderMessages(
    String chatId, {
    required DateTime beforeTimestamp,
    int limit = 30,
  }) async {
    try {
      final snapshot = await _chatsRef
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .where('timestamp', isLessThan: Timestamp.fromDate(beforeTimestamp))
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error loading older messages: $e');
      return [];
    }
  }

  /// Get the last message for a chat.
  /// Uses caching to avoid redundant Firestore queries.
  Future<MessageModel?> getLastMessage(String chatId) async {
    // Check cache first
    if (_isCacheValid(chatId)) {
      return _lastMessageCache[chatId];
    }

    try {
      final snapshot = await _chatsRef
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        _updateCache(chatId, null);
        return null;
      }

      final message = MessageModel.fromJson(snapshot.docs.first.data());
      _updateCache(chatId, message);
      return message;
    } catch (e) {
      debugPrint('Error fetching last message for chat $chatId: $e');
      return null;
    }
  }

  /// Stream the last message for a chat (real-time updates).
  Stream<MessageModel?> streamLastMessage(String chatId) {
    return _chatsRef
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final message = MessageModel.fromJson(snapshot.docs.first.data());
          _updateCache(chatId, message);
          return message;
        });
  }

  /// Get unread message count for a user in a chat.
  Future<int> getUnreadCount(String chatId, String userId) async {
    try {
      final doc = await _chatsRef.doc(chatId).get();
      final data = doc.data();
      if (data == null) return 0;

      final unreadCounts = (data['unreadCounts'] as Map?)?.cast<String, dynamic>();
      return _readUnreadCount(unreadCounts, userId);
    } catch (e) {
      debugPrint(
        'Error fetching unread count for chat $chatId, user $userId: $e',
      );
      return 0;
    }
  }

  /// Stream unread count for a user in a chat (real-time updates).
  Stream<int> streamUnreadCount(String chatId, String userId) {
    return _chatsRef.doc(chatId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return 0;

      final unreadCounts = (data['unreadCounts'] as Map?)?.cast<String, dynamic>();
      return _readUnreadCount(unreadCounts, userId);
    });
  }

  /// Clear unread count when user opens a chat.
  Future<void> clearUnreadCount(String chatId, String userId) async {
    try {
      await _chatsRef.doc(chatId).set({
        'unreadCounts.$userId': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Cleared unread count for chat $chatId, user $userId');
    } catch (e) {
      debugPrint('Error clearing unread count: $e');
    }
  }

  /// Increment unread count for all participants except the sender.
  Future<void> incrementUnreadCount(
    String chatId,
    String senderId,
    List<String> participantIds,
  ) async {
    try {
      final batch = _firestore.batch();
      final chatUpdate = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      for (final participantId in participantIds) {
        if (participantId != senderId) {
          chatUpdate['unreadCounts.$participantId'] = FieldValue.increment(1);
        }
      }

      batch.set(_chatsRef.doc(chatId), chatUpdate, SetOptions(merge: true));
      await batch.commit();
    } catch (e) {
      debugPrint('Error incrementing unread count: $e');
    }
  }

  /// Stream combined chat updates (last message + unread count).
  Stream<ChatUpdateModel> streamChatUpdates(String chatId, String userId) {
    return _chatsRef
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data() as Map<String, dynamic>? ?? {};
          final chatCreatedAt = _parseDateTime(data['createdAt']);
          final lastMessageTime = _parseDateTime(data['lastMessageTime']);
          final unreadCounts =
              (data['unreadCounts'] as Map?)?.cast<String, dynamic>();
          final unreadCount = _readUnreadCount(
            unreadCounts,
            userId,
          );
          final isOrganizerOnlyMode = data['isOrganizerOnlyMode'] == true;

          final lastMessageText = data['lastMessage'] as String?;
          final lastMessageSenderId = data['lastMessageSenderId'] as String?;
          final lastMessageSenderName =
              data['lastMessageSenderName'] as String? ?? 'Bilinmiyor';

          final lastMessage =
              lastMessageText != null &&
                  lastMessageText.isNotEmpty &&
                  lastMessageTime != null
              ? MessageModel(
                  id: 'summary_$chatId',
                  senderId: lastMessageSenderId ?? '',
                  senderName: lastMessageSenderName,
                  text: lastMessageText,
                  type: MessageType.text,
                  timestamp: lastMessageTime,
                )
              : null;

          if (lastMessage != null) {
            _updateCache(chatId, lastMessage);
          }

          return ChatUpdateModel(
            lastMessage: lastMessage,
            unreadCount: unreadCount,
            chatCreatedAt: chatCreatedAt,
            isOrganizerOnlyMode: isOrganizerOnlyMode,
          );
        });
  }

  /// Get chat metadata including creation time.
  Future<Map<String, dynamic>?> getChatMetadata(String chatId) async {
    try {
      final doc = await _chatsRef.doc(chatId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error fetching chat metadata for $chatId: $e');
      return null;
    }
  }

  // Cache helper methods
  bool _isCacheValid(String chatId) {
    final timestamp = _cacheTimestamps[chatId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  void _updateCache(String chatId, MessageModel? message) {
    _lastMessageCache[chatId] = message;
    _cacheTimestamps[chatId] = DateTime.now();
  }

  void invalidateCache(String chatId) {
    _lastMessageCache.remove(chatId);
    _cacheTimestamps.remove(chatId);
  }

  void clearCache() {
    _lastMessageCache.clear();
    _cacheTimestamps.clear();
  }

  // ==================== Direct Message Support ====================

  /// Generate DM chat ID from two user IDs (sorted for consistency)
  static String generateDmChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? 'dm_${uid1}_$uid2' : 'dm_${uid2}_$uid1';
  }

  /// Check if a chat ID is a DM chat
  static bool isDmChat(String chatId) => chatId.startsWith('dm_');

  /// Get or create a direct message chat
  Future<String> getOrCreateDirectChat({
    required String userId1,
    required String userId2,
    required String user1Name,
    required String user2Name,
  }) async {
    final chatId = generateDmChatId(userId1, userId2);

    try {
      final chatDoc = await _chatsRef.doc(chatId).get();
      if (!chatDoc.exists) {
        await _chatsRef.doc(chatId).set({
          'type': 'dm',
          'participants': [userId1, userId2],
          'participantNames': {userId1: user1Name, userId2: user2Name},
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return chatId;
    } catch (e) {
      debugPrint('Error creating DM chat: $e');
      rethrow;
    }
  }

  /// Get direct chats for a user
  Stream<List<Map<String, dynamic>>> getDirectChats(String userId) {
    return _chatsRef
        .where('type', isEqualTo: 'dm')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'chatId': doc.id, ...data};
      }).toList();

      chats.sort((a, b) {
        final aTime = _parseDateTime(a['lastMessageTime']) ??
            _parseDateTime(a['updatedAt']) ??
            _parseDateTime(a['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = _parseDateTime(b['lastMessageTime']) ??
            _parseDateTime(b['updatedAt']) ??
            _parseDateTime(b['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return chats;
    });
  }

  Stream<List<MeetupChatSummaryModel>> streamMeetupChatSummariesForUser(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_summaries')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MeetupChatSummaryModel.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> _syncChatPreview(String chatId) async {
    try {
      final snapshot = await _chatsRef
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        invalidateCache(chatId);
        await _chatsRef.doc(chatId).set({
          'lastMessage': null,
          'lastMessageTime': null,
          'lastMessageSenderId': null,
          'lastMessageSenderName': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      }

      final latestMessage = MessageModel.fromJson(snapshot.docs.first.data());
      _updateCache(chatId, latestMessage);
      await _chatsRef.doc(chatId).set({
        'lastMessage': latestMessage.text,
        'lastMessageTime': Timestamp.fromDate(latestMessage.timestamp),
        'lastMessageSenderId': latestMessage.senderId,
        'lastMessageSenderName': latestMessage.senderName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing chat preview for $chatId: $e');
    }
  }

  int _readUnreadCount(Map<String, dynamic>? unreadCounts, String userId) {
    if (unreadCounts == null) return 0;
    final value = unreadCounts[userId];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
