import 'package:flutter/material.dart';
import 'notification_model.dart';

class NotificationPreferences {
  final bool meetupReminders;
  final bool meetupUpdates;
  final bool chatMessages;
  final bool newParticipants;
  final bool systemNotifications;
  final bool muteAll;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;
  final List<String> mutedChats;

  NotificationPreferences({
    this.meetupReminders = true,
    this.meetupUpdates = true,
    this.chatMessages = true,
    this.newParticipants = true,
    this.systemNotifications = true,
    this.muteAll = false,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.mutedChats = const [],
  });

  factory NotificationPreferences.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return NotificationPreferences();

    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return null;
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return null;
      return TimeOfDay(hour: hour, minute: minute);
    }

    return NotificationPreferences(
      meetupReminders: data['meetupReminders'] ?? true,
      meetupUpdates: data['meetupUpdates'] ?? true,
      chatMessages: data['chatMessages'] ?? true,
      newParticipants: data['newParticipants'] ?? true,
      systemNotifications: data['systemNotifications'] ?? true,
      muteAll: data['muteAll'] ?? false,
      quietHoursStart: parseTime(data['quietHoursStart']),
      quietHoursEnd: parseTime(data['quietHoursEnd']),
      mutedChats: List<String>.from(data['mutedChats'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    String? formatTime(TimeOfDay? time) {
      if (time == null) return null;
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    return {
      'meetupReminders': meetupReminders,
      'meetupUpdates': meetupUpdates,
      'chatMessages': chatMessages,
      'newParticipants': newParticipants,
      'systemNotifications': systemNotifications,
      'muteAll': muteAll,
      'quietHoursStart': formatTime(quietHoursStart),
      'quietHoursEnd': formatTime(quietHoursEnd),
      'mutedChats': mutedChats,
    };
  }

  /// Check if notification should be sent based on preferences
  bool shouldSendNotification(NotificationType type, DateTime time) {
    // If mute all is enabled, don't send any notifications
    if (muteAll) return false;

    // Check quiet hours
    if (isInQuietHours(time)) return false;

    // Check notification type preferences
    switch (type) {
      case NotificationType.meetupReminder:
        return meetupReminders;
      case NotificationType.meetupUpdate:
      case NotificationType.meetupCancelled:
        return meetupUpdates;
      case NotificationType.chatMessage:
        return chatMessages;
      case NotificationType.newParticipant:
      case NotificationType.capacityReached:
      case NotificationType.spotAvailable:
        return newParticipants;
      case NotificationType.system:
      case NotificationType.partnershipRequest:
      case NotificationType.partnershipAccepted:
      case NotificationType.partnershipRejected:
      case NotificationType.partnershipSuggestion:
        return systemNotifications;
    }
  }

  /// Check if a specific chat is muted
  bool isChatMuted(String chatId) {
    return mutedChats.contains(chatId);
  }

  /// Check if current time is within quiet hours
  bool isInQuietHours(DateTime time) {
    if (quietHoursStart == null || quietHoursEnd == null) return false;

    final currentMinutes = time.hour * 60 + time.minute;
    final startMinutes = quietHoursStart!.hour * 60 + quietHoursStart!.minute;
    final endMinutes = quietHoursEnd!.hour * 60 + quietHoursEnd!.minute;

    // Handle overnight quiet hours (e.g., 22:00 to 07:00)
    if (startMinutes > endMinutes) {
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    } else {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }
  }

  NotificationPreferences copyWith({
    bool? meetupReminders,
    bool? meetupUpdates,
    bool? chatMessages,
    bool? newParticipants,
    bool? systemNotifications,
    bool? muteAll,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    List<String>? mutedChats,
  }) {
    return NotificationPreferences(
      meetupReminders: meetupReminders ?? this.meetupReminders,
      meetupUpdates: meetupUpdates ?? this.meetupUpdates,
      chatMessages: chatMessages ?? this.chatMessages,
      newParticipants: newParticipants ?? this.newParticipants,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      muteAll: muteAll ?? this.muteAll,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      mutedChats: mutedChats ?? this.mutedChats,
    );
  }
}
