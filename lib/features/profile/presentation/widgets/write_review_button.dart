import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class WriteReviewButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const WriteReviewButton({
    super.key,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Tooltip(
      message: isEnabled
          ? l10n.writeReviewTooltip
          : l10n.needSharedEvent,
      child: FloatingActionButton.extended(
        onPressed: isEnabled ? onPressed : null,
        backgroundColor: isEnabled
            ? Theme.of(context).primaryColor
            : Colors.grey[400],
        icon: const Icon(Icons.rate_review),
        label: Text(l10n.writeReviewButton),
      ),
    );
  }
}
