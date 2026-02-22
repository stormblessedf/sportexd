import 'package:cloud_firestore/cloud_firestore.dart';

/// Canlı yayın sohbet mesajını temsil eden model
class ChatMessage {
  final String id;
  final String streamId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String message;
  final DateTime timestamp;
  final bool isFromBroadcaster;

  const ChatMessage({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.message,
    required this.timestamp,
    this.isFromBroadcaster = false,
  });

  /// Mesaj boş mu kontrol et
  static bool isValidMessage(String message) {
    return message.trim().isNotEmpty;
  }

  /// Formatlanmış zaman
  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  ChatMessage copyWith({
    String? id,
    String? streamId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? message,
    DateTime? timestamp,
    bool? isFromBroadcaster,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      streamId: streamId ?? this.streamId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isFromBroadcaster: isFromBroadcaster ?? this.isFromBroadcaster,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      streamId: json['streamId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String? ?? '',
      message: json['message'] as String,
      timestamp: _parseDateTime(json['timestamp']),
      isFromBroadcaster: json['isFromBroadcaster'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'streamId': streamId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isFromBroadcaster': isFromBroadcaster,
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, user: $userName, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
