import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/meetup_model.dart';
import '../../../../core/services/meetup_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../features/live_event/presentation/live_feed_page.dart';
import 'widgets/meetup_card.dart';

enum FeedMode { explore, following, live }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Theme colors from HTML
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF13EC5B);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  FeedMode _feedMode = FeedMode.explore;
  List<String> _partnerIds = [];
  bool _isLoadingPartners = true;

  @override
  void initState() {
    super.initState();
    _loadPartnersList();
  }

  Future<void> _loadPartnersList() async {
    final userId = AuthService().currentUserId;
    if (userId == null) {
      setState(() {
        _isLoadingPartners = false;
      });
      return;
    }

    try {
      final user = await AuthService().getCurrentUser();
      setState(() {
        _partnerIds = user?.partners ?? [];
        _isLoadingPartners = false;
      });
    } catch (e) {
      debugPrint('Error loading partners list: $e');
      setState(() {
        _isLoadingPartners = false;
      });
    }
  }

  List<MeetupModel> _filterMeetups(List<MeetupModel> meetups) {
    if (_feedMode == FeedMode.explore) {
      return meetups;
    }

    // Following mode: only show meetups from partners
    return meetups.where((meetup) {
      return _partnerIds.contains(meetup.organizerId);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final meetupService = MeetupService();

    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _feedMode == FeedMode.explore
                                ? 'Keşfet'
                                : _feedMode == FeedMode.following
                                    ? 'Takip Edilenler'
                                    : 'Canlı',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _feedMode == FeedMode.explore
                                ? 'Yakınındaki aktiviteleri keşfet'
                                : _feedMode == FeedMode.following
                                    ? 'Takip ettiğin kişilerin aktiviteleri'
                                    : 'Aktif etkinliklerden canlı paylaşımlar',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Explore button
                          Container(
                            decoration: BoxDecoration(
                              color: _feedMode == FeedMode.explore
                                  ? primary
                                  : surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _feedMode == FeedMode.explore
                                    ? primary
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                if (_feedMode == FeedMode.explore)
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.explore,
                                size: 20,
                                color: _feedMode == FeedMode.explore
                                    ? Colors.white
                                    : textMuted,
                              ),
                              onPressed: () {
                                setState(() {
                                  _feedMode = FeedMode.explore;
                                });
                              },
                              tooltip: 'Keşfet',
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Following button
                          Container(
                            decoration: BoxDecoration(
                              color: _feedMode == FeedMode.following
                                  ? primary
                                  : surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _feedMode == FeedMode.following
                                    ? primary
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                if (_feedMode == FeedMode.following)
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.people,
                                size: 20,
                                color: _feedMode == FeedMode.following
                                    ? Colors.white
                                    : textMuted,
                              ),
                              onPressed: () {
                                setState(() {
                                  _feedMode = FeedMode.following;
                                });
                              },
                              tooltip: 'Takip Edilenler',
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Live button
                          Container(
                            decoration: BoxDecoration(
                              color: _feedMode == FeedMode.live
                                  ? primary
                                  : surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _feedMode == FeedMode.live
                                    ? primary
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                if (_feedMode == FeedMode.live)
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: IconButton(
                              icon: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    Icons.videocam,
                                    size: 20,
                                    color: _feedMode == FeedMode.live
                                        ? Colors.white
                                        : textMuted,
                                  ),
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: _PulsingDot(
                                      isActive: _feedMode != FeedMode.live,
                                    ),
                                  ),
                                ],
                              ),
                              onPressed: () {
                                setState(() {
                                  _feedMode = FeedMode.live;
                                });
                              },
                              tooltip: 'Canlı',
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Filter button
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.tune, size: 20),
                              color: textDark,
                              onPressed: () {
                                // TODO: Filter functionality
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: _feedMode == FeedMode.live
                  ? const LiveFeedPage()
                  : _isLoadingPartners
                  ? const Center(
                      child: CircularProgressIndicator(color: primary),
                    )
                  : StreamBuilder<List<MeetupModel>>(
                      stream: meetupService.getUpcomingMeetups(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: primary),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Bir hata oluştu: ${snapshot.error}',
                              style: const TextStyle(color: textMuted),
                            ),
                          );
                        }

                        final allMeetups = snapshot.data ?? [];
                        final filteredMeetups = _filterMeetups(allMeetups);

                        if (filteredMeetups.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _feedMode == FeedMode.following
                                      ? Icons.people_outline
                                      : Icons.sports_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _feedMode == FeedMode.following
                                      ? 'Takip ettiğin kişiler henüz etkinlik oluşturmamış'
                                      : 'Henüz etkinlik yok',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _feedMode == FeedMode.following
                                      ? 'Keşfet sekmesine göz atabilirsin'
                                      : 'İlk etkinliği sen oluştur!',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          color: primary,
                          backgroundColor: surfaceLight,
                          onRefresh: () async {
                            await _loadPartnersList();
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: filteredMeetups.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return MeetupCard(
                                meetup: filteredMeetups[index],
                                onTap: () {
                                  context.push(
                                    '/detail',
                                    extra: filteredMeetups[index],
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yanıp sönen yeşil nokta göstergesi - canlı içerik olduğunu belirtir.
class _PulsingDot extends StatefulWidget {
  final bool isActive;

  const _PulsingDot({required this.isActive});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
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
                color:
                    const Color(0xFF22C55E).withValues(alpha: _animation.value * 0.5),
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