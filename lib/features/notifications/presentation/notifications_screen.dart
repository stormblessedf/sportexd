import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/meetup_model.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all as read when screen is viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().markAllAsRead();
    });
  }

  /// Group notifications by date categories
  Map<String, List<NotificationModel>> _groupByDate(
    List<NotificationModel> notifications,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));

    final groups = <String, List<NotificationModel>>{
      'Bugün': [],
      'Dün': [],
      'Bu Hafta': [],
      'Daha Önce': [],
    };

    for (final notification in notifications) {
      final notificationDate = DateTime(
        notification.timestamp.year,
        notification.timestamp.month,
        notification.timestamp.day,
      );

      if (notificationDate.isAtSameMomentAs(today) ||
          notificationDate.isAfter(today)) {
        groups['Bugün']!.add(notification);
      } else if (notificationDate.isAtSameMomentAs(yesterday)) {
        groups['Dün']!.add(notification);
      } else if (notificationDate.isAfter(thisWeekStart) ||
          notificationDate.isAtSameMomentAs(thisWeekStart)) {
        groups['Bu Hafta']!.add(notification);
      } else {
        groups['Daha Önce']!.add(notification);
      }
    }

    // Remove empty groups
    groups.removeWhere((key, value) => value.isEmpty);

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = context.read<NotificationService>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Bildirimler'),
        backgroundColor: AppTheme.backgroundLight,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'mark_all_read') {
                notificationService.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tüm bildirimler okundu olarak işaretlendi'),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 20),
                    SizedBox(width: 8),
                    Text('Tümünü Okundu İşaretle'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (snapshot.hasError) {
            debugPrint('Notification stream error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Bir hata oluştu',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      '${snapshot.error}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          final groupedNotifications = _groupByDate(notifications);

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: groupedNotifications.length,
              itemBuilder: (context, groupIndex) {
                final groupName = groupedNotifications.keys.elementAt(
                  groupIndex,
                );
                final groupItems = groupedNotifications[groupName]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        groupName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    // Notification items
                    ...groupItems.map(
                      (notification) => _NotificationListItem(
                        notification: notification,
                        onTap: () => _handleNotificationTap(notification),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 40,
              color: AppTheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bildirim Yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni bildirimler burada görünecek',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    final notificationService = context.read<NotificationService>();

    // Delete notification when clicked
    await notificationService.deleteNotification(notification.id);

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.chatMessage:
        final meetupTitle =
            notification.metadata['meetupTitle'] as String? ??
            notification.title;
        if (mounted) {
          context.push(
            '/chat',
            extra: {'chatId': notification.relatedId, 'title': meetupTitle},
          );
        }
        break;
      case NotificationType.meetupReminder:
      case NotificationType.meetupUpdate:
      case NotificationType.meetupCancelled:
      case NotificationType.newParticipant:
      case NotificationType.capacityReached:
      case NotificationType.spotAvailable:
        await _navigateToMeetup(notification.relatedId);
        break;
      case NotificationType.partnershipRequest:
      case NotificationType.partnershipAccepted:
      case NotificationType.partnershipRejected:
        if (mounted) context.push('/partnership-requests');
        break;
      case NotificationType.partnershipSuggestion:
      case NotificationType.system:
        break;
    }
  }

  Future<void> _navigateToMeetup(String meetupId) async {
    if (meetupId.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('meetups')
          .doc(meetupId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Etkinlik bulunamadı')));
        }
        return;
      }

      final meetup = MeetupModel.fromJson(doc.data() as Map<String, dynamic>);
      if (mounted) {
        context.push('/detail', extra: meetup);
      }
    } catch (e) {
      debugPrint('Error fetching meetup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Etkinlik yüklenirken hata oluştu')),
        );
      }
    }
  }
}

/// Widget for notification list item
class _NotificationListItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationListItem({
    required this.notification,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.meetupReminder:
        return Icons.access_time;
      case NotificationType.meetupUpdate:
        return Icons.update;
      case NotificationType.meetupCancelled:
        return Icons.cancel;
      case NotificationType.newParticipant:
        return Icons.person_add;
      case NotificationType.chatMessage:
        return Icons.chat_bubble;
      case NotificationType.capacityReached:
        return Icons.groups;
      case NotificationType.spotAvailable:
        return Icons.event_available;
      case NotificationType.partnershipRequest:
        return Icons.handshake;
      case NotificationType.partnershipAccepted:
        return Icons.check_circle;
      case NotificationType.partnershipRejected:
        return Icons.cancel;
      case NotificationType.partnershipSuggestion:
        return Icons.person_add;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.meetupReminder:
        return Colors.blue;
      case NotificationType.meetupUpdate:
        return Colors.orange;
      case NotificationType.meetupCancelled:
        return Colors.red;
      case NotificationType.newParticipant:
        return AppTheme.primary;
      case NotificationType.chatMessage:
        return Colors.purple;
      case NotificationType.capacityReached:
        return Colors.green;
      case NotificationType.spotAvailable:
        return Colors.teal;
      case NotificationType.partnershipRequest:
      case NotificationType.partnershipSuggestion:
        return AppTheme.primary;
      case NotificationType.partnershipAccepted:
        return Colors.green;
      case NotificationType.partnershipRejected:
        return Colors.red;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}sa önce';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  /// Get message count from metadata for chat messages
  int _getMessageCount() {
    if (notification.type == NotificationType.chatMessage) {
      final count = notification.metadata['unreadCount'];
      if (count is int) return count;
      if (count is num) return count.toInt();
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final messageCount = _getMessageCount();
    final isChatMessage = notification.type == NotificationType.chatMessage;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? null
              : AppTheme.primary.withValues(alpha: 0.05),
          border: Border(
            bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon with message count badge for chat messages
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getIconColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getIcon(), color: _getIconColor(), size: 22),
                ),
                // Message count badge for chat messages
                if (isChatMessage && messageCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        messageCount > 99 ? '99+' : '$messageCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content - only title, no subtitle
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(notification.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
