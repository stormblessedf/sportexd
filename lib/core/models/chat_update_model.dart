import 'message_model.dart';

/// Model combining last message and unread count for efficient chat list updates.
///
/// Used by StreamBuilder to provide real-time updates for chat cards.
class ChatUpdateModel {
  final MessageModel? lastMessage;
  final int unreadCount;
  final DateTime? chatCreatedAt;
  final bool isOrganizerOnlyMode;

  const ChatUpdateModel({
    this.lastMessage,
    required this.unreadCount,
    this.chatCreatedAt,
    this.isOrganizerOnlyMode = false,
  });

  /// Get the timestamp to display in the chat list.
  /// Returns last message timestamp if available, otherwise chat creation time.
  DateTime? get displayTimestamp => lastMessage?.timestamp ?? chatCreatedAt;

  /// Check if there are unread messages.
  bool get hasUnread => unreadCount > 0;

  ChatUpdateModel copyWith({
    MessageModel? lastMessage,
    int? unreadCount,
    DateTime? chatCreatedAt,
    bool? isOrganizerOnlyMode,
  }) {
    return ChatUpdateModel(
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      chatCreatedAt: chatCreatedAt ?? this.chatCreatedAt,
      isOrganizerOnlyMode: isOrganizerOnlyMode ?? this.isOrganizerOnlyMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatUpdateModel &&
        other.lastMessage?.id == lastMessage?.id &&
        other.unreadCount == unreadCount &&
        other.chatCreatedAt == chatCreatedAt &&
        other.isOrganizerOnlyMode == isOrganizerOnlyMode;
  }

  @override
  int get hashCode => Object.hash(
        lastMessage?.id,
        unreadCount,
        chatCreatedAt,
        isOrganizerOnlyMode,
      );
}
