import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/notification_preferences.dart';
import 'auth_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // State
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _currentScreen;
  String? _currentRelatedId;

  // Stream controller for unread count
  final _unreadCountController = StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  StreamSubscription? _notificationSubscription;

  // Navigation callback
  Function(String route, Map<String, dynamic>? arguments)? onNavigate;

  // In-app banner callback
  Function(NotificationModel notification)? onShowBanner;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        await _updateFcmToken();

        // Listen for token refresh
        _fcm.onTokenRefresh.listen(_handleTokenRefresh);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background message tap
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Check for initial message (app opened from terminated state)
        final initialMessage = await _fcm.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }
      }

      // Start listening to notifications
      _startListeningToNotifications();

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Start listening to user's notifications
  void _startListeningToNotifications() {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    _notificationSubscription?.cancel();
    _notificationSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      _unreadCount = snapshot.docs.length;
      _unreadCountController.add(_unreadCount);
      notifyListeners();
    });
  }

  /// Update FCM token in Firestore
  Future<void> _updateFcmToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      final userId = _authService.currentUserId;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      debugPrint('FCM token updated: $token');
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Handle FCM token refresh
  void _handleTokenRefresh(String token) async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
      debugPrint('FCM token refreshed: $token');
    } catch (e) {
      debugPrint('Error refreshing FCM token: $e');
    }
  }

  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.messageId}');

    final data = message.data;
    final type = data['type'] ?? 'system';
    final relatedId = data['relatedId'] ?? '';

    // Check if user is on the relevant screen
    if (_isOnRelevantScreen(type, relatedId)) {
      debugPrint('User is on relevant screen, not showing banner');
      return;
    }

    // Create notification from message
    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _authService.currentUserId ?? '',
      type: NotificationTypeExtension.fromFirestore(type),
      title: message.notification?.title ?? data['title'] ?? '',
      message: message.notification?.body ?? data['message'] ?? '',
      timestamp: DateTime.now(),
      isRead: false,
      relatedId: relatedId,
      metadata: data,
    );

    // Show in-app banner
    onShowBanner?.call(notification);
  }

  /// Handle message opened from background/terminated
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');

    final data = message.data;
    final type = data['type'] ?? 'system';
    final relatedId = data['relatedId'] ?? '';

    // Navigate to relevant screen
    final route = _getRouteForNotificationType(type, relatedId);
    onNavigate?.call(route, {'relatedId': relatedId});
  }

  /// Check if user is on relevant screen
  bool _isOnRelevantScreen(String type, String relatedId) {
    if (_currentRelatedId != relatedId) return false;

    if (type == 'chat_message' && _currentScreen == 'chat') {
      return true;
    }
    if ((type == 'meetup_reminder' || type == 'meetup_update') &&
        _currentScreen == 'meetup_detail') {
      return true;
    }

    return false;
  }

  /// Get route for notification type
  String _getRouteForNotificationType(String type, String relatedId) {
    switch (type) {
      case 'chat_message':
        return '/chat/$relatedId';
      case 'meetup_reminder':
      case 'meetup_update':
      case 'meetup_cancelled':
      case 'new_participant':
      case 'capacity_reached':
        return '/detail';
      case 'partnership_request':
      case 'partnership_accepted':
      case 'partnership_rejected':
        return '/partnership-requests';
      case 'partnership_suggestion':
        return '/notifications';
      default:
        return '/notifications';
    }
  }

  /// Set current screen for context awareness
  void setCurrentScreen(String screen, [String? relatedId]) {
    _currentScreen = screen;
    _currentRelatedId = relatedId;
  }

  /// Get notifications stream for current user
  Stream<List<NotificationModel>> getNotifications() {
    final userId = _authService.currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    // Use simple query without orderBy to avoid index requirement
    // Sort locally instead
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      // Sort locally by timestamp descending
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notifications;
    });
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();
      final unreadDocs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      debugPrint('Marked ${unreadDocs.docs.length} notifications as read');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Create a local notification (for testing or manual triggers)
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    required String relatedId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': type.firestoreValue,
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'relatedId': relatedId,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Get user's notification preferences
  Future<NotificationPreferences> getPreferences() async {
    final userId = _authService.currentUserId;
    if (userId == null) return NotificationPreferences();

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return NotificationPreferences();

      final data = doc.data();
      return NotificationPreferences.fromFirestore(
        data?['notificationPreferences'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('Error getting notification preferences: $e');
      return NotificationPreferences();
    }
  }

  /// Update user's notification preferences
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).set({
        'notificationPreferences': preferences.toFirestore(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
    }
  }

  /// Get badge text for unread count
  static String? getBadgeText(int count) {
    if (count == 0) return null;
    if (count < 10) return count.toString();
    return '9+';
  }

  /// Get message preview (truncated to 50 chars)
  static String getMessagePreview(String message) {
    if (message.length <= 50) return message;
    return '${message.substring(0, 47)}...';
  }

  /// Navigate to notification
  void navigateToNotification(NotificationModel notification) {
    final route = _getRouteForNotificationType(
      notification.type.firestoreValue,
      notification.relatedId,
    );
    onNavigate?.call(route, {
      'relatedId': notification.relatedId,
      'notification': notification,
    });
  }

  /// Refresh notifications after user login
  void onUserLogin() {
    _startListeningToNotifications();
    _updateFcmToken();
  }

  /// Clean up on user logout
  void onUserLogout() {
    _notificationSubscription?.cancel();
    _unreadCount = 0;
    _unreadCountController.add(0);
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _unreadCountController.close();
    super.dispose();
  }
}
