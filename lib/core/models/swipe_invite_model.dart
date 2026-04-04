import 'package:cloud_firestore/cloud_firestore.dart';

enum SwipeInviteStatus { pending, accepted, rejected, canceled }

enum SwipeInviteContext { sport, meetup }

extension SwipeInviteStatusX on SwipeInviteStatus {
  String get value {
    switch (this) {
      case SwipeInviteStatus.pending:
        return 'pending';
      case SwipeInviteStatus.accepted:
        return 'accepted';
      case SwipeInviteStatus.rejected:
        return 'rejected';
      case SwipeInviteStatus.canceled:
        return 'canceled';
    }
  }

  static SwipeInviteStatus fromValue(String raw) {
    switch (raw) {
      case 'accepted':
        return SwipeInviteStatus.accepted;
      case 'rejected':
        return SwipeInviteStatus.rejected;
      case 'canceled':
        return SwipeInviteStatus.canceled;
      case 'pending':
      default:
        return SwipeInviteStatus.pending;
    }
  }
}

class SwipeInviteModel {
  final String id;
  final String pairId;
  final String senderId;
  final String receiverId;
  final List<String> participantIds;
  final SwipeInviteStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final String? chatId;
  // Invite context
  final SwipeInviteContext inviteContext;
  final String? sportType;   // e.g. 'tennis'
  final String? meetupId;
  final String? meetupTitle;
  final String senderName;
  final String? senderImageUrl;

  const SwipeInviteModel({
    required this.id,
    required this.pairId,
    required this.senderId,
    required this.receiverId,
    required this.participantIds,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.chatId,
    this.inviteContext = SwipeInviteContext.sport,
    this.sportType,
    this.meetupId,
    this.meetupTitle,
    this.senderName = '',
    this.senderImageUrl,
  });

  static String generatePairId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  bool involves(String userId) => participantIds.contains(userId);

  String otherUserId(String currentUserId) {
    if (currentUserId == senderId) return receiverId;
    return senderId;
  }

  factory SwipeInviteModel.fromJson(
    Map<String, dynamic> json, [
    String? docId,
  ]) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final senderId = (json['senderId'] ?? '') as String;
    final receiverId = (json['receiverId'] ?? '') as String;
    final pairId =
        (json['pairId'] ?? generatePairId(senderId, receiverId)) as String;

    return SwipeInviteModel(
      id: docId ?? (json['id'] ?? pairId) as String,
      pairId: pairId,
      senderId: senderId,
      receiverId: receiverId,
      participantIds:
          (json['participantIds'] as List<dynamic>?)?.cast<String>() ??
          [senderId, receiverId],
      status: SwipeInviteStatusX.fromValue(
        (json['status'] ?? 'pending') as String,
      ),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      acceptedAt: parseNullableDate(json['acceptedAt']),
      rejectedAt: parseNullableDate(json['rejectedAt']),
      chatId: json['chatId'] as String?,
      inviteContext: (json['inviteContext'] as String?) == 'meetup'
          ? SwipeInviteContext.meetup
          : SwipeInviteContext.sport,
      sportType: json['sportType'] as String?,
      meetupId: json['meetupId'] as String?,
      meetupTitle: json['meetupTitle'] as String?,
      senderName: (json['senderName'] ?? '') as String,
      senderImageUrl: json['senderImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pairId': pairId,
      'senderId': senderId,
      'receiverId': receiverId,
      'participantIds': participantIds,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'chatId': chatId,
      'inviteContext': inviteContext == SwipeInviteContext.meetup ? 'meetup' : 'sport',
      'sportType': sportType,
      'meetupId': meetupId,
      'meetupTitle': meetupTitle,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
    };
  }

  SwipeInviteModel copyWith({
    String? id,
    String? pairId,
    String? senderId,
    String? receiverId,
    List<String>? participantIds,
    SwipeInviteStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    String? chatId,
    SwipeInviteContext? inviteContext,
    String? sportType,
    String? meetupId,
    String? meetupTitle,
    String? senderName,
    String? senderImageUrl,
  }) {
    return SwipeInviteModel(
      id: id ?? this.id,
      pairId: pairId ?? this.pairId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      participantIds: participantIds ?? this.participantIds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      chatId: chatId ?? this.chatId,
      inviteContext: inviteContext ?? this.inviteContext,
      sportType: sportType ?? this.sportType,
      meetupId: meetupId ?? this.meetupId,
      meetupTitle: meetupTitle ?? this.meetupTitle,
      senderName: senderName ?? this.senderName,
      senderImageUrl: senderImageUrl ?? this.senderImageUrl,
    );
  }
}
