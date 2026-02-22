import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/user_model.dart';
import 'package:sporsal/core/services/partnership_service.dart';
import 'package:sporsal/theme/app_theme.dart';

/// Signature for loading mutual partners between two users.
typedef MutualPartnersLoader = Future<List<UserModel>> Function(
    String userId1, String userId2);

class MutualPartnersBar extends StatefulWidget {
  final String currentUserId;
  final String profileUserId;
  final MutualPartnersLoader? loader;

  const MutualPartnersBar({
    super.key,
    required this.currentUserId,
    required this.profileUserId,
    this.loader,
  });

  @override
  State<MutualPartnersBar> createState() => _MutualPartnersBarState();
}

class _MutualPartnersBarState extends State<MutualPartnersBar> {
  List<UserModel> _mutualPartners = [];
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMutualPartners();
  }

  Future<void> _loadMutualPartners() async {
    try {
      final load =
          widget.loader ?? PartnershipService().getMutualPartners;
      final partners = await load(
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
      if (mounted) {
        setState(() => _isLoaded = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _mutualPartners.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayCount =
        _mutualPartners.length > 3 ? 3 : _mutualPartners.length;
    final extraCount = _mutualPartners.length - 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: displayCount * 18.0 + 6.0 + (extraCount > 0 ? 24 : 0),
            height: 24,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < displayCount; i++)
                  Positioned(
                    left: i * 18.0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.2),
                        backgroundImage:
                            _mutualPartners[i].profileImageUrl != null
                                ? NetworkImage(
                                    _mutualPartners[i].profileImageUrl!)
                                : null,
                        child: _mutualPartners[i].profileImageUrl == null
                            ? Icon(Icons.person,
                                size: 12, color: Colors.grey[400])
                            : null,
                      ),
                    ),
                  ),
                if (extraCount > 0)
                  Positioned(
                    left: displayCount * 18.0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          '+$extraCount',
                          style: GoogleFonts.lexend(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${_mutualPartners.length} ',
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  TextSpan(
                    text: 'ortak spor partneriniz',
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
