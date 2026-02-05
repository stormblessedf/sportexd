import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Empty state widget for chat list when no chats are available.
///
/// Displays a large icon, message, and optional subtitle with
/// AppTheme colors.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: iconColor ?? AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            // Main message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pre-configured empty state for active chats tab.
class ActiveChatsEmptyState extends StatelessWidget {
  const ActiveChatsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.chat_bubble_outline,
      message: 'Henüz aktif sohbetiniz yok',
      subtitle: 'Etkinliklere katılarak sohbetlere dahil olabilirsiniz',
    );
  }
}

/// Pre-configured empty state for past chats tab.
class PastChatsEmptyState extends StatelessWidget {
  const PastChatsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.history,
      message: 'Henüz geçmiş sohbetiniz yok',
      subtitle: 'Tamamlanan etkinliklerin sohbetleri burada görünecek',
    );
  }
}
