import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/eligible_meetup.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/rating_service.dart';
import '../../../theme/app_theme.dart';
import 'widgets/meetup_card.dart';
import 'rate_user_screen.dart';

class SelectMeetupScreen extends StatefulWidget {
  final String currentUserId;
  final String? profileOwnerId; // null means show all pending ratings

  const SelectMeetupScreen({
    super.key,
    required this.currentUserId,
    this.profileOwnerId,
  });

  @override
  State<SelectMeetupScreen> createState() => _SelectMeetupScreenState();
}

class _SelectMeetupScreenState extends State<SelectMeetupScreen> {
  final RatingService _ratingService = RatingService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<EligibleMeetup> _eligibleMeetups = [];
  Map<String, List<UserModel>> _meetupParticipants = {};
  bool _isLoading = true;
  String? _errorMessage;

  bool get _isForSpecificUser => widget.profileOwnerId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isForSpecificUser) {
        await _loadEligibleMeetupsForUser();
      } else {
        await _loadAllPendingMeetups();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Etkinlikler yüklenemedi. Lütfen tekrar deneyin.';
      });
      debugPrint('Error loading meetups: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEligibleMeetupsForUser() async {
    final meetups = await _ratingService.getEligibleMeetups(
      widget.currentUserId,
      widget.profileOwnerId!,
    );
    setState(() {
      _eligibleMeetups = meetups;
    });
  }

  Future<void> _loadAllPendingMeetups() async {
    final now = DateTime.now();

    // Get all past meetups where current user participated
    final meetupsSnapshot = await _firestore
        .collection('meetups')
        .where('participantIds', arrayContains: widget.currentUserId)
        .get();

    final eligibleMeetups = <EligibleMeetup>[];
    final participantsMap = <String, List<UserModel>>{};

    for (final meetupDoc in meetupsSnapshot.docs) {
      final meetupData = meetupDoc.data();
      final participantIds = List<String>.from(
        meetupData['participantIds'] ?? [],
      );

      // Parse meetup date
      DateTime meetupDate;
      final dateValue = meetupData['date'];
      if (dateValue is Timestamp) {
        meetupDate = dateValue.toDate();
      } else if (dateValue is String) {
        meetupDate = DateTime.tryParse(dateValue) ?? DateTime.now();
      } else {
        continue;
      }

      // Check if meetup is in the past
      if (!meetupDate.isBefore(now)) continue;

      // Get participants that haven't been rated yet
      final unratedParticipants = <UserModel>[];
      for (final participantId in participantIds) {
        if (participantId == widget.currentUserId) continue;

        final hasRated = await _ratingService.hasRatedUserInMeetup(
          widget.currentUserId,
          participantId,
          meetupDoc.id,
        );

        if (!hasRated) {
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(participantId)
                .get();
            if (userDoc.exists) {
              unratedParticipants.add(UserModel.fromJson(userDoc.data()!));
            }
          } catch (e) {
            debugPrint('Error fetching user $participantId: $e');
          }
        }
      }

      if (unratedParticipants.isNotEmpty) {
        eligibleMeetups.add(
          EligibleMeetup(
            meetupId: meetupDoc.id,
            title: meetupData['title'] ?? 'İsimsiz Etkinlik',
            date: meetupDate,
            sportType: meetupData['type'] ?? 'other',
            hasRated: false,
          ),
        );
        participantsMap[meetupDoc.id] = unratedParticipants;
      }
    }

    // Sort by date descending
    eligibleMeetups.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _eligibleMeetups = eligibleMeetups;
      _meetupParticipants = participantsMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          _isForSpecificUser ? 'Etkinlik Seç' : 'Değerlendirme Bekleyenler',
        ),
        backgroundColor: AppTheme.backgroundLight,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _errorMessage != null
          ? _buildErrorState()
          : _eligibleMeetups.isEmpty
          ? _buildEmptyState()
          : _isForSpecificUser
          ? _buildMeetupsListForUser()
          : _buildAllPendingMeetups(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.primary.withValues(alpha:0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _isForSpecificUser
                  ? 'Değerlendirilebilecek etkinlik yok'
                  : 'Tüm değerlendirmeler tamamlandı!',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              _isForSpecificUser
                  ? 'Bu kullanıcıyla birlikte geçmiş bir etkinliğe katılmanız gerekiyor'
                  : 'Bekleyen değerlendirmeniz bulunmuyor',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetupsListForUser() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eligibleMeetups.length,
      itemBuilder: (context, index) {
        final meetup = _eligibleMeetups[index];
        return MeetupCard(
          meetup: meetup,
          onRatePressed: () => _navigateToRateUser(meetup),
        );
      },
    );
  }

  Widget _buildAllPendingMeetups() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eligibleMeetups.length,
      itemBuilder: (context, index) {
        final meetup = _eligibleMeetups[index];
        final participants = _meetupParticipants[meetup.meetupId] ?? [];
        return _buildMeetupWithParticipants(meetup, participants);
      },
    );
  }

  Widget _buildMeetupWithParticipants(
    EligibleMeetup meetup,
    List<UserModel> participants,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meetup header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getSportIcon(meetup.sportType),
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meetup.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(meetup.date),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Participants to rate
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Değerlendirilecek Katılımcılar (${participants.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                ...participants.map(
                  (user) => _buildParticipantRow(meetup, user),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantRow(EligibleMeetup meetup, UserModel user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: AppTheme.primary,
        backgroundImage:
            user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
            ? NetworkImage(user.profileImageUrl!)
            : null,
        child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
            ? Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        user.username,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textDark,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: user.averageRating > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  user.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            )
          : null,
      trailing: SizedBox(
        width: 100,
        child: ElevatedButton(
          onPressed: () => _navigateToRateSpecificUser(meetup, user),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Değerlendir', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  void _navigateToRateUser(EligibleMeetup meetup) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => RateUserScreen(
          currentUserId: widget.currentUserId,
          profileOwnerId: widget.profileOwnerId!,
          meetup: meetup,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _navigateToRateSpecificUser(
    EligibleMeetup meetup,
    UserModel user,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => RateUserScreen(
          currentUserId: widget.currentUserId,
          profileOwnerId: user.id,
          meetup: meetup,
        ),
      ),
    );

    if (result == true && mounted) {
      _loadData(); // Refresh the list
    }
  }

  IconData _getSportIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'football':
        return Icons.sports_soccer;
      case 'basketball':
        return Icons.sports_basketball;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'tennis':
        return Icons.sports_tennis;
      case 'tabletennis':
        return Icons.sports_cricket;
      case 'badminton':
        return Icons.sports_tennis;
      case 'swimming':
        return Icons.pool;
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'hiking':
        return Icons.hiking;
      case 'yoga':
        return Icons.self_improvement;
      case 'fitness':
        return Icons.fitness_center;
      case 'boxing':
        return Icons.sports_mma;
      case 'climbing':
        return Icons.terrain;
      case 'skiing':
        return Icons.downhill_skiing;
      default:
        return Icons.sports;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
