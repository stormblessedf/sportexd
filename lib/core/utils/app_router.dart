import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/discovery/presentation/discovery_page.dart';
import '../../features/main/presentation/main_shell.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/create_profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/profile/presentation/rate_members_screen.dart';
import '../../features/profile/presentation/user_ratings_page.dart';
import '../../features/profile/presentation/select_meetup_screen.dart';
import '../../features/profile/presentation/rate_user_screen.dart';
import '../../features/profile/presentation/partner_list_screen.dart';
import '../../features/profile/presentation/partnership_requests_screen.dart';
import '../../features/meetups/presentation/create_meetup_screen.dart';
import '../../features/meetups/presentation/meetup_detail_screen.dart';
import '../../features/meetups/presentation/past_meetups_screen.dart';
import '../../features/meetups/presentation/nearby_meetups_map_screen.dart';
import '../../features/chat/presentation/my_chats_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/notifications/presentation/notification_settings_screen.dart';
import '../../features/profile/presentation/reliability_detail_screen.dart';
import '../../features/profile/presentation/user_meetups_screen.dart';
import '../../features/live_event/presentation/live_event_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../core/models/user_model.dart';
import '../../core/models/meetup_model.dart';
import '../../core/models/venue_model.dart';
import '../../core/models/eligible_meetup.dart';
import '../../core/utils/admin_actions.dart';

