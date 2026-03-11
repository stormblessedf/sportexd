import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/meetup_model.dart';
import '../../../core/services/meetup_service.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class UserMeetupsScreen extends StatefulWidget {
  final String userId;

  const UserMeetupsScreen({super.key, required this.userId});

  @override
  State<UserMeetupsScreen> createState() => _UserMeetupsScreenState();
}

class _UserMeetupsScreenState extends State<UserMeetupsScreen> {
  final MeetupService _meetupService = MeetupService();
  String _filter = 'all';

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  IconData _getSportIcon(MeetupType type) {
    switch (type) {
      case MeetupType.football: return Icons.sports_soccer;
      case MeetupType.basketball: return Icons.sports_basketball;
      case MeetupType.volleyball: return Icons.sports_volleyball;
      case MeetupType.tennis:
      case MeetupType.tableTennis:
      case MeetupType.badminton: return Icons.sports_tennis;
      case MeetupType.swimming: return Icons.pool;
      case MeetupType.running: return Icons.directions_run;
      case MeetupType.cycling: return Icons.directions_bike;
      case MeetupType.hiking: return Icons.terrain;
      case MeetupType.yoga: return Icons.self_improvement;
      case MeetupType.fitness: return Icons.fitness_center;
      case MeetupType.boxing: return Icons.sports_mma;
      case MeetupType.climbing: return Icons.landscape;
      case MeetupType.skiing: return Icons.downhill_skiing;
      default: return Icons.sports;
    }
  }

  Color _getSportColor(MeetupType type) {
    switch (type) {
      case MeetupType.football: return const Color(0xFF4CAF50);
      case MeetupType.basketball: return const Color(0xFFFF9800);
      case MeetupType.volleyball: return const Color(0xFF2196F3);
      case MeetupType.tennis:
      case MeetupType.tableTennis: return const Color(0xFFCDDC39);
      case MeetupType.badminton: return const Color(0xFF00BCD4);
      case MeetupType.swimming: return const Color(0xFF03A9F4);
      case MeetupType.running: return const Color(0xFFFF5722);
      case MeetupType.cycling: return const Color(0xFF795548);
      case MeetupType.hiking: return const Color(0xFF8BC34A);
      case MeetupType.yoga: return const Color(0xFF9C27B0);
      case MeetupType.fitness: return const Color(0xFFE91E63);
      case MeetupType.boxing: return const Color(0xFFF44336);
      case MeetupType.climbing: return const Color(0xFF607D8B);
      case MeetupType.skiing: return const Color(0xFF00BCD4);
      default: return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
        title: Text(l10n.participatedMeetups, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<MeetupModel>>(
        stream: _meetupService.getPastMeetupsForUser(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Text(l10n.errorOccurred, style: TextStyle(color: Colors.red[300], fontSize: 16)),
                ],
              ),
            );
          }

          final meetups = snapshot.data ?? [];
          if (meetups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(l10n.noEventsAttended,
                    style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          final sportTypes = meetups.map((m) => m.type).toSet().toList();
          sportTypes.sort((a, b) => a.displayName.compareTo(b.displayName));
          final filtered = _filter == 'all' ? meetups : meetups.where((m) => m.type.name == _filter).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildSummaryHeader(meetups)),
              SliverToBoxAdapter(child: _buildFilterChips(sportTypes, meetups)),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${filtered.length}${l10n.eventCount}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: EdgeInsets.only(bottom: index < filtered.length - 1 ? 10 : 0),
                      child: _buildMeetupCard(filtered[index]),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(List<MeetupModel> meetups) {
    final typeCounts = <MeetupType, int>{};
    for (final m in meetups) { typeCounts[m.type] = (typeCounts[m.type] ?? 0) + 1; }
    final sorted = typeCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withValues(alpha: 0.12), AppTheme.primary.withValues(alpha: 0.04)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.groups, color: AppTheme.primary, size: 24),
              const SizedBox(width: 8),
              Text('${meetups.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ],
          ),
          const SizedBox(height: 2),
          Text(l10n.totalEvents, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          if (top3.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: top3.map((entry) {
                final color = _getSportColor(entry.key);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getSportIcon(entry.key), size: 14, color: color),
                        const SizedBox(width: 4),
                        Text('${entry.value}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChips(List<MeetupType> sportTypes, List<MeetupModel> meetups) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip(l10n.all, 'all', null),
          ...sportTypes.map((type) {
            final count = meetups.where((m) => m.type == type).length;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildChip('${type.displayName} ($count)', type.name, type),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value, MeetupType? type) {
    final isSelected = _filter == value;
    final color = type != null ? _getSportColor(type) : AppTheme.primary;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : const Color(0xFFE2E8F0)),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? color : Colors.grey[600])),
      ),
    );
  }

  Widget _buildMeetupCard(MeetupModel meetup) {
    final sportColor = _getSportColor(meetup.type);
    final dateStr = DateFormat('dd MMM yyyy, HH:mm', Localizations.localeOf(context).toString()).format(meetup.date);
    final participantCount = meetup.participantIds.length;
    final maxParticipants = meetup.maxParticipants;

    return GestureDetector(
      onTap: () => context.push('/detail', extra: meetup),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: sportColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: sportColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                    child: Icon(_getSportIcon(meetup.type), color: sportColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meetup.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.calendar_today, size: 13, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.location_on, size: 13, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Expanded(child: Text(meetup.locationName, style: TextStyle(fontSize: 12, color: Colors.grey[400]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: sportColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(meetup.type.displayName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sportColor)),
                      ),
                      const SizedBox(height: 8),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 2),
                        Text('$participantCount/$maxParticipants', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[500])),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



