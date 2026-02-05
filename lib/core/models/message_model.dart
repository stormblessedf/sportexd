import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, system, announcement }

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderImageUrl;
  final String text;
  final String? imageUrl;
  final MessageType type;
  final DateTime timestamp;

  // Reply support
  final String? replyToId;
  final String? replyToText;
  final String? replyToSenderName;

  // Edit/Delete support
  final bool isEdited;
  final bool isDeleted;
  final DateTime? editedAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    required this.text,
    this.imageUrl,
    required this.type,
    required this.timestamp,
    this.replyToId,
    this.replyToText,
    this.replyToSenderName,
    this.isEdited = false,
    this.isDeleted = false,
    this.editedAt,
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
      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToSenderName': replyToSenderName,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedTimestamp;
    final timestampValue = json['timestamp'];
    if (timestampValue is Timestamp) {
      parsedTimestamp = timestampValue.toDate();
    } else if (timestampValue is String) {
      parsedTimestamp = DateTime.tryParse(timestampValue) ?? DateTime.now();
    } else {
      parsedTimestamp = DateTime.now();
    }

    DateTime? parsedEditedAt;
    final editedAtValue = json['editedAt'];
    if (editedAtValue is Timestamp) {
      parsedEditedAt = editedAtValue.toDate();
    }

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
      timestamp: parsedTimestamp,
      replyToId: json['replyToId'],
      replyToText: json['replyToText'],
      replyToSenderName: json['replyToSenderName'],
      isEdited: json['isEdited'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      editedAt: parsedEditedAt,
    );
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderImageUrl,
    String? text,
    String? imageUrl,
    MessageType? type,
    DateTime? timestamp,
    String? replyToId,
    String? replyToText,
    String? replyToSenderName,
    bool? isEdited,
    bool? isDeleted,
    DateTime? editedAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderImageUrl: senderImageUrl ?? this.senderImageUrl,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      replyToId: replyToId ?? this.replyToId,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}
