import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/discovery_controller.dart';
import '../../../core/models/filter_state.dart';
import '../../../core/services/auth_service.dart';
import '../../../theme/app_theme.dart';
import 'widgets/quick_filter_chips.dart';
import 'widgets/filter_panel.dart';
import '../../home/presentation/widgets/meetup_card.dart';
import '../../meetups/presentation/nearby_meetups_map_screen.dart';
import '../../notifications/presentation/widgets/notification_bell.dart';
import '../../live_event/presentation/live_feed_page.dart';

enum _FeedMode { discovery, live }

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  late DiscoveryController _controller;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  _FeedMode _feedMode = _FeedMode.discovery;
  bool _headerVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = DiscoveryController();
    _scrollController.addListener(_onScroll);
    _initializeController();
  }

  void _initializeController() {
    final authService = context.read<AuthService>();
    final userId = authService.currentUserId ?? '';
    _controller.initialize(userId);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMore();
    }
  }

  void _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 5 && _headerVisible) {
        setState(() => _headerVisible = false);
      } else if (delta < -5 && !_headerVisible) {
        setState(() => _headerVisible = true);
      }
    }
    if (notification is ScrollEndNotification &&
        notification.metrics.pixels <= 0 &&
        !_headerVisible) {
      setState(() => _headerVisible = true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => FilterPanel(
          initialState: _controller.filterState,
          hasLocationPermission: _controller.hasLocationPermission,
          onApply: (state) {
            _controller.applyFilters(state);
          },
          onClear: () {
            _controller.clearFilters();
          },
          onRequestLocation: () async {
            await _controller.requestLocationPermission();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              // Animated header — hides on scroll down, shows on scroll up
              AnimatedAlign(
                alignment: Alignment.topCenter,
                heightFactor: _headerVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: _headerVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAppBar(),
                      if (_feedMode != _FeedMode.live) ...[
                        _buildSearchBar(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Consumer<DiscoveryController>(
                            builder: (context, controller, _) => QuickFilterChips(
                              filterState: controller.filterState,
                              hasLocationPermission: controller.hasLocationPermission,
                              onTodayTap: () => controller.setDateRange(DateRangeFilter.today),
                              onThisWeekTap: () => controller.setDateRange(DateRangeFilter.thisWeek),
                              onNearMeTap: () => controller.filterNearMe(),
                              onSportTypeTap: (type) => controller.toggleSportType(type),
                              onClearFilters: () => controller.clearFilters(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    _onScrollNotification(notification);
                    return false;
                  },
                  child: _feedMode == _FeedMode.live
                      ? const LiveFeedPage()
                      : Consumer<DiscoveryController>(
                          builder: (context, controller, _) {
                            if (controller.isLoading) {
                              return _buildLoadingState();
                            }

                            if (controller.error != null) {
                              return _buildErrorState(controller.error!);
                            }

                            if (controller.viewMode == ViewMode.map) {
                              return const NearbyMeetupsMapScreen(embedded: true);
                            }

                            return _buildListView(controller);
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _feedMode == _FeedMode.live ? 'Canlı' : 'Keşfet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                _feedMode == _FeedMode.live
                    ? 'Aktif etkinliklerden canlı paylaşımlar'
                    : 'Yakınındaki aktiviteleri bul',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          Row(
            children: [
              // Live mode toggle button
              _buildLiveToggle(),
              const SizedBox(width: 8),
              // View mode toggle
              Consumer<DiscoveryController>(
                builder: (context, controller, _) => Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildViewModeButton(
                        icon: Icons.view_list,
                        isActive: controller.viewMode == ViewMode.list,
                        onTap: () => controller.setViewMode(ViewMode.list),
                        isLeft: true,
                      ),
                      _buildViewModeButton(
                        icon: Icons.map,
                        isActive: controller.viewMode == ViewMode.map,
                        onTap: () => controller.setViewMode(ViewMode.map),
                        isLeft: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Filter button with badge
              Consumer<DiscoveryController>(
                builder: (context, controller, _) => Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.04),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune, size: 20),
                        color: AppTheme.textDark,
                        onPressed: _showFilterPanel,
                      ),
                    ),
                    if (controller.filterState.activeFilterCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${controller.filterState.activeFilterCount}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Notification Bell
              const NotificationBellStyled(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isLeft,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withValues(alpha:0.15) : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(11) : Radius.zero,
            right: isLeft ? Radius.zero : const Radius.circular(11),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? AppTheme.primary : AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _controller.search(value),
        decoration: InputDecoration(
          hintText: 'Etkinlik, konum veya spor ara...',
          hintStyle: const TextStyle(color: AppTheme.textLight),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    _controller.clearSearch();
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveToggle() {
    final isLive = _feedMode == _FeedMode.live;
    return GestureDetector(
      onTap: () {
        setState(() {
          _feedMode = isLive ? _FeedMode.discovery : _FeedMode.live;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isLive ? AppTheme.primary : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLive ? AppTheme.primary : AppTheme.borderLight,
          ),
          boxShadow: isLive
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 18,
              color: isLive ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              'Canlı',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isLive ? Colors.white : AppTheme.textMuted,
              ),
            ),
            const SizedBox(width: 4),
            _LivePulsingDot(isActive: !isLive),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Bir hata oluştu',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _controller.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(DiscoveryController controller) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () => controller.refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Section header for main list
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.filterState.hasActiveFilters ||
                            controller.filterState.searchQuery.isNotEmpty
                        ? 'Sonuçlar'
                        : 'Tüm Etkinlikler',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                  ),
                  Text(
                    '${controller.meetups.length} etkinlik',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Empty state
          if (controller.meetups.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(controller),
            )
          else
            // Meetup list
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= controller.meetups.length) {
                      return null;
                    }

                    final meetupWithDistance = controller.meetups[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildMeetupCard(meetupWithDistance),
                    );
                  },
                  childCount: controller.meetups.length +
                      (controller.isLoadingMore ? 1 : 0),
                ),
              ),
            ),

          // Loading more indicator
          if (controller.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              ),
            ),

          // End of list indicator
          if (!controller.hasMore && controller.meetups.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Tüm etkinlikleri gördün',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeetupCard(MeetupWithDistance meetupWithDistance) {
    return Stack(
      children: [
        MeetupCard(
          meetup: meetupWithDistance.meetup,
          onTap: () {
            context.push('/detail', extra: meetupWithDistance.meetup);
          },
        ),
        // Distance badge
        if (meetupWithDistance.distanceKm != null)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.near_me, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    meetupWithDistance.formattedDistance,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(DiscoveryController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              controller.filterState.hasActiveFilters
                  ? Icons.filter_alt_off
                  : Icons.sports_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              controller.filterState.hasActiveFilters
                  ? 'Sonuç bulunamadı'
                  : 'Henüz etkinlik yok',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.filterState.hasActiveFilters
                  ? 'Filtreleri değiştirmeyi deneyin'
                  : 'İlk etkinliği sen oluştur!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (controller.filterState.hasActiveFilters) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => controller.clearFilters(),
                icon: const Icon(Icons.clear),
                label: const Text('Filtreleri Temizle'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


/// Yanıp sönen yeşil nokta - canlı içerik olduğunu belirtir.
class _LivePulsingDot extends StatefulWidget {
  final bool isActive;
  const _LivePulsingDot({required this.isActive});

  @override
  State<_LivePulsingDot> createState() => _LivePulsingDotState();
}

class _LivePulsingDotState extends State<_LivePulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: _animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withValues(alpha: _animation.value * 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
