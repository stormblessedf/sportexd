import 'package:flutter/material.dart';
import '../../../core/models/rating_model.dart';
import '../../../core/models/rating_distribution.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/rating_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/rating_sorting.dart';
import '../../../theme/app_theme.dart';
import 'widgets/rating_summary_widget.dart';
import 'widgets/rating_filter_bar.dart';
import 'widgets/rating_card.dart';
import 'widgets/write_review_button.dart';
import 'select_meetup_screen.dart';

class UserRatingsPage extends StatefulWidget {
  final String profileOwnerId;

  const UserRatingsPage({
    super.key,
    required this.profileOwnerId,
  });

  @override
  State<UserRatingsPage> createState() => _UserRatingsPageState();
}

class _UserRatingsPageState extends State<UserRatingsPage>
    with SingleTickerProviderStateMixin {
  final RatingService _ratingService = RatingService();
  final AuthService _authService = AuthService();

  // Received ratings (ratings where profileOwner is the ratedUserId)
  List<RatingModel> _receivedRatings = [];
  List<RatingModel> _filteredReceivedRatings = [];

  // Given ratings (ratings where profileOwner is the raterId)
  List<RatingModel> _givenRatings = [];
  List<RatingModel> _filteredGivenRatings = [];

  RatingDistribution _distribution = RatingDistribution.empty();
  RatingFilter _currentFilter = RatingFilter.mostRecent;
  bool _isLoading = true;
  String? _errorMessage;
  bool _canWriteReview = false;

  late TabController _tabController;
  bool _isOwnProfile = false;

  // Cache for rater user models
  final Map<String, UserModel> _userCache = {};

  @override
  void initState() {
    super.initState();
    final currentUserId = _authService.currentUserId;
    _isOwnProfile = currentUserId == widget.profileOwnerId;
    _tabController = TabController(length: _isOwnProfile ? 2 : 1, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final futures = <Future>[
        _loadReceivedRatings(),
        _loadRatingDistribution(),
      ];

      if (!_isOwnProfile) {
        futures.add(_checkEligibility());
      } else {
        futures.add(_loadGivenRatings());
      }

      await Future.wait(futures);
    } catch (e) {
      setState(() {
        _errorMessage = 'Puanlar yüklenemedi. Lütfen tekrar deneyin.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReceivedRatings() async {
    try {
      final ratings = await _ratingService.getRatingsForUser(widget.profileOwnerId);
      setState(() {
        _receivedRatings = ratings;
        _applyFilterToReceived(_currentFilter);
      });
    } catch (e) {
      debugPrint('Error loading received ratings: $e');
      rethrow;
    }
  }

  Future<void> _loadGivenRatings() async {
    try {
      final ratings = await _ratingService.getRatingsGivenByUser(widget.profileOwnerId);
      setState(() {
        _givenRatings = ratings;
        _applyFilterToGiven(_currentFilter);
      });
    } catch (e) {
      debugPrint('Error loading given ratings: $e');
      // Don't rethrow - this is optional data
    }
  }

  Future<void> _loadRatingDistribution() async {
    try {
      final distribution = await _ratingService.getRatingDistribution(widget.profileOwnerId);
      setState(() {
        _distribution = distribution;
      });
    } catch (e) {
      debugPrint('Error loading rating distribution: $e');
      rethrow;
    }
  }

  Future<void> _checkEligibility() async {
    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        setState(() {
          _canWriteReview = false;
        });
        return;
      }

      if (currentUserId == widget.profileOwnerId) {
        setState(() {
          _canWriteReview = false;
        });
        return;
      }

      final eligibleMeetups = await _ratingService.getEligibleMeetups(
        currentUserId,
        widget.profileOwnerId,
      );

      setState(() {
        _canWriteReview = eligibleMeetups.isNotEmpty;
      });
    } catch (e) {
      debugPrint('Error checking eligibility: $e');
      setState(() {
        _canWriteReview = false;
      });
    }
  }

  void _applyFilter(RatingFilter filter) {
    setState(() {
      _currentFilter = filter;
      _applyFilterToReceived(filter);
      _applyFilterToGiven(filter);
    });
  }

  void _applyFilterToReceived(RatingFilter filter) {
    switch (filter) {
      case RatingFilter.mostRecent:
        _filteredReceivedRatings = RatingSorting.sortByMostRecent(_receivedRatings);
        break;
      case RatingFilter.highest:
        _filteredReceivedRatings = RatingSorting.sortByHighest(_receivedRatings);
        break;
      case RatingFilter.lowest:
        _filteredReceivedRatings = RatingSorting.sortByLowest(_receivedRatings);
        break;
    }
  }

  void _applyFilterToGiven(RatingFilter filter) {
    switch (filter) {
      case RatingFilter.mostRecent:
        _filteredGivenRatings = RatingSorting.sortByMostRecent(_givenRatings);
        break;
      case RatingFilter.highest:
        _filteredGivenRatings = RatingSorting.sortByHighest(_givenRatings);
        break;
      case RatingFilter.lowest:
        _filteredGivenRatings = RatingSorting.sortByLowest(_givenRatings);
        break;
    }
  }

  Future<UserModel?> _getUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final userDoc = await _authService.firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final user = UserModel.fromJson(userDoc.data()!);
        _userCache[userId] = user;
        return user;
      }

      final user = UserModel(
        id: userId,
        username: 'Kullanıcı',
        email: '',
        averageRating: 0,
        totalRatings: 0,
      );
      _userCache[userId] = user;
      return user;
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isOwnProfile ? 'Puanlarım' : 'Değerlendirmeler'),
        elevation: 0,
        bottom: _isOwnProfile
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Aldığım Puanlar'),
                  Tab(text: 'Verdiğim Puanlar'),
                ],
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.primary,
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _isOwnProfile
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _buildReceivedRatingsTab(),
                        _buildGivenRatingsTab(),
                      ],
                    )
                  : _buildReceivedRatingsTab(),
      floatingActionButton: _isOwnProfile
          ? null  // Rating is done from profile screen or past meetups
          : WriteReviewButton(
              isEnabled: _canWriteReview,
              onPressed: () => _navigateToSelectMeetup(),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
            _errorMessage ?? 'Bir hata oluştu',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedRatingsTab() {
    if (_receivedRatings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.star_border,
        title: 'Henüz puan almadınız',
        subtitle: 'Etkinliklere katılarak puan almaya başlayın!',
      );
    }

    final averageRating = _distribution.totalCount > 0
        ? _receivedRatings.map((r) => r.rating).reduce((a, b) => a + b) /
            _receivedRatings.length
        : 0.0;

    return Column(
      children: [
        RatingSummaryWidget(
          averageRating: averageRating,
          totalRatings: _distribution.totalCount,
          distribution: _distribution,
        ),
        RatingFilterBar(
          currentFilter: _currentFilter,
          onFilterSelected: _applyFilter,
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredReceivedRatings.length,
            itemBuilder: (context, index) {
              final rating = _filteredReceivedRatings[index];
              return _buildRatingCard(rating, isGiven: false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGivenRatingsTab() {
    if (_givenRatings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.rate_review_outlined,
        title: 'Henüz puan vermediniz',
        subtitle: 'Katıldığınız etkinliklerde diğer katılımcıları puanlayabilirsiniz.',
      );
    }

    return Column(
      children: [
        // Summary for given ratings
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rate_review, color: AppTheme.primary, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_givenRatings.length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Text(
                    'Verilen Değerlendirme',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        RatingFilterBar(
          currentFilter: _currentFilter,
          onFilterSelected: _applyFilter,
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredGivenRatings.length,
            itemBuilder: (context, index) {
              final rating = _filteredGivenRatings[index];
              return _buildRatingCard(rating, isGiven: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingCard(RatingModel rating, {required bool isGiven}) {
    // For given ratings, show the rated user; for received, show the rater
    final userIdToShow = isGiven ? rating.ratedUserId : rating.raterId;

    // First try to use stored data
    if (!isGiven && rating.raterName != null) {
      final tempUser = UserModel(
        id: rating.raterId,
        username: rating.raterName!,
        email: '',
        averageRating: 0,
        totalRatings: 0,
        profileImageUrl: rating.raterPhotoUrl,
      );
      return RatingCard(
        rating: rating,
        rater: tempUser,
        showAsGiven: isGiven,
      );
    }

    return FutureBuilder<UserModel?>(
      future: _getUser(userIdToShow),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text('Yükleniyor...'),
              ),
            ),
          );
        }
        return RatingCard(
          rating: rating,
          rater: snapshot.data!,
          showAsGiven: isGiven,
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSelectMeetup() async {
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SelectMeetupScreen(
          currentUserId: currentUserId,
          profileOwnerId: widget.profileOwnerId,
        ),
      ),
    );

    // Refresh if a rating was submitted
    if (result == true && mounted) {
      _loadData();
    }
  }

}
