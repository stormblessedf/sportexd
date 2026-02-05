import 'package:flutter/material.dart';

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
    return Tooltip(
      message: isEnabled
          ? 'Değerlendirme yap'
          : 'Birlikte etkinlik yapmanız gerekiyor',
      child: FloatingActionButton.extended(
        onPressed: isEnabled ? onPressed : null,
        backgroundColor: isEnabled
            ? Theme.of(context).primaryColor
            : Colors.grey[400],
        icon: const Icon(Icons.rate_review),
        label: const Text('Değerlendirme Yaz'),
      ),
    );
  }
}
