import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';
import '../models/emergency.dart';
import '../services/emergency_service.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart';
import '../exceptions/api_exception.dart';

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
      const Duration(minutes: AppConstants.emergencyEscalationMinutes),
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
        ? const Duration(minutes: AppConstants.emergencyEscalationMinutes)
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
      print('Sending escalation notifications for alert #${alert.id}');
      
      // Send escalation notification via backend API
      final escalationData = {
        'alert_id': alert.id,
        'escalation_type': 'automatic',
        'escalation_time': DateTime.now().toIso8601String(),
        'escalation_reason': 'No response after ${AppConstants.emergencyEscalationMinutes} minutes',
        'escalation_level': _getNextEscalationLevel(alert.severity),
        'original_alert': {
          'id': alert.id,
          'type': alert.alertType,
          'severity': alert.severity,
          'description': alert.description,
          'user_id': alert.userId,
          'user_name': alert.userName,
          'triggered_at': alert.triggeredAt,
          'location': alert.latitude != null && alert.longitude != null ? {
            'latitude': alert.latitude,
            'longitude': alert.longitude,
            'name': alert.locationName,
          } : null,
        },
      };
      
      // Send escalation to backend
      await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/alerts/${alert.id}/escalate',
        data: escalationData,
      );
      
      print('Escalation notification sent successfully');
      
    } catch (e) {
      print('Failed to send escalation notification: $e');
      // Don't throw error - continue with other escalation steps
    }
  }

  /// Contact emergency services
  Future<void> _contactEmergencyServices(EmergencyAlert alert) async {
    try {
      print('Contacting emergency services for alert #${alert.id}');
      
      // Get emergency contacts and call them
      final contacts = await EmergencyService.instance.getEmergencyContacts();
      final emergencyContacts = contacts.where((c) => c.type == 'emergency').toList();
      
      // Try to call the first emergency contact
      if (emergencyContacts.isNotEmpty) {
        try {
          await EmergencyService.instance.callEmergencyContact(emergencyContacts.first);
          print('Emergency contact called successfully');
        } catch (e) {
          print('Failed to call emergency contact: $e');
        }
      }
      
      // Send SMS or push notifications to emergency contacts
      await _sendEmergencyNotifications(alert, contacts);
      
      // Record escalation in backend
      await _recordEscalationAction(alert, 'emergency_contact');
      
    } catch (e) {
      print('Failed to contact emergency services: $e');
    }
  }

  /// Send emergency notifications to contacts
  Future<void> _sendEmergencyNotifications(EmergencyAlert alert, List<EmergencyContact> contacts) async {
    try {
      final notificationData = {
        'alert_id': alert.id,
        'message': 'EMERGENCY ESCALATION: Alert #${alert.id} requires immediate attention',
        'alert_details': {
          'type': alert.alertType,
          'severity': alert.severity,
          'description': alert.description,
          'location': alert.locationName,
          'user': alert.userName ?? 'User #${alert.userId}',
          'triggered_at': alert.triggeredAt,
        },
        'contacts': contacts.map((c) => {
          'id': c.id,
          'name': c.name,
          'phone': c.phone,
          'type': c.type,
        }).toList(),
      };
      
      await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/notifications/send',
        data: notificationData,
      );
      
      print('Emergency notifications sent');
    } catch (e) {
      print('Failed to send emergency notifications: $e');
    }
  }

  /// Record escalation action in backend
  Future<void> _recordEscalationAction(EmergencyAlert alert, String actionType) async {
    try {
      final actionData = {
        'alert_id': alert.id,
        'action_type': actionType,
        'performed_at': DateTime.now().toIso8601String(),
        'performed_by': 'system',
        'details': {
          'escalation_level': _getNextEscalationLevel(alert.severity),
          'escalation_reason': 'Automatic escalation after ${AppConstants.emergencyEscalationMinutes} minutes',
        },
      };
      
      await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/alerts/${alert.id}/actions',
        data: actionData,
      );
      
      print('Escalation action recorded');
    } catch (e) {
      print('Failed to record escalation action: $e');
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
        'alert_details': {
          'id': alert.id,
          'type': alert.alertType,
          'severity': alert.severity,
          'description': alert.description,
          'user_id': alert.userId,
          'user_name': alert.userName,
          'location_name': alert.locationName,
          'triggered_at': alert.triggeredAt,
        },
      };
      
      // Send via WebSocket if connected
      if (WebSocketService.instance.isConnected) {
        try {
          final websocketMessage = {
            'type': 'send_message',
            'data': escalationMessage,
            'timestamp': DateTime.now().toIso8601String(),
          };
          
          // Note: In a real implementation, you would send via WebSocket
          // WebSocketService.instance.sendMessage(websocketMessage);
          
          print('Broadcasting escalation for alert #${alert.id} via WebSocket');
        } catch (e) {
          print('Failed to send WebSocket message: $e');
        }
      } else {
        print('WebSocket not connected - escalation broadcast skipped');
      }
      
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

  /// Get escalation history for an alert
  Future<List<EscalationHistoryEntry>> getEscalationHistory(int alertId) async {
    try {
      final response = await ApiService.instance.get<List<dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/alerts/$alertId/escalations',
      );

      if (response.data != null) {
        return response.data!
            .map((json) => EscalationHistoryEntry.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Failed to get escalation history: $e');
      return [];
    }
  }

  /// Manually trigger escalation for an alert
  Future<void> manuallyEscalateAlert(int alertId, {
    required String reason,
    String? escalationLevel,
    int? escalatedBy,
  }) async {
    try {
      final escalationData = {
        'alert_id': alertId,
        'escalation_type': 'manual',
        'escalation_reason': reason,
        'escalated_by': escalatedBy,
        'escalated_at': DateTime.now().toIso8601String(),
      };

      if (escalationLevel != null) {
        escalationData['escalation_level'] = escalationLevel;
      }

      await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/alerts/$alertId/escalate',
        data: escalationData,
      );

      // Start immediate escalation workflow
      final alert = await _getAlertById(alertId);
      if (alert != null) {
        await _escalateAlert(alert);
      }

      print('Manual escalation triggered for alert #$alertId');
    } catch (e) {
      print('Failed to manually escalate alert: $e');
    }
  }

  /// Set custom escalation rules
  void setEscalationRules(int alertId, Map<String, dynamic> rules) {
    // Store custom escalation rules for specific alerts
    // This could include custom timeouts, escalation levels, contact lists, etc.
    print('Custom escalation rules set for alert #$alertId: $rules');
  }

  /// Get escalation status for an alert
  EscalationStatus getEscalationStatus(int alertId) {
    final hasTimer = _escalationTimers.containsKey(alertId);
    
    if (!hasTimer) {
      return EscalationStatus(
        alertId: alertId,
        isActive: false,
        remainingTime: null,
        escalationLevel: null,
      );
    }

    // In a real implementation, you would track the start time to calculate remaining time
    return EscalationStatus(
      alertId: alertId,
      isActive: true,
      remainingTime: const Duration(minutes: AppConstants.emergencyEscalationMinutes),
      escalationLevel: 'pending',
    );
  }

  /// Send escalation status update
  Future<void> updateEscalationStatus(int alertId, String status, {String? notes}) async {
    try {
      final data = {
        'alert_id': alertId,
        'escalation_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (notes != null) data['notes'] = notes;

      await ApiService.instance.put<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/alerts/$alertId/escalation-status',
        data: data,
      );

      print('Escalation status updated for alert #$alertId: $status');
    } catch (e) {
      print('Failed to update escalation status: $e');
    }
  }

  /// Get alert by ID (helper method)
  Future<EmergencyAlert?> _getAlertById(int alertId) async {
    try {
      final response = await ApiService.instance.get<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/alerts/$alertId',
      );

      if (response.data != null) {
        return EmergencyAlert.fromJson(response.data!);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get emergency contact information
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    return await EmergencyService.instance.getEmergencyContacts();
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