import 'package:flutter/material.dart';
import '../models/partnership_suggestion_model.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class PartnershipSuggestionDialog extends StatelessWidget {
  final PartnershipSuggestionModel suggestion;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const PartnershipSuggestionDialog({
    super.key,
    required this.suggestion,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.handshake, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(l10n.partnerSuggestionTitle, style: const TextStyle(fontSize: 18)),
        ],
      ),
      content: Text(
        suggestion.getMessage(),
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: Text(l10n.notNow, style: const TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton.icon(
          onPressed: onAccept,
          icon: const Icon(Icons.person_add, size: 18),
          label: Text(l10n.addPartner),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
