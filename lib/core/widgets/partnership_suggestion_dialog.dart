import 'package:flutter/material.dart';
import '../models/partnership_suggestion_model.dart';
import '../../theme/app_theme.dart';

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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.handshake, color: AppTheme.primary),
          SizedBox(width: 8),
          Text('Partner Önerisi', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: Text(
        suggestion.getMessage(),
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('Şimdi Değil', style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton.icon(
          onPressed: onAccept,
          icon: const Icon(Icons.person_add, size: 18),
          label: const Text('Partner Ekle'),
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
