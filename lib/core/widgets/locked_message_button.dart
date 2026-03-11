import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class LockedMessageButton extends StatelessWidget {
  final bool isLocked;
  final VoidCallback? onPressed;

  const LockedMessageButton({
    super.key,
    required this.isLocked,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLocked) {
      return OutlinedButton.icon(
        onPressed: () => _showLockedAlert(context),
        icon: const Icon(Icons.lock_outline, size: 18),
        label: Text(l10n.chat),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textLight,
          side: const BorderSide(color: AppTheme.borderLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.message, size: 18),
      label: Text(l10n.chat),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  void _showLockedAlert(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock, color: AppTheme.textMuted),
            const SizedBox(width: 8),
            Text(l10n.lockedMessageTitle, style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(
          l10n.lockedMessageDescription,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.okButton),
          ),
        ],
      ),
    );
  }
}