import '../../features/venue_recommendations/presentation/venue_onboarding_screen.dart';
import '../../features/venue_recommendations/presentation/venue_detail_screen.dart';
import '../../core/services/meetup_service.dart' as meetup_svc;

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    GoRoute(path: '/create-profile', builder: (context, state) => const CreateProfileScreen()),
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(navigationShell: child);
      },
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const DiscoveryPage()),
        GoRoute(path: '/chats', builder: (context, state) => const MyChatsScreen()),
        GoRoute(path: '/create', builder: (context, state) => const CreateMeetupScreen()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      ],
    ),
    GoRoute(
      path: '/detail',
      builder: (context, state) {
        final meetup = state.extra as MeetupModel?;
        if (meetup == null) {
          return const Scaffold(body: Center(child: Text('Buluşma bulunamadı')));
        }
        return MeetupDetailScreen(meetup: meetup);
      },
    ),
    GoRoute(
      path: '/meetup/:meetupId',
      builder: (context, state) {
        final meetupId = state.pathParameters['meetupId'];
        if (meetupId == null || meetupId.isEmpty) {
          return const Scaffold(body: Center(child: Text('Etkinlik bulunamadı')));
        }
        return _MeetupLoaderScreen(meetupId: meetupId);
      },
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          return const Scaffold(body: Center(child: Text('Sohbet bilgisi bulunamadı')));
        }
        return ChatScreen(
          chatId: extra['chatId'] ?? '',
          title: extra['title'] ?? 'Sohbet',
        );
      },
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) {
        final user = state.extra as UserModel?;
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Kullanıcı bulunamadı')));
        }
        return EditProfileScreen(user: user);
      },
    ),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(
      path: '/user-profile/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'];
        if (userId == null || userId.isEmpty) {
          return const Scaffold(body: Center(child: Text('Kullanıcı bulunamadı')));
        }
        return ProfileScreen(userId: userId);
      },
    ),
    GoRoute(path: '/nearby-map', builder: (context, state) => const NearbyMeetupsMapScreen()),
    GoRoute(
      path: '/past-meetups',
      builder: (context, state) {
        final userId = state.extra as String?;
        if (userId == null || userId.isEmpty) {
          return const Scaffold(body: Center(child: Text('Kullanıcı bilgisi bulunamadı')));
        }
        return PastMeetupsScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/rate-participants',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          return const Scaffold(body: Center(child: Text('Etkinlik bilgisi bulunamadı')));
        }
        return RateMembersScreen(
          meetupId: extra['meetupId'] ?? '',
          meetupTitle: extra['meetupTitle'] ?? 'Etkinlik',
          participantIds: List<String>.from(extra['participantIds'] ?? []),
        );
      },
    ),
    GoRoute(
      path: '/user-ratings/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'];
        if (userId == null || userId.isEmpty) {
          return const Scaffold(body: Center(child: Text('Kullanıcı bulunamadı')));
        }
        return UserRatingsPage(profileOwnerId: userId);
      },
    ),
    GoRoute(
      path: '/select-meetup',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final currentUserId = extra?['currentUserId'] as String?;
        final profileOwnerId = extra?['profileOwnerId'] as String?;
        if (extra == null || currentUserId == null || currentUserId.isEmpty ||
            profileOwnerId == null || profileOwnerId.isEmpty) {
          return const Scaffold(body: Center(child: Text('Kullanıcı bilgisi bulunamadı')));
        }
        return SelectMeetupScreen(
          currentUserId: currentUserId,
          profileOwnerId: profileOwnerId,
        );
      },
    ),
    GoRoute(
      path: '/rate-user',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          return const Scaffold(body: Center(child: Text('Bilgi bulunamadı')));
        }
        return RateUserScreen(
          currentUserId: extra['currentUserId'] ?? '',
          profileOwnerId: extra['profileOwnerId'] ?? '',
          meetup: extra['meetup'] as EligibleMeetup,
        );
      },
    ),
    GoRoute(path: '/admin-actions', builder: (context, state) => const AdminActionsScreen()),
    GoRoute(
      path: '/reliability-detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final userId = extra?['userId'] as String?;
        if (extra == null || userId == null || userId.isEmpty) {
          return const Scaffold(body: Center(child: Text('Bilgi bulunamadı')));
        }
        return ReliabilityDetailScreen(
          userId: userId,
          reliabilityScore: (extra['reliabilityScore'] as num?)?.toDouble() ?? 0.0,
        );
      },
    ),
    GoRoute(
      path: '/user-meetups/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'];
        if (userId == null || userId.isEmpty) {
          return const Scaffold(body: Center(child: Text('Kullanıcı bulunamadı')));
        }
        return UserMeetupsScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/user-statistics/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'];
        if (userId == null || userId.isEmpty) {
          return const Scaffold(body: Center(child: Text('Kullanıcı bulunamadı')));
        }
        return StatisticsScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/live-event/:meetupId',
      builder: (context, state) {
        final meetupId = state.pathParameters['meetupId'];
        if (meetupId == null || meetupId.isEmpty) {
          return const Scaffold(body: Center(child: Text('Etkinlik bulunamadı')));
        }
        return LiveEventScreen(meetupId: meetupId);
      },
    ),
    GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    GoRoute(path: '/notification-settings', builder: (context, state) => const NotificationSettingsScreen()),
    GoRoute(
      path: '/partners/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'];
        if (userId == null || userId.isEmpty) {
          return const Scaffold(body: Center(child: Text('Kullanıcı bulunamadı')));
        }
        return PartnerListScreen(userId: userId);
      },
    ),
    GoRoute(path: '/partnership-requests', builder: (context, state) => const PartnershipRequestsScreen()),
    GoRoute(
      path: '/venue-onboarding',
      builder: (context, state) => const VenueOnboardingScreen(),
    ),
    GoRoute(
      path: '/venue-detail/:placeId',
      builder: (context, state) {
        final placeId = state.pathParameters['placeId'];
        if (placeId == null || placeId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Mekan bulunamadı')),
          );
        }
        final extra = state.extra as Map<String, dynamic>?;
        final sportType = extra?['sportType'] as MeetupType?;
        final initialVenue = extra?['initialVenue'] as VenueModel?;
        final distanceKm = extra?['distanceKm'] as double?;
        return VenueDetailScreen(
          placeId: placeId,
          sportType: sportType,
          initialVenue: initialVenue,
          distanceKm: distanceKm,
        );
      },
    ),
  ],
);


class _MeetupLoaderScreen extends StatelessWidget {
  final String meetupId;
  const _MeetupLoaderScreen({required this.meetupId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MeetupModel?>(
      future: meetup_svc.MeetupService().getMeetup(meetupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final meetup = snapshot.data;
        if (meetup == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Etkinlik')),
            body: const Center(child: Text('Etkinlik bulunamadı')),
          );
        }
        return MeetupDetailScreen(meetup: meetup);
      },
    );
  }
}
