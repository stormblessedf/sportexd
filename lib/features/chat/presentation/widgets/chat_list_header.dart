import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Header widget for the chat list screen.
///
/// Displays the title "Sohbetler", subtitle "Etkinlik Sohbetleri",
/// and a circular filter button.
class ChatListHeader extends StatelessWidget {
  final VoidCallback? onFilterTap;

  const ChatListHeader({super.key, this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Sohbetler',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '• Etkinlik Sohbetleri',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const Spacer(),
          _buildFilterButton(context),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F5F9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onFilterTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: const Icon(Icons.tune, size: 20, color: AppTheme.textMuted),
        ),
      ),
    );
  }
}
