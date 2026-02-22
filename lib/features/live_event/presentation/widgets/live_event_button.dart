import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/meetup_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/meetup_service.dart';
import '../../../../theme/app_theme.dart';

/// Profil sayfasında gösterilen animasyonlu canlı etkinlik butonu.
///
/// Aktif etkinlik varsa görünür, yoksa gizli (SizedBox.shrink).
/// [userId] verilirse o kullanıcının aktif etkinliklerini gösterir,
/// verilmezse oturum açmış kullanıcının etkinliklerini gösterir.
/// Tıklandığında `/live-event/{meetupId}` rotasına yönlendirir.
class LiveEventButton extends StatefulWidget {
  final String? userId;
  const LiveEventButton({super.key, this.userId});

  @override
  State<LiveEventButton> createState() => _LiveEventButtonState();
}

class _LiveEventButtonState extends State<LiveEventButton>
    with SingleTickerProviderStateMixin {
  final MeetupService _meetupService = MeetupService();
  final AuthService _authService = AuthService();

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  List<MeetupModel>? _activeMeetups;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadActiveMeetups();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveMeetups() async {
    final targetUserId = widget.userId ?? _authService.currentUserId;
    if (targetUserId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final meetups = await _meetupService.getActiveMeetupsForUser(targetUserId);
      if (mounted) {
        setState(() {
          _activeMeetups = meetups;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  MeetupModel? _selectClosestMeetup(List<MeetupModel> meetups) {
    if (meetups.isEmpty) return null;
    if (meetups.length == 1) return meetups.first;

    final now = DateTime.now();
    meetups.sort((a, b) {
      final diffA = (a.date.difference(now)).abs();
      final diffB = (b.date.difference(now)).abs();
      return diffA.compareTo(diffB);
    });
    return meetups.first;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final meetups = _activeMeetups;
    if (meetups == null || meetups.isEmpty) return const SizedBox.shrink();

    final selectedMeetup = _selectClosestMeetup(meetups);
    if (selectedMeetup == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/live-event/${selectedMeetup.id}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(
                      alpha: _pulseAnimation.value,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(
                          alpha: _pulseAnimation.value * 0.5,
                        ),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Canlı Etkinlik',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
