import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/meetup_model.dart';
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
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _checkParticipation();
  }

  Future<void> _checkParticipation() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Organizer is always a participant
    if (widget.meetup.organizerId == userId) {
      setState(() {
        _isParticipating = true;
        _currentUserId = userId;
        _isLoading = false;
      });
      return;
    }

    final isParticipant = await _meetupService.isParticipant(widget.meetup.id, userId);
    if (mounted) {
      setState(() {
        _isParticipating = isParticipant;
        _currentUserId = userId;
        _isLoading = false;
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
      await _meetupService.joinMeetup(widget.meetup.id, _currentUserId!);
      if (mounted) {
        setState(() {
          _isParticipating = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buluşmaya başarıyla katıldınız!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFull =
        widget.meetup.currentParticipants >= widget.meetup.maxParticipants;
    final bool isPast = _meetupService.isMeetupPast(widget.meetup);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Elegant Header with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'meetup_img_${widget.meetup.id}',
                child: Image.network(widget.meetup.imageUrl, fit: BoxFit.cover),
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
                          widget.meetup.type.name.toUpperCase(),
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
                    widget.meetup.title,
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
                        '${widget.meetup.date.day} ${_getMonth(widget.meetup.date.month)} • ${_formatTime(widget.meetup.date)}',
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.location_on_outlined,
                    title: 'Buluşma Yeri',
                    subtitle: widget.meetup.locationName,
                    description: widget.meetup.locationAddress,
                  ),
                  const SizedBox(height: 16),

                  // Map Widget
                  MeetupMapWidget(
                    latitude: widget.meetup.latitude,
                    longitude: widget.meetup.longitude,
                    locationName: widget.meetup.locationName,
                    locationAddress: widget.meetup.locationAddress,
                  ),
                  const SizedBox(height: 24),

                  // Organizer Info
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.push('/user-profile/${widget.meetup.organizerId}');
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              backgroundImage: widget.meetup.organizerImageUrl != null
                                  ? NetworkImage(widget.meetup.organizerImageUrl!)
                                  : null,
                              child: widget.meetup.organizerImageUrl == null
                                  ? const Icon(Icons.person, color: Colors.white)
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
                                Text(
                                  widget.meetup.organizerName,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () {
                          context.push('/user-profile/${widget.meetup.organizerId}');
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
                    widget.meetup.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Participants Preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Katılımcılar (${widget.meetup.currentParticipants}/${widget.meetup.maxParticipants})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {},
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
                                    chatId: widget.meetup.id,
                                    title: widget.meetup.title,
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
                              context.push('/rate-participants', extra: {
                                'meetupId': widget.meetup.id,
                                'meetupTitle': widget.meetup.title,
                                'participantIds': widget.meetup.participantIds,
                              });
                            },
                            icon: const Icon(Icons.star_rate, color: Color(0xFFFF9800)),
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
                    ? ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: widget.meetup.id,
                                title: widget.meetup.title,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_rounded),
                        label: const Text('Grup Sohbetine Git'),
                      )
                    : ElevatedButton(
                        onPressed: isFull ? null : _joinMeetup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFull ? Colors.grey : null,
                        ),
                        child: Text(isFull ? 'Kontenjan Dolu' : 'Hemen Katıl'),
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
    return Row(
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white10,
            child: Icon(
              Icons.person,
              size: 20,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
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

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
