import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class AboutMeCard extends StatelessWidget {
  final String? bio;
  final int maxLength;

  const AboutMeCard({
    super.key,
    this.bio,
    this.maxLength = 300,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show if bio is empty
    if (bio == null || bio!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // Truncate bio if too long
    final displayBio = bio!.length > maxLength
        ? '${bio!.substring(0, maxLength)}...'
        : bio!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'HAKKIMDA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Bio text with emoji support
            Text(
              displayBio,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textDark,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
