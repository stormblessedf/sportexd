import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/meetup_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/meetup_service.dart';

class MyChatsScreen extends StatelessWidget {
  const MyChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final meetupService = MeetupService();
    final userId = authService.currentUserId;

    if (userId == null) {
      return const Center(child: Text("Sohbetleri görmek için giriş yapın."));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sohbetler"),
      ),
      body: StreamBuilder<List<MeetupModel>>(
        stream: meetupService.getUserMeetups(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Henüz katıldığınız bir etkinlik yok.\nEtkinliklere katılarak sohbetlere dahil olabilirsiniz.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final meetups = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: meetups.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final meetup = meetups[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(meetup.imageUrl),
                  onBackgroundImageError: (_, __) => const Icon(Icons.group),
                ),
                title: Text(
                  meetup.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  meetup.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.push('/chat', extra: {
                    'chatId': meetup.id,
                    'title': meetup.title,
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}
