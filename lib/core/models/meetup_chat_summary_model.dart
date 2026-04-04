import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_update_model.dart';
import 'message_model.dart';
import 'meetup_model.dart';

class MeetupChatSummaryModel {
  final MeetupModel meetup;
  final MessageModel? lastMessage;
  final int unreadCount;
  final DateTime? lastActivityTime;
  final bool isOrganizerOnlyMode;

  const MeetupChatSummaryModel({
    required this.meetup,
    this.lastMessage,
    required this.unreadCount,
    this.lastActivityTime,
    this.isOrganizerOnlyMode = false,
  });

  String get chatId => meetup.id;
  String get title => meetup.title;
  DateTime get meetupDate => meetup.date;
  MeetupModel toMeetupCardModel() => meetup;

  bool get isPast {
    final effectiveEnd = meetup.endDate ?? meetup.date;
    return effectiveEnd.isBefore(DateTime.now());
  }

  ChatUpdateModel toChatUpdateModel() {
    return ChatUpdateModel(
      lastMessage: lastMessage,
      unreadCount: unreadCount,
      chatCreatedAt: lastActivityTime ?? meetup.createdAt,
      isOrganizerOnlyMode: isOrganizerOnlyMode,
    );
  }

  factory MeetupChatSummaryModel.fromChatDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String userId,
  ) {
    return _fromData(doc.id, doc.data(), userId);
  }

  factory MeetupChatSummaryModel.fromJson(
    Map<String, dynamic> json,
    String id,
  ) {
    final chatId = json['chatId'] as String? ?? id;
    final meetupDate = _parseDateTime(json['meetupDate']) ?? DateTime.now();
    final meetupCreatedAt =
        _parseDateTime(json['meetupCreatedAt']) ?? meetupDate;
    final lastMessageTime = _parseDateTime(json['lastMessageTime']);
    final lastMessageText = json['lastMessage'] as String?;

    final meetup = MeetupModel(
      id: chatId,
      title: json['title'] as String? ?? '',
      description: '',
      rules: '',
      imageUrl: json['imageUrl'] as String? ?? '',
      type: _parseMeetupType(json['meetupType']),
      date: meetupDate,
      endDate: _parseDateTime(json['meetupEndDate']),
      locationName: '',
      locationAddress: '',
      organizerId: '',
      organizerName: 'Unknown',
      currentParticipants: 0,
      maxParticipants: 0,
      createdAt: meetupCreatedAt,
      isOrganizerOnlyChat: json['isOrganizerOnlyMode'] == true,
    );

    final lastMessage =
        lastMessageText != null &&
            lastMessageText.isNotEmpty &&
            lastMessageTime != null
        ? MessageModel(
            id: 'summary_$chatId',
            senderId: json['lastMessageSenderId'] as String? ?? '',
            senderName:
                json['lastMessageSenderName'] as String? ?? 'Bilinmiyor',
            text: lastMessageText,
            type: MessageType.text,
            timestamp: lastMessageTime,
          )
        : null;

    return MeetupChatSummaryModel(
      meetup: meetup,
      lastMessage: lastMessage,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      lastActivityTime: lastMessageTime ?? _parseDateTime(json['updatedAt']),
      isOrganizerOnlyMode: json['isOrganizerOnlyMode'] == true,
    );
  }

  static MeetupChatSummaryModel _fromData(
    String id,
    Map<String, dynamic> data,
    String userId,
  ) {
    final chatId = data['chatId'] as String? ?? id;
    final meetupDate = _parseDateTime(data['meetupDate']) ?? DateTime.now();
    final createdAt =
        _parseDateTime(data['createdAt']) ??
        _parseDateTime(data['meetupCreatedAt']) ??
        meetupDate;
    final participants =
        (data['participants'] as List<dynamic>? ??
                data['participantIds'] as List<dynamic>? ??
                const <dynamic>[])
            .map((item) => item.toString())
            .toList();

    final meetup = MeetupModel(
      id: chatId,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      rules: data['rules'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      type: _parseMeetupType(data['meetupType']),
      date: meetupDate,
      endDate:
          _parseDateTime(data['endDate']) ??
          _parseDateTime(data['meetupEndDate']),
      locationName: data['locationName'] as String? ?? '',
      locationAddress: data['locationAddress'] as String? ?? '',
      organizerId: data['organizerId'] as String? ?? '',
      organizerName: data['organizerName'] as String? ?? 'Unknown',
      organizerImageUrl: data['organizerImageUrl'] as String?,
      currentParticipants:
          (data['currentParticipants'] as num?)?.toInt() ?? participants.length,
      maxParticipants: (data['maxParticipants'] as num?)?.toInt() ?? 0,
      participantIds: participants,
      waitlistUserIds:
          (data['waitlistUserIds'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      isOrganizerOnlyChat: data['isOrganizerOnlyMode'] == true,
      createdAt: createdAt,
      hideFromFeedUntilAccepted: data['hideFromFeedUntilAccepted'] == true,
      isFull: data['isFull'] == true,
    );

    final lastMessageTime = _parseDateTime(data['lastMessageTime']);
    final lastMessageText = data['lastMessage'] as String?;
    final lastMessage =
        lastMessageText != null &&
            lastMessageText.isNotEmpty &&
            lastMessageTime != null
        ? MessageModel(
            id: 'summary_$id',
            senderId: data['lastMessageSenderId'] as String? ?? '',
            senderName: data['lastMessageSenderName'] as String? ?? 'Bilinmiyor',
            text: lastMessageText,
            type: MessageType.text,
            timestamp: lastMessageTime,
          )
        : null;

    return MeetupChatSummaryModel(
      meetup: meetup,
      lastMessage: lastMessage,
      unreadCount: _readUnreadCount(
        data['unreadCounts'] ?? data['unreadCount'],
        userId,
      ),
      lastActivityTime: lastMessageTime ?? _parseDateTime(data['updatedAt']),
      isOrganizerOnlyMode: data['isOrganizerOnlyMode'] == true,
    );
  }

  static MeetupType _parseMeetupType(dynamic value) {
    final typeName = value?.toString() ?? '';
    return MeetupType.values.firstWhere(
      (type) => type.name == typeName,
      orElse: () => MeetupType.other,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static int _readUnreadCount(dynamic unreadCounts, String userId) {
    if (unreadCounts == null) return 0;
    if (unreadCounts is int) return unreadCounts;
    if (unreadCounts is num) return unreadCounts.toInt();
    if (unreadCounts is! Map) return 0;
    final value = unreadCounts[userId] ?? unreadCounts['count'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
