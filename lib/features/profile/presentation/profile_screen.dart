import 'package:flutter/material.dart' hide Badge;
import 'package:go_router/go_router.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/meetup_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/share_service.dart';
import '../../../core/services/badge_award_service.dart';
import '../../../core/services/proximity_attendance_service.dart';
import '../../../features/profile/presentation/models/trophy_definition.dart';
import '../../../theme/app_theme.dart';
import 'widgets/profile_header_row.dart';
import 'widgets/name_section.dart';
import 'widgets/action_buttons_row.dart';
import 'widgets/mutual_partners_bar.dart';
import 'widgets/highlights_row.dart';
import 'widgets/photo_grid_tab.dart';
import 'widgets/calendar_tab.dart';
import 'widgets/trophies_tab.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? user;
  final String? userId;

  const ProfileScreen({super.key, this.user, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final BadgeAwardService _badgeAwardService = BadgeAwardService();

  late TabController _tabController;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  List<MeetupModel> _allMeetups = [];
  bool _isMeetupsLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    if (widget.user != null) {
      _user = widget.user;
      _loadMeetupData(_user!.id);
    } else if (widget.userId != null) {
      _loadUserById(widget.userId!);
    } else {
      _loadCurrentUser();
    }
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }

      final currentUserId = _authService.currentUserId;
      if (currentUserId != null) {
        // Process cutoffs for expired meetups
        try {
          await ProximityAttendanceService()
              .processCutoffForActiveMeetups(currentUserId);
        } catch (e) {
          debugPrint('Error processing cutoffs: $e');
        }

        // Refresh profile fields from Firestore
        try {
          final refreshedUser = await _authService.getCurrentUser();
          if (mounted && refreshedUser != null) {
            setState(() => _user = refreshedUser);
          }
        } catch (e) {
          debugPrint('Error refreshing reliability data: $e');
        }

        // Fire-and-forget badge evaluation
        _badgeAwardService.evaluateAndAwardBadges(currentUserId).catchError((e) {
          debugPrint('Badge evaluation failed: $e');
          return <Badge>[];
        });

        _loadMeetupData(currentUserId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Profil yüklenemedi: $e';
        });
      }
    }
  }

  Future<void> _loadUserById(String userId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final doc =
          await _authService.firestore.collection('users').doc(userId).get();
      if (doc.exists && mounted) {
        setState(() {
          _user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
          _isLoading = false;
        });
        _loadMeetupData(userId);
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Kullanıcı bulunamadı';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Profil yüklenemedi: $e';
        });
      }
    }
  }

  Future<void> _loadMeetupData(String userId) async {
    setState(() => _isMeetupsLoading = true);
    await _loadAllUserMeetups(userId);
    if (mounted) {
      setState(() => _isMeetupsLoading = false);
    }
  }

  Future<void> _loadAllUserMeetups(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('meetups')
          .where('participantIds', arrayContains: userId)
          .get();
      if (mounted) {
        setState(() {
          _allMeetups =
              snapshot.docs.map((d) => MeetupModel.fromJson(d.data())).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading all meetups: $e');
    }
  }

  Future<void> _refreshAll() async {
    final userId = _user?.id;
    if (userId == null) return;

    if (widget.userId != null) {
      await _loadUserById(widget.userId!);
    } else {
      await _loadCurrentUser();
    }
  }

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await pickedFile.readAsBytes();
      final userId = _authService.currentUserId;

      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final ref =
          FirebaseStorage.instance.ref('profile_images/$userId/$userId.jpg');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedBy': userId},
      );
      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _authService.updateUser(
        userId: userId,
        profileImageUrl: downloadUrl,
      );

      await _loadCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil resmi güncellendi!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    // Error state
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    // Unauthenticated state
    if (_user == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Kullanıcı bilgisi bulunamadı.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Giriş Yap'),
              ),
            ],
          ),
        ),
      );
    }

    final user = _user!;
    final isOwnProfile = _authService.currentUserId == user.id;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: _buildAppBar(user, isOwnProfile),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Profile header row (avatar + counters)
                      GestureDetector(
                        onTap: isOwnProfile ? _changeProfilePicture : null,
                        child: ProfileHeaderRow(
                          user: user,
                          onCounterTap: (type) => _onCounterTap(type, user),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Name section (name, bio, location, sport tags)
                      NameSection(user: user),
                      const SizedBox(height: 12),
                      // Action buttons (own) or mutual partners (other)
                      if (isOwnProfile)
                        ActionButtonsRow(
                          onEditTap: () => context.push('/edit-profile'),
                          onShareTap: () => ShareService.shareProfile(user.id),
                        )
                      else if (_authService.currentUserId != null)
                        MutualPartnersBar(
                          currentUserId: _authService.currentUserId!,
                          profileUserId: user.id,
                        ),
                      const SizedBox(height: 12),
                      // Highlights row
                      HighlightsRow(
                        isOwnProfile: isOwnProfile,
                        onTap: (type) => _onHighlightTap(type),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  tabBar: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primary,
                    indicatorWeight: 2,
                    labelColor: AppTheme.textDark,
                    unselectedLabelColor: AppTheme.textLight,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on)),
                      Tab(icon: Icon(Icons.calendar_month)),
                      Tab(icon: Icon(Icons.emoji_events)),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // Photo Grid Tab
              _buildPhotoGridTab(user),
              // Calendar Tab
              _buildCalendarTab(user),
              // Trophies Tab
              _buildTrophiesTab(user),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(UserModel user, bool isOwnProfile) {
    return AppBar(
      title: Text(
        '@${user.username}',
        style: GoogleFonts.lexend(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
      ),
      backgroundColor: AppTheme.backgroundLight,
      foregroundColor: AppTheme.textDark,
      elevation: 0,
      automaticallyImplyLeading: !isOwnProfile,
      actions: [
        if (isOwnProfile) ...[
          IconButton(
            icon: const Icon(Icons.history, color: AppTheme.textMuted),
            tooltip: 'Geçmiş Etkinliklerim',
            onPressed: () => context.push('/past-meetups', extra: user.id),
          ),
          IconButton(
            icon: const Icon(Icons.handshake, color: AppTheme.primary),
            tooltip: 'Partner İstekleri',
            onPressed: () => context.push('/partnership-requests'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') {
                context.push('/edit-profile');
              } else if (value == 'settings') {
                context.push('/settings');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Profili Düzenle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Ayarlar'),
                  ],
                ),
              ),
            ],
          ),
        ] else
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [],
          ),
      ],
    );
  }

  Widget _buildPhotoGridTab(UserModel user) {
    final isOwnProfile = _authService.currentUserId == user.id;
    return PhotoGridTab(
      userId: user.id,
      isOwnProfile: isOwnProfile,
    );
  }

  Widget _buildCalendarTab(UserModel user) {
    if (_isMeetupsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: CalendarTab(
        meetups: _allMeetups,
        onMeetupTap: (meetup) => context.push('/meetup/${meetup.id}'),
      ),
    );
  }

  Widget _buildTrophiesTab(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: TrophiesTab(
        earnedBadges: user.badges,
        allTrophies: allTrophyDefinitions,
        onTrophyTap: (trophy) => _showTrophyDetail(context, trophy, user),
      ),
    );
  }

  void _onCounterTap(CounterType type, UserModel user) {
    switch (type) {
      case CounterType.events:
        context.push('/user-meetups/${user.id}');
      case CounterType.partners:
        context.push('/partners/${user.id}');
      case CounterType.reliability:
        context.push('/reliability-detail', extra: {
          'userId': user.id,
          'reliabilityScore': user.reliabilityScore,
        });
      case CounterType.rating:
        context.push('/user-ratings/${user.id}');
    }
  }

  void _onHighlightTap(HighlightType type) {
    switch (type) {
      case HighlightType.badges:
        _tabController.animateTo(2);
      case HighlightType.certificates:
        break; // No certificates section in new design
      case HighlightType.statistics:
        final userId = _user?.id;
        if (userId != null) {
          context.push('/user-statistics/$userId');
        }
      case HighlightType.achievements:
        _tabController.animateTo(2);
      case HighlightType.upcoming:
        _tabController.animateTo(1);
    }
  }

  void _showTrophyDetail(
    BuildContext context,
    TrophyDefinition trophy,
    UserModel user,
  ) {
    final earnedBadge = user.badges.where((b) => b.id == trophy.id).firstOrNull;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(trophy.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              trophy.name,
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              trophy.description,
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (earnedBadge != null) ...[
              const SizedBox(height: 12),
              Text(
                'Kazanıldı ✅',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

}

/// Delegate for pinning the TabBar in NestedScrollView.
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _TabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppTheme.backgroundLight,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
