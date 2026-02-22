import 'package:flutter/material.dart';
import '../../domain/models/models.dart';

/// Yayın gizlilik ayarları bottom sheet
class PrivacySettingsSheet extends StatelessWidget {
  final PrivacyLevel currentPrivacy;
  final ValueChanged<PrivacyLevel> onPrivacySelected;

  const PrivacySettingsSheet({
    super.key,
    required this.currentPrivacy,
    required this.onPrivacySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Gizlilik Ayarları',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Yayınınızı kimler izleyebilsin?',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Gizlilik seçenekleri
          ...PrivacyLevel.values.map((privacy) {
            final isSelected = privacy == currentPrivacy;
            return ListTile(
              leading: Icon(
                _getPrivacyIcon(privacy),
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(privacy.displayName),
              subtitle: Text(privacy.description),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () => onPrivacySelected(privacy),
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getPrivacyIcon(PrivacyLevel privacy) {
    switch (privacy) {
      case PrivacyLevel.public:
        return Icons.public;
      case PrivacyLevel.followersOnly:
        return Icons.people;
      case PrivacyLevel.participantsOnly:
        return Icons.lock;
    }
  }
}
