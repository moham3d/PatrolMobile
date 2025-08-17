import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../models/emergency.dart';
import '../exceptions/api_exception.dart';
import 'api_service.dart';
import 'emergency_service.dart';
import 'emergency_escalation_service.dart';

/// Enhanced emergency response service for advanced emergency management
class EmergencyResponseService {
  static EmergencyResponseService? _instance;
  static EmergencyResponseService get instance => _instance ??= EmergencyResponseService._internal();
  
  EmergencyResponseService._internal();

  final Map<int, DateTime> _responseStartTimes = {};
  final Map<int, List<EmergencyResponseAction>> _responseActions = {};

  /// Start emergency response tracking
  void startResponse(EmergencyAlert alert) {
    _responseStartTimes[alert.id] = DateTime.now();
    _responseActions[alert.id] = [];
    
    print('Started emergency response tracking for alert #${alert.id}');
  }

  /// Record response action
  void recordResponseAction(int alertId, String actionType, String description, {int? userId}) {
    final action = EmergencyResponseAction(
      id: DateTime.now().millisecondsSinceEpoch,
      alertId: alertId,
      actionType: actionType,
      description: description,
      performedBy: userId,
      performedAt: DateTime.now().toIso8601String(),
    );

    _responseActions[alertId]?.add(action);
    print('Recorded response action for alert #$alertId: $actionType');
  }

  /// Get response time for an alert
  Duration? getResponseTime(int alertId) {
    final startTime = _responseStartTimes[alertId];
    if (startTime == null) return null;
    
    return DateTime.now().difference(startTime);
  }

  /// Get response actions for an alert
  List<EmergencyResponseAction> getResponseActions(int alertId) {
    return _responseActions[alertId] ?? [];
  }

