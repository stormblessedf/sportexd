import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/discovery/presentation/discovery_page.dart';
import 'features/main/presentation/main_shell.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/profile/presentation/edit_profile_screen.dart';
import 'features/profile/presentation/create_profile_screen.dart';
import 'features/profile/presentation/settings_screen.dart';
import 'features/profile/presentation/rate_members_screen.dart';
import 'features/profile/presentation/user_ratings_page.dart';
import 'features/profile/presentation/select_meetup_screen.dart';
import 'features/profile/presentation/rate_user_screen.dart';
import 'features/profile/presentation/partner_list_screen.dart';
import 'features/profile/presentation/partnership_requests_screen.dart';
import 'core/services/partnership_service.dart';
import 'core/services/messaging_permission_service.dart';
import 'features/meetups/presentation/create_meetup_screen.dart';
import 'features/meetups/presentation/meetup_detail_screen.dart';
import 'features/meetups/presentation/past_meetups_screen.dart';
import 'features/meetups/presentation/event_evaluation_screen.dart';
import 'features/chat/presentation/my_chats_screen.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'core/models/user_model.dart';
import 'core/models/meetup_model.dart';
import 'core/models/eligible_meetup.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/meetup_service.dart';
import 'core/services/location_service.dart';
import 'core/services/presence_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/map_preferences_service.dart';
import 'features/meetups/presentation/nearby_meetups_map_screen.dart';
import 'features/notifications/presentation/notifications_screen.dart';
import 'features/notifications/presentation/notification_settings_screen.dart';
import 'core/utils/admin_actions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Attempt to initialize Firebase.
    // If firebase_options.dart is not configured, this might fail or show the stub error.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // For now, correct behavior if not configured is just log it,
    // maybe we can continue to run the UI for testing purposes.
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    DevicePreview(
      enabled: kIsWeb, // Only enable on web
      builder: (context) => const SporsalApp(),
    ),
  );
}

final _router = GoRouter(
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
        GoRoute(
          path: '/chats',
          builder: (context, state) => const MyChatsScreen(),
        ),
        GoRoute(
          path: '/create',
          builder: (context, state) => const CreateMeetupScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/detail',
      builder: (context, state) {
        final meetup = state.extra as MeetupModel?;
        if (meetup == null) {
          return const Scaffold(
            body: Center(child: Text('Buluşma bulunamadı')),
          );
        }
        return MeetupDetailScreen(meetup: meetup);
      },
    ),
    GoRoute(
      path: '/evaluate-event',
      builder: (context, state) {
        final meetup = state.extra as MeetupModel?;
        if (meetup == null) {
          return const Scaffold(
            body: Center(child: Text('Etkinlik bulunamadı')),
          );
        }
        return EventEvaluationScreen(meetup: meetup);
      },
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          return const Scaffold(
            body: Center(child: Text('Sohbet bilgisi bulunamadı')),
          );
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
          return const Scaffold(
            body: Center(child: Text('Kullanıcı bulunamadı')),
          );
        }
        return EditProfileScreen(user: user);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/user-profile/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'];
        if (userId == null || userId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Kullanıcı bulunamadı')),
          );
        }
        return ProfileScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/nearby-map',
      builder: (context, state) => const NearbyMeetupsMapScreen(),
    ),
    GoRoute(
      path: '/past-meetups',
      builder: (context, state) {
        final userId = state.extra as String?;
        if (userId == null || userId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Kullanıcı bilgisi bulunamadı')),
          );
        }
        return PastMeetupsScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/rate-participants',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          return const Scaffold(
            body: Center(child: Text('Etkinlik bilgisi bulunamadı')),
          );
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
          return const Scaffold(
            body: Center(child: Text('Kullanıcı bulunamadı')),
          );
        }
        return UserRatingsPage(profileOwnerId: userId);
      },
    ),
    GoRoute(
      path: '/select-meetup',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          return const Scaffold(
            body: Center(child: Text('Kullanıcı bilgisi bulunamadı')),
          );
        }
        return SelectMeetupScreen(
          currentUserId: extra['currentUserId'] ?? '',
          profileOwnerId: extra['profileOwnerId'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/rate-user',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          return const Scaffold(
            body: Center(child: Text('Bilgi bulunamadı')),
          );
        }
        return RateUserScreen(
          currentUserId: extra['currentUserId'] ?? '',
          profileOwnerId: extra['profileOwnerId'] ?? '',
          meetup: extra['meetup'] as EligibleMeetup,
        );
      },
    ),
    GoRoute(
      path: '/admin-actions',
      builder: (context, state) => const AdminActionsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/notification-settings',
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/partners/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'];
        if (userId == null || userId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Kullanıcı bulunamadı')),
          );
        }
        return PartnerListScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/partnership-requests',
      builder: (context, state) => const PartnershipRequestsScreen(),
    ),
  ],
);

class SporsalApp extends StatefulWidget {
  const SporsalApp({super.key});

  @override
  State<SporsalApp> createState() => _SporsalAppState();
}

class _SporsalAppState extends State<SporsalApp> with WidgetsBindingObserver {
  final PresenceService _presenceService = PresenceService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final MapPreferencesService _mapPreferencesService = MapPreferencesService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePresence();
    _initializeNotifications();
    _mapPreferencesService.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceService.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  Future<void> _initializePresence() async {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        _currentUserId = user.uid;
        _presenceService.startPresenceUpdates(user.uid);
        _notificationService.onUserLogin();
      } else {
        if (_currentUserId != null) {
          _presenceService.stopPresenceUpdates(_currentUserId!);
          _notificationService.onUserLogout();
          _currentUserId = null;
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUserId == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        _presenceService.setUserOnline(_currentUserId!);
        _presenceService.startPresenceUpdates(_currentUserId!);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App went to background or closed
        _presenceService.setUserOffline(_currentUserId!);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: _authService),
        Provider<MeetupService>(create: (_) => MeetupService()),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<PresenceService>.value(value: _presenceService),
        Provider<PartnershipService>(create: (_) => PartnershipService()),
        Provider<MessagingPermissionService>(create: (_) => MessagingPermissionService()),
        ChangeNotifierProvider<NotificationService>.value(value: _notificationService),
        ChangeNotifierProvider<MapPreferencesService>.value(value: _mapPreferencesService),
      ],
      child: MaterialApp.router(
        title: 'Sporsal',
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // Light theme as per HTML design
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
