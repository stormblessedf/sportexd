import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/meetup_model.dart';
import '../../../../core/services/meetup_service.dart';
import 'widgets/meetup_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meetupService = MeetupService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sporsal Akış'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<MeetupModel>>(
        stream: meetupService.getMeetups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }

          final meetups = snapshot.data ?? [];

          if (meetups.isEmpty) {
            return const Center(
              child: Text(
                'Henüz etkinlik yok.\nİlk etkinliği sen oluştur!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Firestore streams update automatically, but for UX feel we can fake it or just return
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: meetups.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return MeetupCard(
                  meetup: meetups[index],
                  onTap: () {
                    context.push('/detail', extra: meetups[index]);
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
