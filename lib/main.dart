import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/meetup_service.dart';
import 'core/services/location_service.dart';
import 'core/services/presence_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/map_preferences_service.dart';
import 'core/services/proximity_attendance_service.dart';
import 'core/services/location_tracking_service.dart';
import 'core/services/reliability_service.dart';
import 'core/services/partnership_service.dart';
import 'core/services/messaging_permission_service.dart';
import 'core/services/event_photo_service.dart';
import 'core/services/meetup_participation_service.dart';
import 'core/utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    DevicePreview(
      enabled: kIsWeb,
      builder: (context) => const SporsalApp(),
    ),
  );
}

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
  final ProximityAttendanceService _proximityAttendanceService = ProximityAttendanceService();
  final LocationTrackingService _locationTrackingService = LocationTrackingService();
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
    _notificationService.onNavigate = null;
    _presenceService.dispose();
    _locationTrackingService.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    _notificationService.onNavigate = (route, arguments) {
      _handleNotificationNavigation(route, arguments);
    };
    await _notificationService.initialize();
  }

  Future<void> _handleNotificationNavigation(
    String route,
    Map<String, dynamic>? arguments,
  ) async {
    if (_authService.currentUserId == null) {
      appRouter.go('/login');
      return;
    }

    final relatedId = arguments?['relatedId'] as String? ?? '';

    if (route == '/chat') {
      if (relatedId.isEmpty) {
        appRouter.go('/notifications');
        return;
      }
      final title = arguments?['title'] as String? ?? 'Sohbet';
      appRouter.push('/chat', extra: {'chatId': relatedId, 'title': title});
      return;
    }

    if (route == '/detail') {
      if (relatedId.isEmpty) {
        appRouter.go('/notifications');
        return;
      }
      try {
        final meetup = await MeetupService().getMeetupById(relatedId);
        if (meetup != null) {
          appRouter.push('/detail', extra: meetup);
        } else {
          appRouter.go('/notifications');
        }
      } catch (e) {
        debugPrint('Error resolving meetup from notification: $e');
        appRouter.go('/notifications');
      }
      return;
    }

    appRouter.go(route);
  }

  Future<void> _initializePresence() async {
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        _currentUserId = user.uid;
        _presenceService.startPresenceUpdates(user.uid);
        _notificationService.onUserLogin();
        Future.delayed(const Duration(milliseconds: 500), () {
          _startLocationTracking();
        });
      } else {
        if (_currentUserId != null) {
          _presenceService.stopPresenceUpdates(_currentUserId!);
          _notificationService.onUserLogout();
          _locationTrackingService.resetTrackingState();
          _currentUserId = null;
        }
      }
    });
  }

  Future<void> _startLocationTracking() async {
    if (_currentUserId == null) return;
    try {
      await _proximityAttendanceService.processCutoffForActiveMeetups(_currentUserId!);
      final activeMeetups = await _locationTrackingService.getActiveMeetups(_currentUserId!);
      if (activeMeetups.isNotEmpty) {
        await _locationTrackingService.startTracking(
          userId: _currentUserId!,
          activeMeetups: activeMeetups,
        );
      }
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUserId == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _presenceService.setUserOnline(_currentUserId!);
        _presenceService.startPresenceUpdates(_currentUserId!);
        _startLocationTracking();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _presenceService.setUserOffline(_currentUserId!);
        _locationTrackingService.stopTracking();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: _authService),
        Provider<MeetupService>(create: (_) => MeetupService()),
        Provider<MeetupParticipationService>(create: (_) => MeetupParticipationService()),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<PresenceService>.value(value: _presenceService),
        Provider<PartnershipService>(create: (_) => PartnershipService()),
        Provider<MessagingPermissionService>(create: (_) => MessagingPermissionService()),
        Provider<ProximityAttendanceService>.value(value: _proximityAttendanceService),
        Provider<LocationTrackingService>.value(value: _locationTrackingService),
        Provider<ReliabilityService>(create: (_) => ReliabilityService()),
        ProxyProvider<MeetupService, EventPhotoService>(
          update: (_, meetupService, __) => EventPhotoService(meetupService: meetupService),
        ),
        ChangeNotifierProvider<NotificationService>.value(value: _notificationService),
        ChangeNotifierProvider<MapPreferencesService>.value(value: _mapPreferencesService),
      ],
      child: MaterialApp.router(
        title: 'Sporsal',
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr'),
          Locale('en'),
        ],
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
