import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/meetup_model.dart';
import '../../../core/models/chat_update_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/meetup_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../theme/app_theme.dart';
import 'widgets/chat_card.dart';
import 'widgets/chat_list_header.dart';
import 'widgets/empty_state_widget.dart';

class MyChatsScreen extends StatefulWidget {
  const MyChatsScreen({super.key});

  @override
  State<MyChatsScreen> createState() => _MyChatsScreenState();
}

class _MyChatsScreenState extends State<MyChatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        backgroundColor: AppTheme.backgroundLight,
        body: Center(
          child: EmptyStateWidget(
            icon: Icons.login,
            message: 'Sohbetleri görmek için giriş yapın',
            subtitle:
                'Hesabınıza giriş yaparak etkinlik sohbetlerinize ulaşabilirsiniz',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Sticky header with backdrop blur
              SliverAppBar(
                floating: true,
                snap: true,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                expandedHeight: 50,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: AppTheme.backgroundLight.withValues(alpha: 0.9),
                      child: ChatListHeader(
                        onFilterTap: () {
                          // TODO: Implement filter functionality
                          _showFilterBottomSheet(context);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // Tab bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primary,
                    indicatorWeight: 3,
                    labelColor: AppTheme.textDark,
                    unselectedLabelColor: AppTheme.textMuted,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'Aktif'),
                      Tab(text: 'Geçmiş'),
                      Tab(text: 'DM'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _ActiveChatsTab(userId: userId, chatService: _chatService),
              _PastChatsTab(userId: userId, chatService: _chatService),
              _DirectMessagesTab(userId: userId, chatService: _chatService),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sohbetleri Filtrele',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.sports_soccer),
                title: const Text('Spor Türüne Göre'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort),
                title: const Text('Tarihe Göre Sırala'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// Sliver delegate for tab bar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppTheme.backgroundLight, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

// Active Chats Tab
class _ActiveChatsTab extends StatelessWidget {
  final String userId;
  final ChatService chatService;

  const _ActiveChatsTab({required this.userId, required this.chatService});

  @override
  Widget build(BuildContext context) {
    final meetupService = MeetupService();

    return StreamBuilder<List<MeetupModel>>(
      stream: meetupService.getUserMeetups(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (snapshot.hasError) {
          return EmptyStateWidget(
            icon: Icons.error_outline,
            message: 'Bir hata oluştu',
            subtitle: snapshot.error.toString(),
            iconColor: Colors.red,
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const ActiveChatsEmptyState();
        }

        // Filter only upcoming/active meetups
        final activeMeetups = snapshot.data!
            .where((meetup) => !meetupService.isMeetupPast(meetup))
            .toList();

        if (activeMeetups.isEmpty) {
          return const ActiveChatsEmptyState();
        }

        // Sort by date (nearest first)
        activeMeetups.sort((a, b) => a.date.compareTo(b.date));

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: activeMeetups.length,
          separatorBuilder: (context, index) => const ChatDivider(),
          itemBuilder: (context, index) {
            final meetup = activeMeetups[index];
            return _ChatCardWithStream(
              meetup: meetup,
              userId: userId,
              chatService: chatService,
              isPast: false,
            );
          },
        );
      },
    );
  }
}

// Past Chats Tab
class _PastChatsTab extends StatelessWidget {
  final String userId;
  final ChatService chatService;

  const _PastChatsTab({required this.userId, required this.chatService});

  @override
  Widget build(BuildContext context) {
    final meetupService = MeetupService();

    return StreamBuilder<List<MeetupModel>>(
      stream: meetupService.getPastMeetupsForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (snapshot.hasError) {
          return EmptyStateWidget(
            icon: Icons.error_outline,
            message: 'Bir hata oluştu',
            subtitle: snapshot.error.toString(),
            iconColor: Colors.red,
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const PastChatsEmptyState();
        }

        final pastMeetups = snapshot.data!;

        // Sort by date (most recent first)
        pastMeetups.sort((a, b) => b.date.compareTo(a.date));

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: pastMeetups.length,
          separatorBuilder: (context, index) => const ChatDivider(),
          itemBuilder: (context, index) {
            final meetup = pastMeetups[index];
            return _ChatCardWithStream(
              meetup: meetup,
              userId: userId,
              chatService: chatService,
              isPast: true,
            );
          },
        );
      },
    );
  }
}

// Direct Messages Tab
class _DirectMessagesTab extends StatelessWidget {
  final String userId;
  final ChatService chatService;

  const _DirectMessagesTab({required this.userId, required this.chatService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: chatService.getDirectChats(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (snapshot.hasError) {
          return EmptyStateWidget(
            icon: Icons.error_outline,
            message: 'Bir hata oluştu',
            subtitle: snapshot.error.toString(),
            iconColor: Colors.red,
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: EmptyStateWidget(
              icon: Icons.chat_bubble_outline,
              message: 'Henüz direkt mesajınız yok',
              subtitle: 'Spor partnerlerinize mesaj gönderin',
            ),
          );
        }

        final dmChats = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: dmChats.length,
          separatorBuilder: (context, index) => const ChatDivider(),
          itemBuilder: (context, index) {
            final chat = dmChats[index];
            final chatId = chat['chatId'] as String;
            final participantNames = chat['participantNames'] as Map<String, dynamic>? ?? {};
            final participants = (chat['participants'] as List<dynamic>?)?.cast<String>() ?? [];
            final otherUserId = participants.firstWhere((id) => id != userId, orElse: () => '');
            final otherUserName = participantNames[otherUserId] ?? 'Kullanıcı';
            final lastMessage = chat['lastMessage'] as String?;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                child: Text(
                  otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                otherUserName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              subtitle: lastMessage != null
                  ? Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    )
                  : const Text(
                      'Henüz mesaj yok',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
              onTap: () {
                chatService.clearUnreadCount(chatId, userId);
                context.push(
                  '/chat',
                  extra: {'chatId': chatId, 'title': otherUserName},
                );
              },
            );
          },
        );
      },
    );
  }
}

// Chat Card with real-time stream updates
class _ChatCardWithStream extends StatelessWidget {
  final MeetupModel meetup;
  final String userId;
  final ChatService chatService;
  final bool isPast;

  const _ChatCardWithStream({
    required this.meetup,
    required this.userId,
    required this.chatService,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatUpdateModel>(
      stream: chatService.streamChatUpdates(meetup.id, userId),
      builder: (context, snapshot) {
        final chatUpdate = snapshot.data;

        // Listen to organizer mode status
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(meetup.id)
              .snapshots(),
          builder: (context, chatSnapshot) {
            final isOrganizerOnlyMode =
                chatSnapshot.hasData && chatSnapshot.data != null
                ? ((chatSnapshot.data!.data()
                          as Map<String, dynamic>?)?['isOrganizerOnlyMode'] ??
                      false)
                : false;

            return ChatCard(
              meetup: meetup,
              lastMessage: chatUpdate?.lastMessage,
              unreadCount: chatUpdate?.unreadCount ?? 0,
              lastActivityTime: chatUpdate?.chatCreatedAt ?? meetup.createdAt,
              currentUserId: userId,
              isPast: isPast,
              isOrganizerOnlyMode: isOrganizerOnlyMode,
              onTap: () {
                // Clear unread count when navigating to chat
                chatService.clearUnreadCount(meetup.id, userId);

                context.push(
                  '/chat',
                  extra: {'chatId': meetup.id, 'title': meetup.title},
                );
              },
            );
          },
        );
      },
    );
  }
}
