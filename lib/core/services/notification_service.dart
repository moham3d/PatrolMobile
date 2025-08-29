import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification service for push notifications and local notifications
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._internal();
  
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  String? _fcmToken;
  
  /// Get FCM token
  String? get fcmToken => _fcmToken;
  
  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Request notification permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      announcement: false,
    );
    
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('Notification permission denied');
      return;
    }
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');
    
    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      print('FCM Token refreshed: $token');
      // TODO: Send updated token to backend
    });
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle message open when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    _isInitialized = true;
  }
  
  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );
  }
  
  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.messageId}');
    
    // Show local notification for foreground messages
    _showLocalNotification(
      title: message.notification?.title ?? 'PatrolShield',
      body: message.notification?.body ?? 'New notification',
      data: message.data,
    );
  }
  
  /// Handle message when app is opened from background
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.messageId}');
    _handleNotificationAction(message.data);
  }
  
  /// Handle notification action
  void _handleNotificationAction(Map<String, dynamic> data) {
    final type = data['type'];
    
    switch (type) {
      case 'emergency_alert':
        _handleEmergencyAlert(data);
        break;
      case 'patrol_assignment':
        _handlePatrolAssignment(data);
        break;
      case 'message':
        _handleMessage(data);
        break;
      default:
        print('Unknown notification type: $type');
    }
  }
  
  /// Handle emergency alert notification
  void _handleEmergencyAlert(Map<String, dynamic> data) {
    // TODO: Navigate to emergency screen or show emergency dialog
    print('Emergency alert notification: $data');
  }
  
  /// Handle patrol assignment notification
  void _handlePatrolAssignment(Map<String, dynamic> data) {
    // TODO: Navigate to patrol screen
    print('Patrol assignment notification: $data');
  }
  
  /// Handle message notification
  void _handleMessage(Map<String, dynamic> data) {
    // TODO: Navigate to messages screen
    print('Message notification: $data');
  }
  
  /// Handle local notification tap
  void _handleLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _handleNotificationAction(data);
    }
  }
  
  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? channelId,
    String? channelName,
    String? channelDescription,
    Priority priority = Priority.high,
    Importance importance = Importance.high,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    
    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'default',
      channelName ?? 'Default',
      channelDescription: channelDescription ?? 'Default notifications',
      priority: priority,
      importance: importance,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
    
    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: data != null ? json.encode(data) : null,
    );
  }
  
  /// Show emergency notification
  Future<void> showEmergencyNotification({
    required String title,
    required String body,
    required Map<String, dynamic> emergencyData,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      data: {
        'type': 'emergency_alert',
        ...emergencyData,
      },
      channelId: 'emergency',
      channelName: 'Emergency Alerts',
      channelDescription: 'Critical emergency notifications',
      priority: Priority.max,
      importance: Importance.max,
    );
  }
  
  /// Show patrol notification
  Future<void> showPatrolNotification({
    required String title,
    required String body,
    required Map<String, dynamic> patrolData,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      data: {
        'type': 'patrol_assignment',
        ...patrolData,
      },
      channelId: 'patrols',
      channelName: 'Patrol Assignments',
      channelDescription: 'Patrol assignment and updates',
    );
  }
  
  /// Show message notification
  Future<void> showMessageNotification({
    required String title,
    required String body,
    required Map<String, dynamic> messageData,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      data: {
        'type': 'message',
        ...messageData,
      },
      channelId: 'messages',
      channelName: 'Messages',
      channelDescription: 'In-app messages and communications',
    );
  }
  
  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
  
  /// Cancel notification by ID
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
  // Handle background message processing
}