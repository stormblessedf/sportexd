import 'package:flutter/material.dart';
import '../../domain/models/models.dart';

/// Yayın kalitesi ayarları bottom sheet
class QualitySettingsSheet extends StatelessWidget {
  final StreamQuality currentQuality;
  final ValueChanged<StreamQuality> onQualitySelected;

  const QualitySettingsSheet({
    super.key,
    required this.currentQuality,
    required this.onQualitySelected,
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
              'Yayın Kalitesi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Kalite seçenekleri
          ...StreamQuality.values.map((quality) {
            final isSelected = quality == currentQuality;
            return ListTile(
              leading: Icon(
                _getQualityIcon(quality),
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(quality.displayName),
              subtitle: Text(_getQualityDescription(quality)),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () => onQualitySelected(quality),
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getQualityIcon(StreamQuality quality) {
    switch (quality) {
      case StreamQuality.auto:
        return Icons.auto_awesome;
      case StreamQuality.quality1080p:
        return Icons.hd;
      case StreamQuality.quality720p:
        return Icons.high_quality;
      case StreamQuality.quality480p:
        return Icons.sd;
      case StreamQuality.quality360p:
        return Icons.low_priority;
    }
  }

  String _getQualityDescription(StreamQuality quality) {
    switch (quality) {
      case StreamQuality.auto:
        return 'Bağlantı hızınıza göre otomatik ayarlanır';
      case StreamQuality.quality1080p:
        return 'Full HD - En yüksek kalite';
      case StreamQuality.quality720p:
        return 'HD - İyi kalite';
      case StreamQuality.quality480p:
        return 'SD - Orta kalite';
      case StreamQuality.quality360p:
        return 'Düşük - Yavaş bağlantılar için';
    }
  }
}
