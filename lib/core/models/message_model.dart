import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, system }

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderImageUrl;
  final String text;
  final String? imageUrl;
  final MessageType type;
  final DateTime timestamp;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    required this.text,
    this.imageUrl,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'text': text,
      'imageUrl': imageUrl,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'Unknown',
      senderImageUrl: json['senderImageUrl'],
      text: json['text'] ?? '',
      imageUrl: json['imageUrl'],
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }
}
