import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/meetup_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/meetup_service.dart';
import '../../../core/services/auth_service.dart';
import '../../chat/presentation/chat_screen.dart';
import 'widgets/meetup_map_widget.dart';

class MeetupDetailScreen extends StatefulWidget {
  final MeetupModel meetup;

  const MeetupDetailScreen({super.key, required this.meetup});

  @override
  State<MeetupDetailScreen> createState() => _MeetupDetailScreenState();
}

class _MeetupDetailScreenState extends State<MeetupDetailScreen> {
  final MeetupService _meetupService = MeetupService();
  final AuthService _authService = AuthService();

  bool _isParticipating = false;
  bool _isLoading = true;
  bool _isOnWaitlist = false;
  String? _currentUserId;
  late MeetupModel _currentMeetup;
  List<UserModel> _participants = [];

  @override
  void initState() {
    super.initState();
    _currentMeetup = widget.meetup;
    _checkParticipation();
    _checkWaitlistStatus();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      final participants = <UserModel>[];
      for (final participantId in _currentMeetup.participantIds) {
        final doc = await _authService.firestore
            .collection('users')
            .doc(participantId)
            .get();
        if (doc.exists) {
          participants.add(UserModel.fromJson(doc.data()!));
        }
      }
      if (mounted) {
        setState(() {
          _participants = participants;
        });
      }
    } catch (e) {
      debugPrint('Error loading participants: $e');
    }
  }

  Future<void> _checkParticipation() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Organizer is always a participant
    if (_currentMeetup.organizerId == userId) {
      setState(() {
        _isParticipating = true;
        _currentUserId = userId;
        _isLoading = false;
      });
      return;
    }

    final isParticipant = await _meetupService.isParticipant(
      _currentMeetup.id,
      userId,
    );
    if (mounted) {
      setState(() {
        _isParticipating = isParticipant;
        _currentUserId = userId;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkWaitlistStatus() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    final isOnWaitlist = await _meetupService.isOnWaitlist(
      _currentMeetup.id,
      userId,
    );
    if (mounted) {
      setState(() {
        _isOnWaitlist = isOnWaitlist;
      });
    }
  }

  Future<void> _joinMeetup() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Katılmak için giriş yapmalısınız.')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      await _meetupService.joinMeetup(_currentMeetup.id, _currentUserId!);

      // Refresh meetup data to get updated participant count
      final updatedMeetup = await _meetupService.getMeetupById(
        _currentMeetup.id,
      );

      if (mounted) {
        setState(() {
          if (updatedMeetup != null) {
            _currentMeetup = updatedMeetup;
          }
          _isParticipating = true;
          _isLoading = false;
        });
        // Reload participants to include the new user
        _loadParticipants();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buluşmaya başarıyla katıldınız!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _joinWaitlist() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hatırlatma için giriş yapmalısınız.')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      await _meetupService.joinWaitlist(_currentMeetup.id, _currentUserId!);

      if (mounted) {
        setState(() {
          _isOnWaitlist = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kontenjan açıldığında bildirim alacaksınız!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _leaveWaitlist() async {
    if (_currentUserId == null) return;

    try {
      setState(() => _isLoading = true);
      await _meetupService.leaveWaitlist(_currentMeetup.id, _currentUserId!);

      if (mounted) {
        setState(() {
          _isOnWaitlist = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bekleme listesinden çıkarıldınız')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _leaveMeetup() async {
    if (_currentUserId == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etkinlikten Ayrıl'),
        content: const Text(
          'Bu etkinlikten ayrılmak istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ayrıl'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);
      await _meetupService.leaveMeetup(_currentMeetup.id, _currentUserId!);

      // Refresh meetup data
      final updatedMeetup = await _meetupService.getMeetupById(
        _currentMeetup.id,
      );

      if (mounted) {
        setState(() {
          if (updatedMeetup != null) {
            _currentMeetup = updatedMeetup;
          }
          _isParticipating = false;
          _isLoading = false;
        });
        _loadParticipants();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Etkinlikten ayrıldınız')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  Future<double> _getOrganizerRating(String organizerId) async {
    try {
      final doc = await _authService.firestore
          .collection('users')
          .doc(organizerId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return (data?['averageRating'] ?? 0.0).toDouble();
      }
    } catch (e) {
      debugPrint('Error getting organizer rating: $e');
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final bool isFull =
        _currentMeetup.currentParticipants >= _currentMeetup.maxParticipants;
    final bool isPast = _meetupService.isMeetupPast(_currentMeetup);

    // Debug logging
    debugPrint(
      'DEBUG: isFull=$isFull, isPast=$isPast, isParticipating=$_isParticipating, isOnWaitlist=$_isOnWaitlist, isLoading=$_isLoading',
    );
    debugPrint(
      'DEBUG: current=${_currentMeetup.currentParticipants}, max=${_currentMeetup.maxParticipants}',
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Elegant Header with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'meetup_img_${_currentMeetup.id}',
                child: Image.network(
                  _currentMeetup.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {},
              ),
            ],
          ),

          // Content Area
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _currentMeetup.type.name.toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentMeetup.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Cards
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    title: 'Tarih & Saat',
                    subtitle:
                        '${_currentMeetup.date.day} ${_getMonth(_currentMeetup.date.month)} • ${_formatTime(_currentMeetup.date, endDate: _currentMeetup.endDate)}',
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.location_on_outlined,
                    title: 'Buluşma Yeri',
                    subtitle: _currentMeetup.locationName,
                    description: _currentMeetup.locationAddress,
                  ),
                  const SizedBox(height: 16),

                  // Map Widget
                  MeetupMapWidget(
                    latitude: _currentMeetup.latitude,
                    longitude: _currentMeetup.longitude,
                    locationName: _currentMeetup.locationName,
                    locationAddress: _currentMeetup.locationAddress,
                  ),
                  const SizedBox(height: 24),

                  // Organizer Info
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.push(
                            '/user-profile/${_currentMeetup.organizerId}',
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              backgroundImage:
                                  _currentMeetup.organizerImageUrl != null
                                  ? NetworkImage(
                                      _currentMeetup.organizerImageUrl!,
                                    )
                                  : null,
                              child: _currentMeetup.organizerImageUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Organizatör',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                FutureBuilder<double>(
                                  future: _getOrganizerRating(
                                    _currentMeetup.organizerId,
                                  ),
                                  builder: (context, snapshot) {
                                    final rating = snapshot.data ?? 0.0;
                                    return Row(
                                      children: [
                                        Text(
                                          _currentMeetup.organizerName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                        ),
                                        if (rating > 0) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.amber.withValues(
                                                alpha: 0.9,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () {
                          context.push(
                            '/user-profile/${_currentMeetup.organizerId}',
                          );
                        },
                        child: const Text('Profil'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // About Section
                  Text(
                    'Açıklama',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentMeetup.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Participants Preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Katılımcılar (${_currentMeetup.currentParticipants}/${_currentMeetup.maxParticipants})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () => _showAllParticipants(),
                        child: const Text('Tümünü Gör'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildParticipantAvatars(),
                  const SizedBox(height: 100), // Extra space for action button
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Action Bar
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator()),
              )
            : isPast
            ? _isParticipating
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatId: _currentMeetup.id,
                                  title: _currentMeetup.title,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_rounded),
                          label: const Text('Grup Sohbetine Git'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            context.push(
                              '/rate-participants',
                              extra: {
                                'meetupId': _currentMeetup.id,
                                'meetupTitle': _currentMeetup.title,
                                'participantIds': _currentMeetup.participantIds,
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.star_rate,
                            color: Color(0xFFFF9800),
                          ),
                          label: const Text(
                            'Katılımcıları Değerlendir',
                            style: TextStyle(color: Color(0xFFFF9800)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFF9800)),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'Bu etkinlik tamamlandı',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
            : _isParticipating
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: _currentMeetup.id,
                            title: _currentMeetup.title,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_rounded),
                    label: const Text('Grup Sohbetine Git'),
                  ),
                  // Show leave button only for non-organizers
                  if (_currentUserId != _currentMeetup.organizerId) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _leaveMeetup,
                      icon: const Icon(Icons.exit_to_app, color: Colors.red),
                      label: const Text(
                        'Etkinlikten Ayrıl',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              )
            : isFull
            ? (_isOnWaitlist
                  ? OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Bekleme Listesinden Çık'),
                            content: const Text(
                              'Kontenjan açıldığında bildirim almak istemediğinizden emin misiniz?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('İptal'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _leaveWaitlist();
                                },
                                child: const Text('Çık'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Bekleme Listesinde'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _joinWaitlist,
                      icon: const Icon(Icons.notifications_outlined),
                      label: const Text('Beni Hatırlat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ))
            : ElevatedButton(
                onPressed: _joinMeetup,
                child: const Text('Hemen Katıl'),
              ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String subtitle,
    String? description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (description != null)
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantAvatars() {
    if (_participants.isEmpty) {
      return Row(
        children: List.generate(
          _currentMeetup.currentParticipants.clamp(0, 5),
          (index) => Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 20, color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    final displayCount = _participants.length.clamp(0, 5);
    final extraCount = _participants.length - displayCount;

    return Row(
      children: [
        ...List.generate(displayCount, (index) {
          final participant = _participants[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => _showParticipantCard(participant),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primary,
                backgroundImage: participant.profileImageUrl != null
                    ? NetworkImage(participant.profileImageUrl!)
                    : null,
                child: participant.profileImageUrl == null
                    ? Text(
                        participant.username[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
            ),
          );
        }),
        if (extraCount > 0)
          GestureDetector(
            onTap: () => _showAllParticipants(),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: Text(
                '+$extraCount',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showParticipantCard(UserModel participant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primary,
                backgroundImage: participant.profileImageUrl != null
                    ? NetworkImage(participant.profileImageUrl!)
                    : null,
                child: participant.profileImageUrl == null
                    ? Text(
                        participant.username[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    participant.username,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (participant.averageRating > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            participant.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (participant.bio != null && participant.bio!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  participant.bio!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              if (participant.totalRatings > 0)
                Text(
                  '${participant.totalRatings} değerlendirme',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Kapat'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/user-profile/${participant.id}');
                      },
                      child: const Text('Profili Gör'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllParticipants() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Katılımcılar (${_participants.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _participants.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _participants.length,
                      itemBuilder: (context, index) {
                        final participant = _participants[index];
                        final isOrganizer =
                            participant.id == _currentMeetup.organizerId;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            backgroundImage: participant.profileImageUrl != null
                                ? NetworkImage(participant.profileImageUrl!)
                                : null,
                            child: participant.profileImageUrl == null
                                ? Text(
                                    participant.username[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Text(
                                participant.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isOrganizer) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Organizatör',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: participant.averageRating > 0
                              ? Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${participant.averageRating.toStringAsFixed(1)} (${participant.totalRatings})',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              Navigator.pop(context);
                              context.push('/user-profile/${participant.id}');
                            },
                          ),
                          onTap: () => _showParticipantCard(participant),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime date, {DateTime? endDate}) {
    final startTime = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (endDate != null) {
      final endTime = '${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}';
      return '$startTime - $endTime';
    }
    return startTime;
  }
}
