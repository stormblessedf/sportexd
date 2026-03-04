import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/core/models/search_query_model.dart';
import 'package:sporsal/theme/app_colors.dart';

/// Emoji mapping for each MeetupType (same as SportTypeGrid).
const _sportEmojis = <MeetupType, String>{
  MeetupType.football: '⚽',
  MeetupType.basketball: '🏀',
  MeetupType.volleyball: '🏐',
  MeetupType.tennis: '🎾',
  MeetupType.tableTennis: '🏓',
  MeetupType.badminton: '🏸',
  MeetupType.swimming: '🏊',
  MeetupType.running: '🏃',
  MeetupType.cycling: '🚴',
  MeetupType.hiking: '🥾',
  MeetupType.yoga: '🧘',
  MeetupType.fitness: '💪',
  MeetupType.boxing: '🥊',
  MeetupType.climbing: '🧗',
  MeetupType.skiing: '⛷️',
  MeetupType.other: '🏅',
};

/// Callback-based DI signatures for testability without SharedPreferences.
typedef RecentSearchesFetcher = Future<List<SearchQueryModel>> Function();
typedef SearchDeleter = Future<void> Function(String id);

/// Displays recent venue searches with swipe-to-delete support.
///
/// Each item shows the sport type emoji, region name, and relative date.
/// Tapping an item triggers [onSearchTap] to re-run the query.
///
/// Validates: Requirements 12.2, 12.3, 12.5
class RecentSearchesList extends StatefulWidget {
  const RecentSearchesList({
    super.key,
    required this.onSearchTap,
    required this.recentSearchesFetcher,
    required this.searchDeleter,
  });

  /// Called when a search item is tapped to re-run the query.
  final ValueChanged<SearchQueryModel> onSearchTap;

  /// Fetches recent searches (newest first).
  final RecentSearchesFetcher recentSearchesFetcher;

  /// Deletes a single search by ID.
  final SearchDeleter searchDeleter;

  @override
  State<RecentSearchesList> createState() => _RecentSearchesListState();
}

class _RecentSearchesListState extends State<RecentSearchesList> {
  List<SearchQueryModel> _searches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSearches();
  }

  Future<void> _loadSearches() async {
    final results = await widget.recentSearchesFetcher();
    if (!mounted) return;
    setState(() {
      _searches = results;
      _isLoading = false;
    });
  }

  Future<void> _deleteSearch(String id) async {
    await widget.searchDeleter(id);
    if (!mounted) return;
    setState(() {
      _searches.removeWhere((s) => s.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (_searches.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _searches.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 56,
        color: AppColors.borderLight,
      ),
      itemBuilder: (context, index) {
        final search = _searches[index];
        return _RecentSearchItem(
          search: search,
          onTap: () => widget.onSearchTap(search),
          onDismissed: () => _deleteSearch(search.id),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Center(
        child: Text(
          'Henüz arama geçmişi yok',
          style: GoogleFonts.lexend(
            fontSize: 14,
            color: AppColors.textLight,
          ),
        ),
      ),
    );
  }
}

/// A single recent search row with swipe-to-delete via [Dismissible].
class _RecentSearchItem extends StatelessWidget {
  const _RecentSearchItem({
    required this.search,
    required this.onTap,
    required this.onDismissed,
  });

  final SearchQueryModel search;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final emoji = _sportEmojis[search.sportType] ?? '🏅';
    final title = '${search.sportType.displayName} - ${search.regionName}';
    final subtitle = _formatRelativeDate(search.searchedAt);

    return Dismissible(
      key: ValueKey(search.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error.withValues(alpha: 0.1),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.error,
          size: 22,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Sport emoji
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron
              const Icon(
                Icons.chevron_right,
                color: AppColors.textLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formats a [DateTime] as a Turkish relative date string.
///
/// Examples: "Bugün", "Dün", "3 gün önce", "2 hafta önce", "1 ay önce"
String _formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;

  if (diff <= 0) return 'Bugün';
  if (diff == 1) return 'Dün';
  if (diff < 7) return '$diff gün önce';
  if (diff < 30) {
    final weeks = (diff / 7).floor();
    return '$weeks hafta önce';
  }
  final months = (diff / 30).floor();
  if (months == 1) return '1 ay önce';
  return '$months ay önce';
}
