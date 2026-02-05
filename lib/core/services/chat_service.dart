import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../models/chat_update_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // In-memory cache for last messages
  final Map<String, MessageModel?> _lastMessageCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Collection Reference
  CollectionReference get _chatsRef => _firestore.collection('chats');

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

      debugPrint('Message deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  // Get Messages Stream
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _chatsRef
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel.fromJson(doc.data());
          }).toList();
        });
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
      final doc = await _chatsRef
          .doc(chatId)
          .collection('unread')
          .doc(userId)
          .get();

      return doc.data()?['count'] ?? 0;
    } catch (e) {
      debugPrint(
        'Error fetching unread count for chat $chatId, user $userId: $e',
      );
      return 0;
    }
  }

  /// Stream unread count for a user in a chat (real-time updates).
  Stream<int> streamUnreadCount(String chatId, String userId) {
    return _chatsRef
        .doc(chatId)
        .collection('unread')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.data()?['count'] ?? 0;
        });
  }

  /// Clear unread count when user opens a chat.
  Future<void> clearUnreadCount(String chatId, String userId) async {
    try {
      await _chatsRef.doc(chatId).collection('unread').doc(userId).set({
        'count': 0,
        'lastCleared': FieldValue.serverTimestamp(),
      });
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

      for (final participantId in participantIds) {
        if (participantId != senderId) {
          final unreadRef = _chatsRef
              .doc(chatId)
              .collection('unread')
              .doc(participantId);
          batch.set(unreadRef, {
            'count': FieldValue.increment(1),
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error incrementing unread count: $e');
    }
  }

  /// Stream combined chat updates (last message + unread count).
  Stream<ChatUpdateModel> streamChatUpdates(String chatId, String userId) {
    return _chatsRef
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .asyncMap((snapshot) async {
          final lastMessage = snapshot.docs.isEmpty
              ? null
              : MessageModel.fromJson(snapshot.docs.first.data());

          if (lastMessage != null) {
            _updateCache(chatId, lastMessage);
          }

          final unreadCount = await getUnreadCount(chatId, userId);
          final chatDoc = await _chatsRef.doc(chatId).get();
          DateTime? chatCreatedAt;

          if (chatDoc.exists) {
            final data = chatDoc.data() as Map<String, dynamic>?;
            final createdAtValue = data?['createdAt'];
            if (createdAtValue is Timestamp) {
              chatCreatedAt = createdAtValue.toDate();
            }
          }

          return ChatUpdateModel(
            lastMessage: lastMessage,
            unreadCount: unreadCount,
            chatCreatedAt: chatCreatedAt,
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
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'chatId': doc.id, ...data};
      }).toList();
    });
  }
}
