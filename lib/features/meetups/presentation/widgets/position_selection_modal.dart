import 'package:flutter/material.dart';
import '../../../../core/models/meetup_model.dart';
import '../../../../core/models/position_slot.dart';
import '../../../../core/services/meetup_service.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Bottom sheet for selecting a position when joining a football meetup.
/// Uses a side-by-side two-column layout matching the detail screen's
/// "Kadro Düzeni" board so users see both teams at once.
class PositionSelectionModal extends StatefulWidget {
  final MeetupModel meetup;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final VoidCallback onJoined;

  const PositionSelectionModal({
    super.key,
    required this.meetup,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.onJoined,
  });

  static Future<bool> show({
    required BuildContext context,
    required MeetupModel meetup,
    required String userId,
    required String userName,
    String? userImageUrl,
    required VoidCallback onJoined,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PositionSelectionModal(
        meetup: meetup,
        userId: userId,
        userName: userName,
        userImageUrl: userImageUrl,
        onJoined: onJoined,
      ),
    );
    return result ?? false;
  }

  @override
  State<PositionSelectionModal> createState() => _PositionSelectionModalState();
}

class _PositionSelectionModalState extends State<PositionSelectionModal> {
  String? _selectedTeam;
  int? _selectedSlotIndex;
  bool _isLoading = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  void _selectSlot(String team, int index) {
    setState(() {
      _selectedTeam = team;
      _selectedSlotIndex = index;
    });
  }

  bool get _hasValidSelection =>
      _selectedTeam != null && _selectedSlotIndex != null;

  Future<void> _confirmJoin() async {
    if (!_hasValidSelection) return;
    setState(() => _isLoading = true);

    try {
      final meetupService = context.read<MeetupService>();
      await meetupService.joinMeetupWithPosition(
        meetupId: widget.meetup.id,
        userId: widget.userId,
        userName: widget.userName,
        team: _selectedTeam!,
        slotIndex: _selectedSlotIndex!,
        userImageUrl: widget.userImageUrl,
      );
      if (mounted) {
        widget.onJoined();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.80,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                Icon(Icons.sports_soccer, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.selectPositionTitle,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        '${widget.meetup.teamFormat} - ${widget.meetup.formation}',
                        style:
                            TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),

          // Side-by-side pitch board
          Expanded(child: _buildPitchBoard()),

          // Bottom button
          _buildBottomButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildPitchBoard() {
    final teamASlots = widget.meetup.teamASlots ?? const <PositionSlot>[];
    final teamBSlots = widget.meetup.teamBSlots ?? const <PositionSlot>[];

    if (teamASlots.isEmpty && teamBSlots.isEmpty) {
      return Center(child: Text(l10n.noPositionInfo));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8FAEE), Color(0xFFF5FCF8)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF13EC5B).withValues(alpha: 0.2),
        ),
      ),
      child: Stack(
        children: [
          // Center divider line
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 1.2,
                  color: const Color(0xFF13EC5B).withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
          // Center circle
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF13EC5B).withValues(alpha: 0.22),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Two columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTeamColumn(l10n.teamA, teamASlots, 'A'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTeamColumn(l10n.teamB, teamBSlots, 'B'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamColumn(
      String teamName, List<PositionSlot> slots, String team) {
    final positionCounters = <String, int>{};

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  teamName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...slots.asMap().entries.map((entry) {
              final index = entry.key;
              final slot = entry.value;
              positionCounters[slot.position] =
                  (positionCounters[slot.position] ?? 0) + 1;
              final slotOrder = positionCounters[slot.position]!;
              final isSelected =
                  _selectedTeam == team && _selectedSlotIndex == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: slot.isEmpty ? () => _selectSlot(team, index) : null,
                  child: _buildSlotTile(
                    slot: slot,
                    slotOrder: slotOrder,
                    isSelected: isSelected,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotTile({
    required PositionSlot slot,
    required int slotOrder,
    required bool isSelected,
  }) {
    final bool isOrganizer =
        slot.assignedUserId == widget.meetup.organizerId;

    if (slot.isFilled) {
      final accent = _positionColor(slot.position);
      final initial = (slot.assignedUserName ?? '?').trim().isNotEmpty
          ? slot.assignedUserName!.trim()[0].toUpperCase()
          : '?';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isOrganizer
                  ? Colors.amber.withValues(alpha: 0.3)
                  : accent.withValues(alpha: 0.2),
              backgroundImage: slot.assignedUserImageUrl != null
                  ? NetworkImage(slot.assignedUserImageUrl!)
                  : null,
              child: slot.assignedUserImageUrl == null
                  ? Text(
                      isOrganizer ? 'K' : initial,
                      style: TextStyle(
                        color:
                            isOrganizer ? Colors.amber.shade800 : accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.assignedUserName ?? 'Bilinmeyen',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isOrganizer
                        ? 'Kaptan'
                        : _slotDisplayName(slot.position, slotOrder),
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Empty slot — selectable with dashed or selected border
    if (isSelected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF13EC5B).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFF13EC5B),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF13EC5B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(Icons.check, size: 16, color: Color(0xFF13EC5B)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _slotDisplayName(slot.position, slotOrder),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Empty, not selected — dashed border
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: Colors.grey.shade400,
        strokeWidth: 1.2,
        dashWidth: 5,
        dashSpace: 3,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(999),
              ),
              child:
                  Icon(Icons.add, size: 16, color: Colors.grey.shade500),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _slotDisplayName(slot.position, slotOrder),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                (_hasValidSelection && !_isLoading) ? _confirmJoin : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _hasValidSelection
                        ? 'Takım $_selectedTeam\'ya Katıl'
                        : 'Pozisyon Seçin',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  String _slotDisplayName(String position, int order) {
    switch (position) {
      case 'goalkeeper':
        return 'Kaleci';
      case 'defender':
        return 'Defans $order';
      case 'midfielder':
        return 'Orta $order';
      case 'forward':
        return 'Forvet $order';
      default:
        return position;
    }
  }

  Color _positionColor(String position) {
    switch (position) {
      case 'goalkeeper':
        return Colors.orange;
      case 'defender':
        return Colors.blue;
      case 'midfielder':
        return Colors.green;
      case 'forward':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// Dashed stadium-shaped border painter
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.height / 2),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance = end + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashWidth != oldDelegate.dashWidth ||
      dashSpace != oldDelegate.dashSpace;
}


