import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/meetup_model.dart';
import '../../../core/services/meetup_service.dart';
import '../../home/presentation/widgets/meetup_card.dart';

enum PastMeetupSort { newest, oldest, title, type }

class PastMeetupsScreen extends StatefulWidget {
  final String userId;

  const PastMeetupsScreen({super.key, required this.userId});

  @override
  State<PastMeetupsScreen> createState() => _PastMeetupsScreenState();
}

class _PastMeetupsScreenState extends State<PastMeetupsScreen> {
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF13EC5B);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  PastMeetupSort _currentSort = PastMeetupSort.newest;

  List<MeetupModel> _sortMeetups(List<MeetupModel> meetups) {
    final sorted = List<MeetupModel>.from(meetups);
    switch (_currentSort) {
      case PastMeetupSort.newest:
        sorted.sort((a, b) => b.date.compareTo(a.date));
        break;
      case PastMeetupSort.oldest:
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
      case PastMeetupSort.title:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case PastMeetupSort.type:
        sorted.sort((a, b) => a.type.displayName.compareTo(b.type.displayName));
        break;
    }
    return sorted;
  }

  String _sortLabel(PastMeetupSort sort) {
    switch (sort) {
      case PastMeetupSort.newest:
        return 'En Yeni';
      case PastMeetupSort.oldest:
        return 'En Eski';
      case PastMeetupSort.title:
        return 'İsim (A-Z)';
      case PastMeetupSort.type:
        return 'Spor Türü';
    }
  }

  IconData _sortIcon(PastMeetupSort sort) {
    switch (sort) {
      case PastMeetupSort.newest:
        return Icons.arrow_downward;
      case PastMeetupSort.oldest:
        return Icons.arrow_upward;
      case PastMeetupSort.title:
        return Icons.sort_by_alpha;
      case PastMeetupSort.type:
        return Icons.sports;
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetupService = MeetupService();

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('Geçmiş Etkinliklerim'),
        backgroundColor: backgroundLight,
        foregroundColor: textDark,
        elevation: 0,
      ),
      body: StreamBuilder<List<MeetupModel>>(
        stream: meetupService.getPastMeetupsForUser(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Bir hata oluştu',
                    style: TextStyle(
                      color: Colors.red[300],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: textMuted, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final pastMeetups = snapshot.data ?? [];

          if (pastMeetups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    'Henüz geçmiş etkinliğiniz yok',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Etkinliklere katılmaya başlayın!',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.explore),
                    label: const Text('Etkinlikleri Keşfet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: textDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final sortedMeetups = _sortMeetups(pastMeetups);

          return Column(
            children: [
              // Sort chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: PastMeetupSort.values.map((sort) {
                    final isSelected = _currentSort == sort;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _sortIcon(sort),
                              size: 14,
                              color: isSelected ? Colors.white : textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(_sortLabel(sort)),
                          ],
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : textDark,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        backgroundColor: surfaceLight,
                        selectedColor: primary,
                        checkmarkColor: Colors.white,
                        showCheckmark: false,
                        side: BorderSide(
                          color: isSelected ? primary : const Color(0xFFE2E8F0),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (_) {
                          setState(() => _currentSort = sort);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Count
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${sortedMeetups.length} etkinlik',
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // List
              Expanded(
                child: RefreshIndicator(
                  color: primary,
                  backgroundColor: surfaceLight,
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: sortedMeetups.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final meetup = sortedMeetups[index];
                      return MeetupCard(
                        meetup: meetup,
                        onTap: () {
                          context.push('/detail', extra: meetup);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
