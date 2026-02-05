import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../theme/app_theme.dart';

class InAppBanner extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const InAppBanner({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<InAppBanner> createState() => _InAppBannerState();
}

class _InAppBannerState extends State<InAppBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Start animation
    _animationController.forward();

    // Auto-dismiss after 3 seconds
    _autoDismissTimer = Timer(const Duration(seconds: 3), _dismiss);
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    _autoDismissTimer?.cancel();
    await _animationController.reverse();
    widget.onDismiss();
  }

  IconData _getIcon() {
    switch (widget.notification.type) {
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
    switch (widget.notification.type) {
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
        return const Color(0xFF13EC5B);
      case NotificationType.partnershipAccepted:
        return Colors.green;
      case NotificationType.partnershipRejected:
        return Colors.red;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: InkWell(
              onTap: () {
                _autoDismissTimer?.cancel();
                widget.onTap();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getIconColor().withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _getIconColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getIcon(), color: _getIconColor(), size: 24),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.notification.message,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dismiss button
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _dismiss,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay entry for showing in-app banners
class InAppBannerOverlay {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required NotificationModel notification,
    required VoidCallback onTap,
  }) {
    // Remove existing banner if any
    hide();

    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: InAppBanner(
          notification: notification,
          onTap: () {
            hide();
            onTap();
          },
          onDismiss: hide,
        ),
      ),
    );

    Overlay.of(context).insert(_currentEntry!);
  }

  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
