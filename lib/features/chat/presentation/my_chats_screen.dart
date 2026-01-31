import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/meetup_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/meetup_service.dart';

class MyChatsScreen extends StatefulWidget {
  const MyChatsScreen({super.key});

  @override
  State<MyChatsScreen> createState() => _MyChatsScreenState();
}

class _MyChatsScreenState extends State<MyChatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userId = authService.currentUserId;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("Sohbetleri görmek için giriş yapın.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sohbetler"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.chat_bubble),
              text: 'Aktif',
            ),
            Tab(
              icon: Icon(Icons.check_circle_outline),
              text: 'Geçmiş',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveChatsTab(userId: userId),
          _PastChatsTab(userId: userId),
        ],
      ),
    );
  }
}

// Active Chats Tab
class _ActiveChatsTab extends StatelessWidget {
  final String userId;

  const _ActiveChatsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final meetupService = MeetupService();

    return StreamBuilder<List<MeetupModel>>(
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
                  "Henüz aktif sohbetiniz yok",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Etkinliklere katılarak sohbetlere dahil olabilirsiniz",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Filter only upcoming/active meetups
        final activeMeetups = snapshot.data!
            .where((meetup) => !meetupService.isMeetupPast(meetup))
            .toList();

        if (activeMeetups.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "Henüz aktif sohbetiniz yok",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: activeMeetups.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final meetup = activeMeetups[index];
            return _ChatListTile(meetup: meetup);
          },
        );
      },
    );
  }
}

// Past Chats Tab
class _PastChatsTab extends StatelessWidget {
  final String userId;

  const _PastChatsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final meetupService = MeetupService();

    return StreamBuilder<List<MeetupModel>>(
      stream: meetupService.getPastMeetupsForUser(userId),
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
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "Henüz geçmiş sohbetiniz yok",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Tamamlanan etkinliklerin sohbetleri burada görünecek",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final pastMeetups = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pastMeetups.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final meetup = pastMeetups[index];
            return _ChatListTile(meetup: meetup, isPast: true);
          },
        );
      },
    );
  }
}

// Chat List Tile Widget
class _ChatListTile extends StatelessWidget {
  final MeetupModel meetup;
  final bool isPast;

  const _ChatListTile({
    required this.meetup,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(meetup.imageUrl),
            onBackgroundImageError: (exception, stackTrace) {},
          ),
          if (isPast)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              meetup.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (isPast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Tamamlandı',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
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
  }
}
