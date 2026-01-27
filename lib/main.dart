import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/main/presentation/main_shell.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/profile/presentation/edit_profile_screen.dart';
import 'features/meetups/presentation/create_meetup_screen.dart';
import 'features/meetups/presentation/meetup_detail_screen.dart';
import 'features/chat/presentation/my_chats_screen.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'core/models/user_model.dart';
import 'core/models/meetup_model.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/meetup_service.dart';

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
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(navigationShell: child);
      },
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
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
        final meetup = state.extra as MeetupModel;
        return MeetupDetailScreen(meetup: meetup);
      },
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ChatScreen(
          chatId: extra['chatId'],
          title: extra['title'],
        );
      },
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) {
        final user = state.extra as UserModel;
        return EditProfileScreen(user: user);
      },
    ),
  ],
);

class SporsalApp extends StatelessWidget {
  const SporsalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<MeetupService>(create: (_) => MeetupService()),
      ],
      child: MaterialApp.router(
        title: 'Sporsal',
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Start with dark mode for that premium feel
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
