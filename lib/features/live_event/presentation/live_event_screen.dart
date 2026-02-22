import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/models/event_photo_model.dart';
import '../../../core/models/meetup_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/event_photo_service.dart';
import '../../../core/services/meetup_service.dart';
import '../../../theme/app_theme.dart';
import '../utils/progress_utils.dart';
import '../../live_broadcast/live_broadcast.dart';

class LiveEventScreen extends StatefulWidget {
  final String meetupId;
  const LiveEventScreen({super.key, required this.meetupId});

  @override
  State<LiveEventScreen> createState() => _LiveEventScreenState();
}

class _LiveEventScreenState extends State<LiveEventScreen> {
  final MeetupService _meetupService = MeetupService();
  final AuthService _authService = AuthService();
  late final EventPhotoService _photoService;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  List<UserModel> _participants = [];
  bool _participantsLoaded = false;
  String? _lastParticipantKey;

  @override
  void initState() {
    super.initState();
    _photoService = EventPhotoService(meetupService: _meetupService);
  }

  Future<void> _loadParticipants(List<String> participantIds) async {
    final key = participantIds.join(',');
    if (_participantsLoaded && _lastParticipantKey == key) return;
    _lastParticipantKey = key;

    final List<UserModel> users = [];
    for (final id in participantIds) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
        if (doc.exists) {
          users.add(UserModel.fromJson(doc.data()!));
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() { _participants = users; _participantsLoaded = true; });
    }
  }

  Future<void> _pickAndUploadPhoto(MeetupModel meetup) async {
    final userId = _authService.currentUserId;
    if (userId == null) return;
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85,
      );
      if (pickedFile == null) return;
      setState(() => _isUploading = true);
      final Uint8List imageBytes = await pickedFile.readAsBytes();
      final user = await _authService.getCurrentUser();
      await _photoService.uploadPhoto(
        meetupId: widget.meetupId, userId: userId,
        userName: user?.username ?? 'Anonim', userImageUrl: user?.profileImageUrl,
        imageBytes: imageBytes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf başarıyla paylaşıldı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf yüklenirken bir hata oluştu')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('meetups').doc(widget.meetupId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(snapshot.hasError ? 'Bir hata oluştu' : 'Etkinlik bulunamadı',
                  style: TextStyle(color: Colors.red[300], fontSize: 18, fontWeight: FontWeight.w600)),
              ]),
            );
          }

          final meetup = MeetupModel.fromJson(snapshot.data!.data() as Map<String, dynamic>);
          final effectiveEnd = _meetupService.getEffectiveEndDate(meetup);
          final progress = calculateProgress(meetup.date, effectiveEnd, DateTime.now());
          final isCompleted = progress >= 1.0;

          // Load participants (has its own guard via _lastParticipantKey)
          _loadParticipants(meetup.participantIds);

          return CustomScrollView(
            slivers: [
              // Sticky glass header — countdown is self-contained inside
              SliverPersistentHeader(
                pinned: true,
                delegate: _LiveHeaderDelegate(
                  meetup: meetup,
                  isCompleted: isCompleted,
                  effectiveEnd: effectiveEnd,
                  topPadding: MediaQuery.of(context).padding.top,
                ),
              ),
              // Body content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPhotoGallery(meetup, isCompleted),
                      const SizedBox(height: 32),
                      _buildLiveBroadcastSection(meetup),
                      const SizedBox(height: 32),
                      _buildParticipantsSection(meetup),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Photo Gallery (horizontal scroll) ──
  Widget _buildPhotoGallery(MeetupModel meetup, bool isCompleted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: StreamBuilder<List<EventPhotoModel>>(
            stream: _photoService.getPhotosForMeetup(widget.meetupId),
            builder: (context, snap) {
              final photos = snap.data ?? [];
              final List<Widget> cards = [];

              if (meetup.imageUrl.isNotEmpty) {
                cards.add(_GalleryCard(
                  imageUrl: meetup.imageUrl,
                  overlayLabel: 'Kapak Fotoğrafı',
                  overlaySubtitle: meetup.organizerName,
                  isPrimary: true,
                ));
              }

              for (final photo in photos) {
                cards.add(_GalleryCard(
                  imageUrl: photo.photoUrl,
                  userName: photo.userName,
                  userImageUrl: photo.userImageUrl,
                ));
              }

              if (cards.isEmpty) {
                cards.add(Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  decoration: BoxDecoration(
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.photo_library_outlined, size: 48, color: AppTheme.textLight),
                      SizedBox(height: 8),
                      Text('Henüz fotoğraf yok', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                    ]),
                  ),
                ));
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (_, i) => SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: cards[i],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            elevation: 4,
            shadowColor: AppTheme.primary.withValues(alpha: 0.3),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isCompleted || _isUploading ? null : () => _pickAndUploadPhoto(meetup),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _isUploading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                      : const Icon(Icons.add_a_photo, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isUploading ? 'Yükleniyor...' : 'Fotoğraf Ekle',
                    style: const TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 14,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Live Broadcast Section ──
  Widget _buildLiveBroadcastSection(MeetupModel meetup) {
    final liveService = LiveBroadcastService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Canlı Yayınlar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ],
        ),
        const SizedBox(height: 12),
        // Yayın Başlat Butonu
        GestureDetector(
          onTap: () => _startBroadcast(meetup),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Colors.redAccent],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.videocam, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Yayın Başlat', style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textDark)),
                    SizedBox(height: 2),
                    Text('Maçı canlı paylaş', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow, color: Colors.white, size: 18),
                      SizedBox(width: 4),
                      Text('Başlat',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Aktif Yayınlar Listesi
        StreamBuilder<List<StreamSession>>(
          stream: liveService.watchActiveStreams(),
          builder: (context, snapshot) {
            final allStreams = snapshot.data ?? [];
            // Bu etkinliğe ait yayınları filtrele
            final eventStreams = allStreams.where((s) => s.eventId == meetup.id).toList();

            if (eventStreams.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.borderLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off, color: AppTheme.textMuted, size: 20),
                    SizedBox(width: 8),
                    Text('Henüz aktif yayın yok',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                  ],
                ),
              );
            }

            return SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: eventStreams.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (_, i) {
                  final stream = eventStreams[i];
                  return _LiveStreamCard(
                    stream: stream,
                    onTap: () => context.push('/live-broadcast/viewer/${stream.id}'),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  void _startBroadcast(MeetupModel meetup) {
    context.push('/live-broadcast/create', extra: {
      'eventId': meetup.id,
      'eventName': meetup.title,
    });
  }

  // ── Participants Section ──
  Widget _buildParticipantsSection(MeetupModel meetup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Kadro (${meetup.currentParticipants}/${meetup.maxParticipants})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            GestureDetector(
              onTap: () {},
              child: const Text('Tümünü Gör',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: _participantsLoaded
              ? _participants.isEmpty
                  ? const Center(child: Text('Katılımcı bulunamadı', style: TextStyle(color: AppTheme.textMuted)))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _participants.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _ParticipantCard(
                        user: _participants[i],
                        isOrganizer: _participants[i].id == meetup.organizerId,
                        onTap: () => context.push('/user-profile/${_participants[i].id}'),
                      ),
                    )
              : const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        ),
      ],
    );
  }
}


// ── Self-contained Countdown Widget ──
// Manages its own Timer so setState only rebuilds this widget, not the whole page.
class _CountdownText extends StatefulWidget {
  final DateTime endTime;
  final bool isCompleted;

  const _CountdownText({required this.endTime, required this.isCompleted});

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  Timer? _timer;
  String _text = '00:00:00';

  @override
  void initState() {
    super.initState();
    _update();
    if (!widget.isCompleted) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
    }
  }

  @override
  void didUpdateWidget(covariant _CountdownText old) {
    super.didUpdateWidget(old);
    if (old.endTime != widget.endTime || old.isCompleted != widget.isCompleted) {
      _timer?.cancel();
      _update();
      if (!widget.isCompleted) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _update() {
    final remaining = widget.endTime.difference(DateTime.now());
    if (remaining.isNegative) {
      _timer?.cancel();
      if (mounted) setState(() => _text = '00:00:00');
      return;
    }
    if (mounted) setState(() => _text = formatRemainingTime(remaining));
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _text,
      style: TextStyle(
        fontSize: 32, fontWeight: FontWeight.bold,
        color: widget.isCompleted ? AppTheme.textMuted : AppTheme.primary,
        fontFamily: 'monospace', letterSpacing: 2,
      ),
    );
  }
}


// ── Sticky Glass Header Delegate ──
class _LiveHeaderDelegate extends SliverPersistentHeaderDelegate {
  final MeetupModel meetup;
  final bool isCompleted;
  final DateTime effectiveEnd;
  final double topPadding;

  _LiveHeaderDelegate({
    required this.meetup,
    required this.isCompleted,
    required this.effectiveEnd,
    required this.topPadding,
  });

  @override
  double get maxExtent => 220 + topPadding;
  @override
  double get minExtent => 220 + topPadding;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final startStr = DateFormat('HH:mm').format(meetup.date);
    final endStr = DateFormat('HH:mm').format(effectiveEnd);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: AppTheme.borderLight.withValues(alpha: 0.5))),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: back + LIVE badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textMuted),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _PulsingDot(isCompleted: isCompleted),
                      const SizedBox(width: 6),
                      Text(
                        isCompleted ? 'BİTTİ' : 'CANLI',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold,
                          color: isCompleted ? AppTheme.textMuted : AppTheme.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 28),
                ],
              ),
              const SizedBox(height: 8),
              // Title
              Text(meetup.title,
                textAlign: TextAlign.center,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
              const SizedBox(height: 6),
              // Countdown — isolated widget, only this rebuilds every second
              _CountdownText(endTime: effectiveEnd, isCompleted: isCompleted),
              const SizedBox(height: 6),
              // Location & time row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.place, size: 15, color: AppTheme.textMuted),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(meetup.locationName,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(width: 4, height: 4,
                      decoration: BoxDecoration(color: AppTheme.borderLight, shape: BoxShape.circle)),
                  ),
                  const Icon(Icons.schedule, size: 15, color: AppTheme.textMuted),
                  const SizedBox(width: 3),
                  Text('$startStr - $endStr',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _LiveHeaderDelegate oldDelegate) =>
      isCompleted != oldDelegate.isCompleted ||
      effectiveEnd != oldDelegate.effectiveEnd ||
      meetup.id != oldDelegate.meetup.id;
}


