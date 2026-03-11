import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

class ChatListHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String swipeInviteLabel;
  final VoidCallback? onFilterTap;
  final VoidCallback? onSwipeInviteTap;

  const ChatListHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.swipeInviteLabel,
    this.onFilterTap,
    this.onSwipeInviteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _circleButton(
            icon: Icons.sports_handball_rounded,
            onTap: onSwipeInviteTap,
            tooltip: swipeInviteLabel,
          ),
          const SizedBox(width: 8),
          _circleButton(icon: Icons.tune, onTap: onFilterTap, tooltip: null),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback? onTap,
    required String? tooltip,
  }) {
    final button = Material(
      color: const Color(0xFFF1F5F9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppTheme.textMuted),
        ),
      ),
    );

    if (tooltip == null || tooltip.isEmpty) {
      return button;
    }

    return Tooltip(message: tooltip, child: button);
  }
}
