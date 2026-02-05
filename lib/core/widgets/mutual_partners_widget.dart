import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/partnership_service.dart';
import '../../theme/app_theme.dart';

class MutualPartnersWidget extends StatefulWidget {
  final String currentUserId;
  final String profileUserId;

  const MutualPartnersWidget({
    super.key,
    required this.currentUserId,
    required this.profileUserId,
  });

  @override
  State<MutualPartnersWidget> createState() => _MutualPartnersWidgetState();
}

class _MutualPartnersWidgetState extends State<MutualPartnersWidget> {
  final PartnershipService _partnershipService = PartnershipService();
  List<UserModel> _mutualPartners = [];
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMutualPartners();
  }

  Future<void> _loadMutualPartners() async {
    try {
      final partners = await _partnershipService.getMutualPartners(
        widget.currentUserId,
        widget.profileUserId,
      );
      if (mounted) {
        setState(() {
          _mutualPartners = partners;
          _isLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _mutualPartners.isEmpty) return const SizedBox.shrink();

    final count = _mutualPartners.length;
    final names = _mutualPartners.take(3).map((u) => u.username).join(', ');

    return Row(
      children: [
        const Icon(Icons.people, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Senin $count partnerinle ($names) daha önce maç yaptı',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
