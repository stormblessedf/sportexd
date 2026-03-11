import 'package:flutter/material.dart';
import '../../../../core/models/meetup_model.dart';
import '../../../../core/models/position_slot.dart';
import '../../../../l10n/app_localizations.dart';

/// Widget for displaying team lineup in football meetups
class TeamLineupWidget extends StatelessWidget {
  final MeetupModel meetup;
  final String? currentUserId;

  const TeamLineupWidget({super.key, required this.meetup, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Only show for football meetups with teams
    if (!meetup.isFootballWithTeams) {
      return const SizedBox.shrink();
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.sports_soccer, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.formationLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  meetup.formation ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.teamA),
                      const SizedBox(width: 4),
                      _buildFilledCount(context, meetup.teamASlots),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.teamB),
                      const SizedBox(width: 4),
                      _buildFilledCount(context, meetup.teamBSlots),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab content
          SizedBox(
            height: _calculateHeight(_maxSlotCount()),
            child: TabBarView(
              children: [
                _buildTeamSlots(context, meetup.teamASlots),
                _buildTeamSlots(context, meetup.teamBSlots),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilledCount(BuildContext context, List<PositionSlot>? slots) {
    if (slots == null) return const SizedBox.shrink();

    final filled = slots.where((s) => s.isFilled).length;
    final total = slots.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: filled == total
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$filled/$total',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: filled == total ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  int _maxSlotCount() {
    final teamACount = meetup.teamASlots?.length ?? 0;
    final teamBCount = meetup.teamBSlots?.length ?? 0;
    return teamACount > teamBCount ? teamACount : teamBCount;
  }

  double _calculateHeight(int slotCount) {
    // Keep lineup compact but scrollable for larger slot counts.
    final estimatedHeight = (slotCount * 72.0) + 16;
    return estimatedHeight.clamp(220.0, 420.0).toDouble();
  }

  Widget _buildTeamSlots(BuildContext context, List<PositionSlot>? slots) {
    if (slots == null || slots.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noPositionInfo));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _PositionSlotCard(
            slot: slot,
            isCurrentUser: slot.assignedUserId == currentUserId,
          ),
        );
      },
    );
  }
}

class _PositionSlotCard extends StatelessWidget {
  final PositionSlot slot;
  final bool isCurrentUser;

  const _PositionSlotCard({required this.slot, this.isCurrentUser = false});

  Color _getPositionColor() {
    switch (slot.position) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final positionColor = _getPositionColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? colorScheme.primary
              : slot.isEmpty
              ? colorScheme.outlineVariant
              : positionColor.withValues(alpha: 0.3),
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Position badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: positionColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: positionColor.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                slot.shortName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: positionColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User info or empty state
          Expanded(
            child: slot.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        l10n.open,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // User avatar
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: positionColor.withValues(alpha: 0.2),
                        backgroundImage: slot.assignedUserImageUrl != null
                            ? NetworkImage(slot.assignedUserImageUrl!)
                            : null,
                        child: slot.assignedUserImageUrl == null
                            ? Text(
                                slot.assignedUserName?.isNotEmpty == true
                                    ? slot.assignedUserName![0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: positionColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot.assignedUserName ?? l10n.unknownUser,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              slot.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          // Status indicator
          if (slot.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.open,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            )
          else if (isCurrentUser)
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}


