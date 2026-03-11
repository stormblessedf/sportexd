import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/models/formation_config.dart';
import '../../../core/models/meetup_model.dart';
import '../../../core/models/position_slot.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/meetup_service.dart';
import '../../../core/services/auth_service.dart';
import '../../chat/presentation/chat_screen.dart';
import 'widgets/meetup_map_widget.dart';
import 'widgets/join_celebration_overlay.dart';
import 'widgets/route_map_display_widget.dart';

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
  int _selectedFootballTab = 0;
  String? _currentUserId;
  String? _selectedTeam;
  int? _selectedSlotIndex;
  late MeetupModel _currentMeetup;
  List<UserModel> _participants = [];

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  bool get _isOrganizer =>
      _currentUserId != null &&
      _currentUserId == _currentMeetup.organizerId;

  @override
  void initState() {
    super.initState();
    _currentMeetup = widget.meetup;
    _checkParticipation();
    _checkWaitlistStatus();
    _loadParticipants();
  }

  Future<void> _autoFillTeams() async {
    // TODO: Implement auto-fill logic - assign waiting participants to random empty slots
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.autoFillSoon)),
    );
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
        SnackBar(content: Text(l10n.loginToJoin)),
      );
      return;
    }

    // For football meetups with teams, use the selected slot from Takım tab
    if (_currentMeetup.isFootballWithTeams) {
      if (_selectedTeam == null || _selectedSlotIndex == null) {
        // Switch to Takım tab and show warning
        setState(() => _selectedFootballTab = 1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.selectPositionFirst),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.userInfoFailed)),
          );
        }
        return;
      }

      try {
        setState(() => _isLoading = true);
        await _meetupService.joinMeetupWithPosition(
          meetupId: _currentMeetup.id,
          userId: _currentUserId!,
          userName: currentUser.username,
          team: _selectedTeam!,
          slotIndex: _selectedSlotIndex!,
          userImageUrl: currentUser.profileImageUrl,
        );

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
            _selectedTeam = null;
            _selectedSlotIndex = null;
          });
          _loadParticipants();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.joinedSuccessfully),
            ),
          );
          JoinCelebrationOverlay.show(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
            ),
          );
        }
      }
      return;
    }

    // Standard join for non-football meetups
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
          SnackBar(content: Text(l10n.joinedSuccessfully)),
        );
        JoinCelebrationOverlay.show(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorWithMessage(e.toString()))));
      }
    }
  }

  Future<void> _joinWaitlist() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reminderLoginRequired)),
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
          SnackBar(
            content: Text(l10n.spotNotification),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorWithMessage(e.toString()))));
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
          SnackBar(content: Text(l10n.removedFromWaitlist)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorWithMessage(e.toString()))));
      }
    }
  }

  Future<void> _leaveMeetup() async {
    if (_currentUserId == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveEvent),
        content: Text(
          l10n.leaveEventConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.leaveButton),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.leftEvent)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hata: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
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

                  if (_currentMeetup.type == MeetupType.football) ...[
                    _buildFootballTabSelector(),
                    const SizedBox(height: 24),
                  ],

                  if (_currentMeetup.type != MeetupType.football ||
                      _selectedFootballTab == 0) ...[
                    // Info Cards
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      title: l10n.dateAndTime,
                      subtitle:
                          '${_currentMeetup.date.day} ${_getMonth(_currentMeetup.date.month)} • ${_formatTime(_currentMeetup.date, endDate: _currentMeetup.endDate)}',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.location_on_outlined,
                      title: l10n.meetupLocation,
                      subtitle: _currentMeetup.locationName,
                      description: _currentMeetup.locationAddress,
                    ),
                    const SizedBox(height: 16),

                    // Map Widget - show route map if route data exists, otherwise regular map
                    if (_currentMeetup.hasRoute)
                      RouteMapDisplayWidget(routeData: _currentMeetup.routeData!)
                    else
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
                                    l10n.organizer,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
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
                          child: Text(l10n.profile),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // About Section
                    Text(
                      l10n.description,
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
                          '${l10n.participants} (${_currentMeetup.currentParticipants}/${_currentMeetup.maxParticipants})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => _showAllParticipants(),
                          child: Text(l10n.seeAll),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildParticipantAvatars(),
                  ],
                  if (_currentMeetup.type == MeetupType.football &&
                      _selectedFootballTab == 1) ...[
                    _buildFootballTeamTab(),
                  ],
                  if (_currentMeetup.type == MeetupType.football &&
                      _selectedFootballTab == 2) ...[
                    _buildFootballRulesTab(),
                  ],
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
                          label: Text(l10n.goToGroupChat),
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
                          label: Text(
                            l10n.rateParticipants,
                            style: const TextStyle(color: Color(0xFFFF9800)),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            l10n.eventCompleted,
                            style: const TextStyle(color: Colors.grey),
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
                    label: Text(l10n.goToGroupChat),
                  ),
                  // Show leave button only for non-organizers
                  if (_currentUserId != _currentMeetup.organizerId) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _leaveMeetup,
                      icon: const Icon(Icons.exit_to_app, color: Colors.red),
                      label: Text(
                        l10n.leaveEvent,
                        style: const TextStyle(color: Colors.red),
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
                            title: Text(l10n.leaveWaitlist),
                            content: Text(
                              l10n.leaveWaitlistConfirm,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _leaveWaitlist();
                                },
                                child: Text(l10n.leave),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_active),
                      label: Text(l10n.onWaitlist),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _joinWaitlist,
                      icon: const Icon(Icons.notifications_outlined),
                      label: Text(l10n.remindMe),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ))
            : ElevatedButton(
                onPressed: _joinMeetup,
                child: Text(l10n.joinNow),
              ),
      ),
    );
  }

  Widget _buildFootballTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _buildFootballTabButton(index: 0, label: l10n.generalTab),
          _buildFootballTabButton(index: 1, label: l10n.teamTab),
          _buildFootballTabButton(index: 2, label: l10n.rulesTab),
        ],
      ),
    );
  }

  Widget _buildFootballTabButton({required int index, required String label}) {
    final bool isSelected = _selectedFootballTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFootballTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF13EC5B) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF13EC5B).withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.black : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFootballTeamTab() {
    final String selectedFormat = _currentMeetup.teamFormat ?? '';
    final String selectedFormation = _currentMeetup.formation ?? '';
    final List<FormationConfig> availableFormations =
        FormationData.formations[selectedFormat] ?? const <FormationConfig>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Mac Formati',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            const _FootballRequiredTag(),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: FormationData.formats.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final format = FormationData.formats[index];
              final isSelected = format == selectedFormat;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF13EC5B) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF13EC5B)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  format,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.black : Colors.grey.shade700,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Formasyon',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (availableFormations.isEmpty)
          _buildFootballEmptyState(
            icon: Icons.sports_soccer_outlined,
            text: 'Bu etkinlikte formasyon bilgisi bulunmuyor.',
          )
        else
          SizedBox(
            height: 156,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: availableFormations.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final config = availableFormations[index];
                final isSelected = config.formation == selectedFormation;
                return Container(
                  width: 240,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF13EC5B)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(
                                      0xFF13EC5B,
                                    ).withValues(alpha: 0.2)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Icon(
                              isSelected ? Icons.check_circle : Icons.shield,
                              size: 18,
                              color: isSelected
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              config.formation,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.green.shade800
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _buildFormationCountChips(config),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text(
              l10n.formation,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (_isOrganizer)
              GestureDetector(
                onTap: _autoFillTeams,
                child: Text(
                  'Otomatik Doldur',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildFootballPitchBoard(),
      ],
    );
  }

  List<Widget> _buildFormationCountChips(FormationConfig config) {
    final entries = <MapEntry<FootballPosition, int>>[
      MapEntry(
        FootballPosition.goalkeeper,
        config.positionCounts[FootballPosition.goalkeeper] ?? 0,
      ),
      MapEntry(
        FootballPosition.defender,
        config.positionCounts[FootballPosition.defender] ?? 0,
      ),
      MapEntry(
        FootballPosition.midfielder,
        config.positionCounts[FootballPosition.midfielder] ?? 0,
      ),
      MapEntry(
        FootballPosition.forward,
        config.positionCounts[FootballPosition.forward] ?? 0,
      ),
    ];

    return entries.where((entry) => entry.value > 0).map((entry) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${entry.value} ${_positionLabel(entry.key)}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildFootballPitchBoard() {
    final teamASlots = _currentMeetup.teamASlots ?? const <PositionSlot>[];
    final teamBSlots = _currentMeetup.teamBSlots ?? const <PositionSlot>[];

    if (teamASlots.isEmpty && teamBSlots.isEmpty) {
      return _buildFootballEmptyState(
        icon: Icons.groups_outlined,
        text: l10n.teamNotSetUp,
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8FAEE), Color(0xFFF5FCF8)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF13EC5B).withValues(alpha: 0.2),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 1.2,
                  color: const Color(0xFF13EC5B).withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF13EC5B).withValues(alpha: 0.22),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTeamColumn(l10n.teamA, teamASlots, 'A')),
              const SizedBox(width: 12),
              Expanded(child: _buildTeamColumn(l10n.teamB, teamBSlots, 'B')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamColumn(String teamName, List<PositionSlot> slots, String team) {
    final positionCounters = <String, int>{};
    final bool canSelect = !_isParticipating && _currentMeetup.isFootballWithTeams;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                teamName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...slots.asMap().entries.map((entry) {
            final index = entry.key;
            final slot = entry.value;
            positionCounters[slot.position] =
                (positionCounters[slot.position] ?? 0) + 1;
            final slotOrder = positionCounters[slot.position]!;
            final isSelected = _selectedTeam == team && _selectedSlotIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: (canSelect && slot.isEmpty)
                    ? () {
                        setState(() {
                          _selectedTeam = team;
                          _selectedSlotIndex = index;
                        });
                      }
                    : null,
                child: _buildTeamSlotTile(
                  slot: slot,
                  slotOrder: slotOrder,
                  isSelected: isSelected,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTeamSlotTile({
    required PositionSlot slot,
    required int slotOrder,
    bool isSelected = false,
  }) {
    final bool isOrganizer = slot.assignedUserId == _currentMeetup.organizerId;
    final Color accent = _positionColor(slot.position);

    if (slot.isFilled) {
      final initial = (slot.assignedUserName ?? '?').trim().isNotEmpty
          ? slot.assignedUserName!.trim()[0].toUpperCase()
          : '?';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isOrganizer
                  ? Colors.amber.withValues(alpha: 0.3)
                  : accent.withValues(alpha: 0.2),
              backgroundImage: slot.assignedUserImageUrl != null
                  ? NetworkImage(slot.assignedUserImageUrl!)
                  : null,
              child: slot.assignedUserImageUrl == null
                  ? Text(
                      isOrganizer ? 'K' : initial,
                      style: TextStyle(
                        color: isOrganizer ? Colors.amber.shade800 : accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.assignedUserName ?? 'Bilinmeyen',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isOrganizer
                        ? 'Kaptan'
                        : _slotDisplayName(slot.position, slotOrder),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Empty slot - selected state
    if (isSelected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF13EC5B).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFF13EC5B),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF13EC5B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(Icons.check, size: 16, color: Color(0xFF13EC5B)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _slotDisplayName(slot.position, slotOrder),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Empty slot with dashed border
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: Colors.grey.shade400,
        borderRadius: 999,
        strokeWidth: 1.2,
        dashWidth: 5,
        dashSpace: 3,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(Icons.add, size: 16, color: Colors.grey.shade500),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _slotDisplayName(slot.position, slotOrder),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFootballRulesTab() {
    final rulesText = _currentMeetup.rules.trim();
    if (rulesText.isEmpty) {
      return _buildFootballEmptyState(
        icon: Icons.rule_folder_outlined,
        text: l10n.noRulesAdded,
      );
    }

    final lines = rulesText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, size: 18, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Text(
                'Etkinlik Kurallari',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...lines.map((line) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        height: 1.4,
                        color: Colors.grey.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFootballEmptyState({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  String _positionLabel(FootballPosition position) {
    switch (position) {
      case FootballPosition.goalkeeper:
        return 'Kaleci';
      case FootballPosition.defender:
        return 'Defans';
      case FootballPosition.midfielder:
        return 'Orta';
      case FootballPosition.forward:
        return 'Forvet';
    }
  }

  String _slotDisplayName(String position, int slotOrder) {
    final base = switch (position) {
      'goalkeeper' => 'Kaleci',
      'defender' => 'Defans',
      'midfielder' => 'Orta',
      'forward' => 'Forvet',
      _ => 'Pozisyon',
    };
    if (position == 'goalkeeper') {
      return base;
    }
    return '$base $slotOrder';
  }

  Color _positionColor(String position) {
    switch (position) {
      case 'goalkeeper':
        return Colors.orange.shade700;
      case 'defender':
        return Colors.blue.shade700;
      case 'midfielder':
        return Colors.green.shade700;
      case 'forward':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
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
                  l10n.reviewCount(participant.totalRatings),
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
                      child: Text(l10n.closeButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/user-profile/${participant.id}');
                      },
                      child: Text(l10n.viewProfile),
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
                    '${l10n.participants} (${_participants.length})',
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
                                    l10n.organizer,
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
    switch (month) {
      case 1:
        return l10n.monthJan;
      case 2:
        return l10n.monthFeb;
      case 3:
        return l10n.monthMar;
      case 4:
        return l10n.monthApr;
      case 5:
        return l10n.monthMay;
      case 6:
        return l10n.monthJun;
      case 7:
        return l10n.monthJul;
      case 8:
        return l10n.monthAug;
      case 9:
        return l10n.monthSep;
      case 10:
        return l10n.monthOct;
      case 11:
        return l10n.monthNov;
      case 12:
        return l10n.monthDec;
      default:
        return '';
    }
  }

  String _formatTime(DateTime date, {DateTime? endDate}) {
    final startTime =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (endDate != null) {
      final endTime =
          '${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}';
      return '$startTime - $endTime';
    }
    return startTime;
  }
}

class _FootballRequiredTag extends StatelessWidget {
  const _FootballRequiredTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF13EC5B).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Zorunlu',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.green.shade800,
        ),
      ),
    );
  }
}

/// Custom painter for dashed stadium-shaped borders on empty position slots
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.height / 2), // stadium shape
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance = end + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashWidth != oldDelegate.dashWidth ||
      dashSpace != oldDelegate.dashSpace;
}










