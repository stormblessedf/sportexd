import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/meetup_model.dart';
import '../../../../core/services/meetup_service.dart';
import '../../../../core/services/auth_service.dart';
import 'widgets/meetup_card.dart';

enum FeedMode { explore, following }

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
                                : 'Takip Edilenler',
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
                                : 'Takip ettiğin kişilerin aktiviteleri',
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
              child: _isLoadingPartners
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
