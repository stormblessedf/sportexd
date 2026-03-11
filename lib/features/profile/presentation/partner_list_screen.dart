import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/partnership_service.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

enum _SortOption { recent, mostMeetups, alphabetical }

class PartnerListScreen extends StatefulWidget {
  final String userId;

  const PartnerListScreen({
    super.key,
    required this.userId,
  });

  @override
  State<PartnerListScreen> createState() => _PartnerListScreenState();
}

class _PartnerListScreenState extends State<PartnerListScreen> {
  final PartnershipService _partnershipService = PartnershipService();

  List<UserModel> _partners = [];
  Map<String, int> _sharedMeetupCounts = {};
  bool _isLoading = true;
  _SortOption _currentSort = _SortOption.recent;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPartners() async {
    setState(() => _isLoading = true);

    try {
      final partners = await _partnershipService.getPartners(widget.userId);

      // Load shared meetup counts for each partner in parallel
      final countFutures = partners.map(
        (partner) => _partnershipService
            .getSharedMeetupCount(widget.userId, partner.id)
            .then((count) => MapEntry(partner.id, count)),
      );
      final countEntries = await Future.wait(countFutures);
      final counts = Map<String, int>.fromEntries(countEntries);

      if (mounted) {
        setState(() {
          _partners = partners;
          _sharedMeetupCounts = counts;
          _isLoading = false;
        });
        _applySorting();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.partnersLoadError(e.toString()))),
        );
      }
    }
  }

  void _applySorting() {
    setState(() {
      switch (_currentSort) {
        case _SortOption.recent:
          // Keep the original order from Firestore (most recently added)
          break;
        case _SortOption.mostMeetups:
          _partners.sort((a, b) {
            final countA = _sharedMeetupCounts[a.id] ?? 0;
            final countB = _sharedMeetupCounts[b.id] ?? 0;
            return countB.compareTo(countA);
          });
          break;
        case _SortOption.alphabetical:
          _partners.sort(
            (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()),
          );
          break;
      }
    });
  }

  void _onSortChanged(_SortOption option) {
    _currentSort = option;
    _applySorting();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.sportPartnersTitle),
        backgroundColor: AppTheme.backgroundLight,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _partners.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildSearchBar(),
                    _buildSortBar(),
                    Expanded(child: _buildPartnerList()),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 72,
            color: AppTheme.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(l10n.noSportPartners,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.findPartnersByJoiningEvents,
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<UserModel> get _filteredPartners {
    if (_searchQuery.isEmpty) return _partners;
    final q = _searchQuery.toLowerCase();
    return _partners.where((p) => p.username.toLowerCase().contains(q)).toList();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: l10n.searchByName,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.borderLight),
          ),
        ),
      ),
    );
  }

  Widget _buildSortBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            l10n.partnerCount(_partners.length),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          _buildSortChip(l10n.sortNewest, _SortOption.recent),
          const SizedBox(width: 8),
          _buildSortChip(l10n.mostMeetups, _SortOption.mostMeetups),
          const SizedBox(width: 8),
          _buildSortChip(l10n.sortNameAZ, _SortOption.alphabetical),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, _SortOption option) {
    final isSelected = _currentSort == option;
    return GestureDetector(
      onTap: () => _onSortChanged(option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppTheme.primary : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerList() {
    final list = _filteredPartners;
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Sonuç bulunamadı',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPartners,
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final partner = list[index];
          final sharedCount = _sharedMeetupCounts[partner.id] ?? 0;
          return _buildPartnerCard(partner, sharedCount);
        },
      ),
    );
  }

  Widget _buildPartnerCard(UserModel partner, int sharedMeetupCount) {
    return InkWell(
      onTap: () {
        context.push('/user-profile/${partner.id}');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            // Profile avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primary,
              backgroundImage: partner.profileImageUrl != null
                  ? NetworkImage(partner.profileImageUrl!)
                  : null,
              child: partner.profileImageUrl == null
                  ? Text(
                      partner.username.isNotEmpty
                          ? partner.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Partner info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username and rating row
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          partner.username,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (partner.averageRating > 0) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          partner.averageRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Location row
                  if (partner.location != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppTheme.textMuted.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            partner.location!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted.withValues(alpha: 0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Shared meetup count
                  Row(
                    children: [
                      Icon(
                        Icons.sports_outlined,
                        size: 14,
                        color: AppTheme.primary.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.sharedMeetupCount(sharedMeetupCount),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

