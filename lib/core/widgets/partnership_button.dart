import 'package:flutter/material.dart';
import '../models/partnership_model.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class PartnershipButtonWidget extends StatelessWidget {
  final String currentUserId;
  final String profileUserId;
  final PartnershipModel? partnership;
  final List<String> sharedMeetupIds;
  final VoidCallback? onSendRequest;
  final VoidCallback? onAcceptRequest;
  final bool isLoading;

  const PartnershipButtonWidget({
    super.key,
    required this.currentUserId,
    required this.profileUserId,
    this.partnership,
    this.sharedMeetupIds = const [],
    this.onSendRequest,
    this.onAcceptRequest,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    if (partnership?.status == PartnershipStatus.blocked) {
      return const SizedBox.shrink();
    }

    if (partnership?.status == PartnershipStatus.accepted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.handshake, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.partnerBadge,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (partnership?.status == PartnershipStatus.pending && partnership?.userId == currentUserId) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.schedule, size: 18),
        label: Text(l10n.requestSentStatus),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textMuted,
          side: const BorderSide(color: AppTheme.borderLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      );
    }

    if (partnership?.status == PartnershipStatus.pending && partnership?.partnerId == currentUserId) {
      return ElevatedButton.icon(
        onPressed: onAcceptRequest,
        icon: const Icon(Icons.check, size: 18),
        label: Text(l10n.acceptRequest),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      );
    }

    if (sharedMeetupIds.isEmpty) {
      return Tooltip(
        message: l10n.partnerRequiresSharedEvent,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.person_add_disabled, size: 18),
          label: Text(l10n.addPartner),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textLight,
            side: const BorderSide(color: AppTheme.borderLight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onSendRequest,
      icon: const Icon(Icons.person_add, size: 18),
      label: Text(l10n.addPartner),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}
