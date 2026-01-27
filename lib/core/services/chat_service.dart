import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection Reference
  CollectionReference get _chatsRef => _firestore.collection('chats');

  // Send Message
  Future<void> sendMessage({
    required String chatId, // This will be the meetupId
    required String senderId,
    required String senderName,
    String? senderImageUrl,
    required String text,
    MessageType type = MessageType.text,
  }) async {
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
    );

    await docRef.set(message.toJson());
    
    // Update last message in chat document for list previews (optional but good practice)
    await _chatsRef.doc(chatId).set({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
}