// ── Pulsing green dot ──
class _PulsingDot extends StatefulWidget {
  final bool isCompleted;
  const _PulsingDot({required this.isCompleted});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _scaleAnim = Tween(begin: 0.8, end: 2.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacityAnim = Tween(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompleted) {
      return Container(width: 8, height: 8,
        decoration: BoxDecoration(color: AppTheme.textMuted, shape: BoxShape.circle));
    }
    return SizedBox(
      width: 10, height: 10,
      child: Stack(alignment: Alignment.center, children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnim.value,
            child: Opacity(
              opacity: _opacityAnim.value,
              child: Container(width: 10, height: 10,
                decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
            ),
          ),
        ),
        Container(width: 8, height: 8,
          decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
      ]),
    );
  }
}

// ── Gallery Card ──
class _GalleryCard extends StatelessWidget {
  final String imageUrl;
  final String? overlayLabel;
  final String? overlaySubtitle;
  final bool isPrimary;
  final String? userName;
  final String? userImageUrl;

  const _GalleryCard({
    required this.imageUrl,
    this.overlayLabel,
    this.overlaySubtitle,
    this.isPrimary = false,
    this.userName,
    this.userImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppTheme.borderLight,
              child: const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))),
            errorWidget: (_, __, ___) => Container(color: AppTheme.borderLight,
              child: const Icon(Icons.broken_image, color: AppTheme.textLight, size: 40)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: isPrimary ? 0.6 : 0.5)],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: isPrimary
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(overlayLabel ?? '',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    const SizedBox(height: 4),
                    Text(overlaySubtitle ?? '',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                  ])
                : Row(children: [
                    if (userImageUrl != null && userImageUrl!.isNotEmpty)
                      CircleAvatar(radius: 12,
                        backgroundImage: CachedNetworkImageProvider(userImageUrl!),
                        backgroundColor: AppTheme.borderLight)
                    else
                      const CircleAvatar(radius: 12, backgroundColor: AppTheme.borderLight,
                        child: Icon(Icons.person, size: 14, color: AppTheme.textLight)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('@${userName ?? ''}',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                  ]),
          ),
        ],
      ),
    );
  }
}


