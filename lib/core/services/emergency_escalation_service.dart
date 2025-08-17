import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';
import '../models/emergency.dart';
import '../services/emergency_service.dart';
import '../services/websocket_service.dart';

/// Emergency escalation service for automatic alert escalation
class EmergencyEscalationService {
  static EmergencyEscalationService? _instance;
  static EmergencyEscalationService get instance => _instance ??= EmergencyEscalationService._internal();
  
  EmergencyEscalationService._internal();

  final Map<int, Timer> _escalationTimers = {};
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the escalation service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize local notifications
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
    
    await _notificationsPlugin.initialize(initializationSettings);
    _isInitialized = true;
    
    print('Emergency escalation service initialized');
  }

  /// Start escalation timer for an emergency alert
  void startEscalation(EmergencyAlert alert) {
    final alertId = alert.id;
    
    // Cancel any existing timer for this alert
    cancelEscalation(alertId);
    
    print('Starting escalation timer for alert #$alertId (${AppConstants.emergencyEscalationMinutes} minutes)');
    
    // Start escalation timer
    _escalationTimers[alertId] = Timer(
      Duration(minutes: AppConstants.emergencyEscalationMinutes),
      () => _escalateAlert(alert),
    );
  }

  /// Cancel escalation for an alert
  void cancelEscalation(int alertId) {
    final timer = _escalationTimers.remove(alertId);
    if (timer != null) {
      timer.cancel();
      print('Cancelled escalation for alert #$alertId');
    }
  }

  /// Check if alert has an active escalation timer
  bool hasActiveEscalation(int alertId) {
    return _escalationTimers.containsKey(alertId);
  }

  /// Get remaining escalation time for an alert
  Duration? getRemainingEscalationTime(int alertId) {
    // Note: Timer doesn't provide remaining time directly
    // In a real implementation, you would track start time and calculate remaining time
    return _escalationTimers.containsKey(alertId) 
        ? Duration(minutes: AppConstants.emergencyEscalationMinutes)
        : null;
  }

  /// Escalate an emergency alert
  Future<void> _escalateAlert(EmergencyAlert alert) async {
    print('Escalating emergency alert #${alert.id}');
    
    try {
      // Remove from active timers
      _escalationTimers.remove(alert.id);
      
      // Send escalated notification to higher-level personnel
      await _sendEscalationNotification(alert);
      
      // Trigger emergency contacts
      await _contactEmergencyServices(alert);
      
      // Broadcast escalation via WebSocket
      _broadcastEscalation(alert);
      
      // Show local notification
      await _showEscalationNotification(alert);
      
      print('Emergency alert #${alert.id} escalated successfully');
      
    } catch (e) {
      print('Failed to escalate emergency alert #${alert.id}: $e');
    }
  }

  /// Send escalation notification to supervisors/managers
  Future<void> _sendEscalationNotification(EmergencyAlert alert) async {
    try {
      // In a real implementation, this would send notifications to:
      // - Direct supervisors
      // - Site managers
      // - Emergency response team
      // - External emergency services (if configured)
      
      print('Sending escalation notifications for alert #${alert.id}');
      
      // Example: Send to emergency service API
      // await EmergencyService.instance.escalateAlert(alert.id);
      
    } catch (e) {
      print('Failed to send escalation notification: $e');
    }
  }

  /// Contact emergency services
  Future<void> _contactEmergencyServices(EmergencyAlert alert) async {
    try {
      // In a real implementation, this could:
      // - Send SMS to emergency contacts
      // - Call emergency services automatically
      // - Send email notifications
      // - Integrate with third-party emergency services
      
      print('Contacting emergency services for alert #${alert.id}');
      
      // Example escalation actions:
      final escalationData = {
        'alert_id': alert.id,
        'escalation_type': 'automatic',
        'escalation_time': DateTime.now().toIso8601String(),
        'escalation_reason': 'No response after ${AppConstants.emergencyEscalationMinutes} minutes',
        'original_alert': {
          'severity': alert.severity,
          'description': alert.description,
          'location': alert.location != null ? {
            'latitude': alert.location!.latitude,
            'longitude': alert.location!.longitude,
            'name': alert.location!.locationName,
          } : null,
        },
      };
      
      // Send escalation to backend
      // await ApiService.instance.post('/emergency/escalate', data: escalationData);
      
    } catch (e) {
      print('Failed to contact emergency services: $e');
    }
  }

  /// Broadcast escalation via WebSocket
  void _broadcastEscalation(EmergencyAlert alert) {
    try {
      // Broadcast escalation to all connected users
      final escalationMessage = {
        'type': 'emergency_escalation',
        'alert_id': alert.id,
        'escalated_at': DateTime.now().toIso8601String(),
        'escalation_level': _getNextEscalationLevel(alert.severity),
        'requires_immediate_attention': true,
      };
      
      // Send via WebSocket
      // WebSocketService.instance.sendMessage(escalationMessage);
      print('Broadcasting escalation for alert #${alert.id}');
      
    } catch (e) {
      print('Failed to broadcast escalation: $e');
    }
  }

  /// Show local notification for escalation
  Future<void> _showEscalationNotification(EmergencyAlert alert) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'emergency_escalation',
        'Emergency Escalations',
        channelDescription: 'Critical emergency alert escalations',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        ongoing: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      );
      
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notificationsPlugin.show(
        alert.id + 1000, // Offset ID for escalations
        '🚨 EMERGENCY ESCALATED',
        'Alert #${alert.id} has been escalated - Immediate attention required',
        notificationDetails,
        payload: 'emergency_escalation:${alert.id}',
      );
      
    } catch (e) {
      print('Failed to show escalation notification: $e');
    }
  }

  /// Get the next escalation level based on current severity
  String _getNextEscalationLevel(String currentSeverity) {
    switch (currentSeverity.toLowerCase()) {
      case 'low':
        return 'medium';
      case 'medium':
        return 'high';
      case 'high':
        return 'critical';
      case 'critical':
        return 'maximum';
      default:
        return 'critical';
    }
  }

  /// Get emergency contact information
  List<EmergencyContact> getEmergencyContacts() {
    // In a real implementation, this would be fetched from:
    // - User preferences
    // - Organization settings
    // - Site-specific emergency contacts
    
    return [
      const EmergencyContact(
        name: 'Site Security',
        phone: '+1-555-0101',
        type: 'security',
      ),
      const EmergencyContact(
        name: 'Emergency Services',
        phone: '911',
        type: 'emergency',
      ),
      const EmergencyContact(
        name: 'Site Manager',
        phone: '+1-555-0102',
        type: 'management',
      ),
    ];
  }

  /// Dispose resources
  void dispose() {
    // Cancel all active timers
    for (final timer in _escalationTimers.values) {
      timer.cancel();
    }
    _escalationTimers.clear();
    print('Emergency escalation service disposed');
  }
}

/// Emergency contact model
class EmergencyContact {
  final String name;
  final String phone;
  final String type;
  final String? email;

  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.type,
    this.email,
  });

  @override
  String toString() => 'EmergencyContact(name: $name, phone: $phone, type: $type)';
}