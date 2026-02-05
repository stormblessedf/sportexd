import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/meetup_model.dart';
import '../../../../core/models/message_model.dart';
import '../../../../core/utils/relative_timestamp.dart';
import '../../../../theme/app_theme.dart';
import 'activity_badge.dart';

/// A modern chat card widget displaying conversation information.
///
/// Shows profile image with activity badge, event title, status,
/// last message preview, timestamp, and unread indicator.
class ChatCard extends StatelessWidget {
  final MeetupModel meetup;
  final MessageModel? lastMessage;
  final int unreadCount;
  final DateTime? lastActivityTime;
  final String currentUserId;
  final VoidCallback onTap;
  final bool isPast;
  final bool isOrganizerOnlyMode;

  const ChatCard({
    super.key,
    required this.meetup,
    this.lastMessage,
    required this.unreadCount,
    this.lastActivityTime,
    required this.currentUserId,
    required this.onTap,
    this.isPast = false,
    this.isOrganizerOnlyMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: AppTheme.primary.withValues(alpha: 0.1),
      highlightColor: const Color(0xFFF1F5F9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile image with activity badge
            _buildProfileImage(),
            const SizedBox(width: 12),
            // Chat information
            Expanded(child: _buildChatInfo(context)),
            // Timestamp and unread indicator
            _buildRightColumn(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Profile image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: meetup.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    meetup.title.isNotEmpty
                        ? meetup.title[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Activity badge
          Positioned(
            bottom: -4,
            right: -4,
            child: ActivityBadge(meetupType: meetup.type, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Event title with lock icon
        Row(
          children: [
            Expanded(
              child: Text(
                meetup.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            if (isOrganizerOnlyMode) ...[
              const SizedBox(width: 4),
              const Icon(Icons.lock, size: 14, color: Colors.orange),
            ],
          ],
        ),
        const SizedBox(height: 2),
        // Event status/time
        Text(
          isPast
              ? 'TAMAMLANDI'
              : RelativeTimestamp.formatMeetupStatus(meetup.date),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isPast ? AppTheme.textMuted : AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        // Last message preview
        _buildMessagePreview(),
      ],
    );
  }

  Widget _buildMessagePreview() {
    if (lastMessage == null) {
      return const Text(
        'Henüz mesaj yok',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textLight,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final isCurrentUser = lastMessage!.senderId == currentUserId;
    final senderPrefix = isCurrentUser ? 'Sen' : lastMessage!.senderName;

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
        children: [
          TextSpan(
            text: '$senderPrefix: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
            ),
          ),
          TextSpan(text: lastMessage!.text),
        ],
      ),
    );
  }

  Widget _buildRightColumn(BuildContext context) {
    final timestamp = lastMessage?.timestamp ?? lastActivityTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timestamp
        Text(
          timestamp != null ? RelativeTimestamp.format(timestamp) : '',
          style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
        ),
        const SizedBox(height: 8),
        // Unread indicator
        if (unreadCount > 0)
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6), // Blue color for unread
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

/// Custom divider that starts after the profile image.
class ChatDivider extends StatelessWidget {
  const ChatDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(
        left: 84,
      ), // 16 (padding) + 56 (image) + 12 (gap)
      child: Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
    );
  }
}
