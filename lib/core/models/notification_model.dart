import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  meetupReminder,
  meetupUpdate,
  meetupCancelled,
  newParticipant,
  chatMessage,
  capacityReached,
  spotAvailable,
  partnershipRequest,
  partnershipAccepted,
  partnershipRejected,
  partnershipSuggestion,
  system,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.meetupReminder:
        return 'Etkinlik Hatırlatması';
      case NotificationType.meetupUpdate:
        return 'Etkinlik Güncellendi';
      case NotificationType.meetupCancelled:
        return 'Etkinlik İptal Edildi';
      case NotificationType.newParticipant:
        return 'Yeni Katılımcı';
      case NotificationType.chatMessage:
        return 'Yeni Mesaj';
      case NotificationType.capacityReached:
        return 'Kontenjan Doldu';
      case NotificationType.spotAvailable:
        return 'Kontenjan Açıldı';
      case NotificationType.partnershipRequest:
        return 'Partner İsteği';
      case NotificationType.partnershipAccepted:
        return 'Partner Kabul Edildi';
      case NotificationType.partnershipRejected:
        return 'Partner Reddedildi';
      case NotificationType.partnershipSuggestion:
        return 'Partner Önerisi';
      case NotificationType.system:
        return 'Sistem Bildirimi';
    }
  }

  String get firestoreValue {
    switch (this) {
      case NotificationType.meetupReminder:
        return 'meetup_reminder';
      case NotificationType.meetupUpdate:
        return 'meetup_update';
      case NotificationType.meetupCancelled:
        return 'meetup_cancelled';
      case NotificationType.newParticipant:
        return 'new_participant';
      case NotificationType.chatMessage:
        return 'chat_message';
      case NotificationType.capacityReached:
        return 'capacity_reached';
      case NotificationType.spotAvailable:
        return 'spot_available';
      case NotificationType.partnershipRequest:
        return 'partnership_request';
      case NotificationType.partnershipAccepted:
        return 'partnership_accepted';
      case NotificationType.partnershipRejected:
        return 'partnership_rejected';
      case NotificationType.partnershipSuggestion:
        return 'partnership_suggestion';
      case NotificationType.system:
        return 'system';
    }
  }

  static NotificationType fromFirestore(String value) {
    switch (value) {
      case 'meetup_reminder':
        return NotificationType.meetupReminder;
      case 'meetup_update':
        return NotificationType.meetupUpdate;
      case 'meetup_cancelled':
        return NotificationType.meetupCancelled;
      case 'new_participant':
        return NotificationType.newParticipant;
      case 'chat_message':
        return NotificationType.chatMessage;
      case 'capacity_reached':
        return NotificationType.capacityReached;
      case 'spot_available':
        return NotificationType.spotAvailable;
      case 'partnership_request':
        return NotificationType.partnershipRequest;
      case 'partnership_accepted':
        return NotificationType.partnershipAccepted;
      case 'partnership_rejected':
        return NotificationType.partnershipRejected;
      case 'partnership_suggestion':
        return NotificationType.partnershipSuggestion;
      case 'system':
      default:
        return NotificationType.system;
    }
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String relatedId;
  final Map<String, dynamic> metadata;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.relatedId,
    this.metadata = const {},
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromJson(data, doc.id);
  }

  factory NotificationModel.fromJson(
    Map<String, dynamic> json, [
    String? docId,
  ]) {
    DateTime parsedTimestamp;
    final timestampValue = json['timestamp'];
    if (timestampValue is Timestamp) {
      parsedTimestamp = timestampValue.toDate();
    } else if (timestampValue is String) {
      parsedTimestamp = DateTime.tryParse(timestampValue) ?? DateTime.now();
    } else {
      parsedTimestamp = DateTime.now();
    }

    return NotificationModel(
      id: docId ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: NotificationTypeExtension.fromFirestore(json['type'] ?? 'system'),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: parsedTimestamp,
      isRead: json['isRead'] ?? false,
      relatedId: json['relatedId'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.firestoreValue,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'relatedId': relatedId,
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      metadata: metadata ?? this.metadata,
    );
  }
}
