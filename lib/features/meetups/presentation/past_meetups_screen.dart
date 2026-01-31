import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/meetup_model.dart';
import '../../../core/services/meetup_service.dart';
import '../../home/presentation/widgets/meetup_card.dart';

class PastMeetupsScreen extends StatelessWidget {
  final String userId;

  const PastMeetupsScreen({super.key, required this.userId});

  // Theme colors
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF13EC5B);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final meetupService = MeetupService();

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('Geçmiş Etkinliklerim'),
        backgroundColor: backgroundLight,
        foregroundColor: textDark,
        elevation: 0,
      ),
      body: StreamBuilder<List<MeetupModel>>(
        stream: meetupService.getPastMeetupsForUser(userId),
        builder: (context, snapshot) {
          // Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primary,
              ),
            );
          }

          // Error State
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bir hata oluştu',
                    style: TextStyle(
                      color: Colors.red[300],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final pastMeetups = snapshot.data ?? [];

          // Empty State
          if (pastMeetups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Henüz geçmiş etkinliğiniz yok',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Etkinliklere katılmaya başlayın!',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.go('/home');
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Etkinlikleri Keşfet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: textDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // List of Past Meetups
          return RefreshIndicator(
            color: primary,
            backgroundColor: surfaceLight,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pastMeetups.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final meetup = pastMeetups[index];
                return MeetupCard(
                  meetup: meetup,
                  onTap: () {
                    context.push('/detail', extra: meetup);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