  /// Enhanced acknowledge alert with response tracking
  Future<void> acknowledgeAlertEnhanced(int alertId, {
    String? acknowledgmentNote,
    int? responderId,
  }) async {
    try {
      // Start response tracking
      final alert = await _getAlertById(alertId);
      if (alert != null) {
        startResponse(alert);
      }

      final data = <String, dynamic>{};
      if (acknowledgmentNote != null) data['acknowledgment_note'] = acknowledgmentNote;
      if (responderId != null) data['responder_id'] = responderId;
      
      await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/alerts/$alertId/acknowledge',
        data: data.isNotEmpty ? data : null,
      );

      // Record the acknowledgment action
      recordResponseAction(alertId, 'acknowledge', acknowledgmentNote ?? 'Alert acknowledged', userId: responderId);
      
      // Cancel escalation
      EmergencyEscalationService.instance.cancelEscalation(alertId);
      
      print('Alert #$alertId acknowledged with enhanced tracking');
    } on DioException catch (e) {
      throw EmergencyException(
        message: ApiException.fromDioError(e).message,
        statusCode: e.response?.statusCode,
        code: 'ACKNOWLEDGE_ERROR',
      );
    }
  }

  /// Enhanced resolve alert with comprehensive resolution data
  Future<void> resolveAlertEnhanced(int alertId, {
    required String resolutionType,
    String? resolutionNotes,
    int? resolverId,
    List<String>? followUpActions,
    Map<String, dynamic>? resolutionData,
  }) async {
    try {
      final data = <String, dynamic>{
        'resolution_type': resolutionType,
        'status': 'resolved',
      };
      
      if (resolutionNotes != null) data['resolution_notes'] = resolutionNotes;
      if (resolverId != null) data['resolver_id'] = resolverId;
      if (followUpActions != null && followUpActions.isNotEmpty) {
        data['follow_up_actions'] = followUpActions;
      }
      if (resolutionData != null) data['resolution_data'] = resolutionData;

      await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/alerts/$alertId/resolve',
        data: data,
      );

      // Record the resolution action
      recordResponseAction(alertId, 'resolve', 'Alert resolved: $resolutionType', userId: resolverId);
      
      // Cancel escalation
      EmergencyEscalationService.instance.cancelEscalation(alertId);
      
      // Calculate and log response time
      final responseTime = getResponseTime(alertId);
      if (responseTime != null) {
        await _logResponseMetrics(alertId, responseTime);
      }
      
      print('Alert #$alertId resolved with enhanced data');
    } on DioException catch (e) {
      throw EmergencyException(
        message: ApiException.fromDioError(e).message,
        statusCode: e.response?.statusCode,
        code: 'RESOLVE_ERROR',
      );
    }
  }

  /// Manual escalation trigger
  Future<void> escalateAlert(int alertId, {
    required String escalationReason,
    String? escalationLevel,
    int? escalatedBy,
  }) async {
    try {
      final data = <String, dynamic>{
        'escalation_reason': escalationReason,
        'escalated_by': escalatedBy,
        'escalation_type': 'manual',
      };
      
      if (escalationLevel != null) data['escalation_level'] = escalationLevel;

      await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/alerts/$alertId/escalate',
        data: data,
      );

      // Record the escalation action
      recordResponseAction(alertId, 'escalate', 'Manual escalation: $escalationReason', userId: escalatedBy);
      
      print('Alert #$alertId manually escalated');
    } on DioException catch (e) {
      throw EmergencyException(
        message: ApiException.fromDioError(e).message,
        statusCode: e.response?.statusCode,
        code: 'ESCALATION_ERROR',
      );
    }
  }

  /// Get emergency contacts with enhanced functionality
  Future<List<EmergencyContact>> getEmergencyContactsEnhanced({
    String? contactType,
    bool activeOnly = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (contactType != null) queryParams['type'] = contactType;
      if (activeOnly) queryParams['active'] = 'true';

      final response = await ApiService.instance.get<List<dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/contacts',
        queryParameters: queryParams,
      );

      if (response.data == null) {
        return EmergencyService.instance.getEmergencyContacts();
      }

      return response.data!
          .map((json) => EmergencyContact.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to basic emergency contacts
      return EmergencyService.instance.getEmergencyContacts();
    }
  }

  /// Test emergency contact connectivity
  Future<ContactTestResult> testEmergencyContact(EmergencyContact contact) async {
    try {
      final data = <String, dynamic>{
        'contact_id': contact.id,
        'test_type': 'connectivity',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/contacts/${contact.id}/test',
        data: data,
      );

      if (response.data != null) {
        return ContactTestResult.fromJson(response.data!);
      }

      return ContactTestResult(
        contactId: contact.id,
        success: false,
        message: 'No response from server',
        testedAt: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      return ContactTestResult(
        contactId: contact.id,
        success: false,
        message: 'Test failed: $e',
        testedAt: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Get response metrics for an alert
  Future<EmergencyResponseMetrics?> getResponseMetrics(int alertId) async {
    try {
      final response = await ApiService.instance.get<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/alerts/$alertId/metrics',
      );

      if (response.data != null) {
        return EmergencyResponseMetrics.fromJson(response.data!);
      }

      return null;
    } catch (e) {
      print('Failed to get response metrics for alert #$alertId: $e');
      return null;
    }
  }

  /// Log response metrics to backend
  Future<void> _logResponseMetrics(int alertId, Duration responseTime) async {
    try {
      final data = <String, dynamic>{
        'alert_id': alertId,
        'response_time_seconds': responseTime.inSeconds,
        'response_actions': getResponseActions(alertId).map((a) => a.toJson()).toList(),
        'logged_at': DateTime.now().toIso8601String(),
      };

      await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/alerts/$alertId/metrics',
        data: data,
      );
    } catch (e) {
      print('Failed to log response metrics: $e');
    }
  }

  /// Get alert by ID (helper method)
  Future<EmergencyAlert?> _getAlertById(int alertId) async {
    try {
      final alerts = await EmergencyService.instance.getEmergencyAlerts();
      return alerts.firstWhere((alert) => alert.id == alertId);
    } catch (e) {
      return null;
    }
  }

  /// Clear response tracking data for an alert
  void clearResponseData(int alertId) {
    _responseStartTimes.remove(alertId);
    _responseActions.remove(alertId);
  }

  /// Dispose service resources
  void dispose() {
    _responseStartTimes.clear();
    _responseActions.clear();
    print('Emergency response service disposed');
  }
}

/// Emergency response action model
class EmergencyResponseAction {
  final int id;
  final int alertId;
  final String actionType;
  final String description;
  final int? performedBy;
  final String performedAt;

  const EmergencyResponseAction({
    required this.id,
    required this.alertId,
    required this.actionType,
    required this.description,
    this.performedBy,
    required this.performedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'alert_id': alertId,
    'action_type': actionType,
    'description': description,
    'performed_by': performedBy,
    'performed_at': performedAt,
  };

  factory EmergencyResponseAction.fromJson(Map<String, dynamic> json) => EmergencyResponseAction(
    id: json['id'] as int,
    alertId: json['alert_id'] as int,
    actionType: json['action_type'] as String,
    description: json['description'] as String,
    performedBy: json['performed_by'] as int?,
    performedAt: json['performed_at'] as String,
  );
}

/// Contact test result model
class ContactTestResult {
  final int contactId;
  final bool success;
  final String message;
  final String testedAt;
  final Map<String, dynamic>? testData;

  const ContactTestResult({
    required this.contactId,
    required this.success,
    required this.message,
    required this.testedAt,
    this.testData,
  });

  Map<String, dynamic> toJson() => {
    'contact_id': contactId,
    'success': success,
    'message': message,
    'tested_at': testedAt,
    'test_data': testData,
  };

  factory ContactTestResult.fromJson(Map<String, dynamic> json) => ContactTestResult(
    contactId: json['contact_id'] as int,
    success: json['success'] as bool,
    message: json['message'] as String,
    testedAt: json['tested_at'] as String,
    testData: json['test_data'] as Map<String, dynamic>?,
  );
}

/// Emergency response metrics model
class EmergencyResponseMetrics {
  final int alertId;
  final Duration? responseTime;
  final int actionCount;
  final String? firstResponder;
  final List<EmergencyResponseAction> actions;
  final Map<String, dynamic>? additionalMetrics;

  const EmergencyResponseMetrics({
    required this.alertId,
    this.responseTime,
    required this.actionCount,
    this.firstResponder,
    required this.actions,
    this.additionalMetrics,
  });

  Map<String, dynamic> toJson() => {
    'alert_id': alertId,
    'response_time_seconds': responseTime?.inSeconds,
    'action_count': actionCount,
    'first_responder': firstResponder,
    'actions': actions.map((a) => a.toJson()).toList(),
    'additional_metrics': additionalMetrics,
  };

  factory EmergencyResponseMetrics.fromJson(Map<String, dynamic> json) => EmergencyResponseMetrics(
    alertId: json['alert_id'] as int,
    responseTime: json['response_time_seconds'] != null 
        ? Duration(seconds: json['response_time_seconds'] as int)
        : null,
    actionCount: json['action_count'] as int,
    firstResponder: json['first_responder'] as String?,
    actions: (json['actions'] as List?)
        ?.map((a) => EmergencyResponseAction.fromJson(a as Map<String, dynamic>))
        .toList() ?? [],
    additionalMetrics: json['additional_metrics'] as Map<String, dynamic>?,
  );
}

/// Emergency exception for response service
class EmergencyException implements Exception {
  final String message;
  final String code;
  final int? statusCode;

  const EmergencyException({
    required this.message,
    required this.code,
    this.statusCode,
  });

  @override
  String toString() => 'EmergencyException: $message (Code: $code)';
}