// ── Participant Card ──
class _ParticipantCard extends StatelessWidget {
  final UserModel user;
  final bool isOrganizer;
  final VoidCallback onTap;

  const _ParticipantCard({
    required this.user,
    required this.isOrganizer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.borderLight,
                  backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                      ? const Icon(Icons.person, size: 32, color: AppTheme.textLight)
                      : null,
                ),
                Positioned(
                  bottom: 2, right: 0,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: user.isOnline ? AppTheme.primary : AppTheme.borderLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surfaceLight, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(user.username,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
            const SizedBox(height: 4),
            if (user.averageRating > 0)
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 3),
                Text(user.averageRating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              ]),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isOrganizer
                    ? AppTheme.primary.withValues(alpha: 0.1)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isOrganizer ? 'Organizatör' : _getLevelText(user.level),
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: isOrganizer ? AppTheme.primary : AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelText(Level? level) {
    switch (level) {
      case Level.beginner: return 'Başlangıç';
      case Level.intermediate: return 'Orta';
      case Level.advanced: return 'İleri';
      default: return 'Oyuncu';
    }
  }
}


// ── Live Stream Card ──
class _LiveStreamCard extends StatelessWidget {
  final StreamSession stream;
  final VoidCallback onTap;

  const _LiveStreamCard({
    required this.stream,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.red, Colors.redAccent, Colors.orange],
                  ),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.borderLight,
                  backgroundImage: stream.broadcasterAvatar.isNotEmpty
                      ? NetworkImage(stream.broadcasterAvatar)
                      : null,
                  child: stream.broadcasterAvatar.isEmpty
                      ? Text(
                          stream.broadcasterName.isNotEmpty
                              ? stream.broadcasterName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMuted,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: -4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.surfaceLight, width: 2),
                    ),
                    child: const Text(
                      'CANLI',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            stream.broadcasterName,
            style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.visibility, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 3),
              Text(
                '${stream.currentViewers}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
