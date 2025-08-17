import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency.dart';
import '../services/emergency_service.dart';
import '../services/emergency_escalation_service.dart';
import '../services/emergency_response_service.dart';

/// Emergency service provider
final emergencyServiceProvider = Provider<EmergencyService>((ref) {
  return EmergencyService.instance;
});

/// Emergency escalation service provider
final emergencyEscalationServiceProvider = Provider<EmergencyEscalationService>((ref) {
  return EmergencyEscalationService.instance;
});

/// Emergency response service provider
final emergencyResponseServiceProvider = Provider<EmergencyResponseService>((ref) {
  return EmergencyResponseService.instance;
});

/// Emergency alerts provider
final emergencyAlertsProvider = StateNotifierProvider<EmergencyAlertsNotifier, EmergencyAlertsState>((ref) {
  return EmergencyAlertsNotifier(
    ref.read(emergencyServiceProvider),
    ref.read(emergencyEscalationServiceProvider),
    ref.read(emergencyResponseServiceProvider),
  );
});

/// Active emergency alert provider
final activeEmergencyProvider = StateProvider<EmergencyAlert?>((ref) {
  return null;
});

/// Emergency contacts provider
final emergencyContactsProvider = FutureProvider<List<EmergencyContact>>((ref) async {
  final responseService = ref.read(emergencyResponseServiceProvider);
  return await responseService.getEmergencyContactsEnhanced();
});

/// Location permission status provider
final locationPermissionProvider = FutureProvider<bool>((ref) async {
  final emergencyService = ref.read(emergencyServiceProvider);
  return await emergencyService.hasLocationPermission();
});

/// Location service enabled provider
final locationServiceProvider = FutureProvider<bool>((ref) async {
  final emergencyService = ref.read(emergencyServiceProvider);
  return await emergencyService.isLocationServiceEnabled();
});

/// Emergency alerts state notifier
class EmergencyAlertsNotifier extends StateNotifier<EmergencyAlertsState> {
  final EmergencyService _emergencyService;
  final EmergencyEscalationService _escalationService;
  final EmergencyResponseService _responseService;
  
  EmergencyAlertsNotifier(
    this._emergencyService, 
    this._escalationService,
    this._responseService,
  ) : super(const EmergencyAlertsState.initial());

  /// Trigger SOS emergency alert
  Future<EmergencyAlert?> triggerSOS({String? description}) async {
    state = const EmergencyAlertsState.triggering();
    
    try {
      final response = await _emergencyService.triggerSOS(
        description: description,
        includeLocation: true,
      );
      
      if (response.success) {
        // Broadcast emergency alert via WebSocket
        _broadcastEmergencyAlert(response.alert);
        
        // Start escalation timer
        _escalationService.startEscalation(response.alert);
        
        state = EmergencyAlertsState.triggered(response.alert);
        return response.alert;
      } else {
        state = EmergencyAlertsState.error(response.message);
        return null;
      }
    } catch (e) {
      state = EmergencyAlertsState.error(e.toString());
      return null;
    }
  }

  /// Trigger panic alert
  Future<EmergencyAlert?> triggerPanic({String? description}) async {
    state = const EmergencyAlertsState.triggering();
    
    try {
      final response = await _emergencyService.triggerPanic(
        description: description,
        includeLocation: true,
      );
      
      if (response.success) {
        // Broadcast emergency alert via WebSocket
        _broadcastEmergencyAlert(response.alert);
        
        // Start escalation timer
        _escalationService.startEscalation(response.alert);
        
        state = EmergencyAlertsState.triggered(response.alert);
        return response.alert;
      } else {
        state = EmergencyAlertsState.error(response.message);
        return null;
      }
    } catch (e) {
      state = EmergencyAlertsState.error(e.toString());
      return null;
    }
  }

  /// Broadcast emergency alert via WebSocket
  void _broadcastEmergencyAlert(EmergencyAlert alert) {
    try {
      // Create emergency alert message for WebSocket broadcasting
      final alertMessage = {
        'type': 'emergency_alert',
        'alert': {
          'id': alert.id,
          'alert_type': alert.alertType,
          'severity': alert.severity,
          'status': alert.status,
          'user_id': alert.userId,
          'user_name': alert.userName,
          'description': alert.description,
          'location': {
            'latitude': alert.latitude,
            'longitude': alert.longitude,
            'location_name': alert.locationName,
          },
          'triggered_at': alert.triggeredAt,
        },
        'broadcast_to': 'supervisors', // Broadcast to supervisors and above
        'priority': 'critical',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Send via WebSocket if available
      // Note: In production, this would be handled by WebSocketService
      print('Broadcasting emergency alert via WebSocket: ${alert.id}');
      print('Alert data: ${alertMessage.toString()}');
      
      // In actual implementation:
      // WebSocketService.instance.sendMessage(alertMessage);
      
    } catch (e) {
      print('Failed to broadcast emergency alert: $e');
    }
  }

  /// Load emergency alerts
  Future<void> loadAlerts({String? status}) async {
    state = const EmergencyAlertsState.loading();
    
    try {
      final alerts = await _emergencyService.getEmergencyAlerts(status: status);
      state = EmergencyAlertsState.loaded(alerts);
    } catch (e) {
      state = EmergencyAlertsState.error(e.toString());
    }
  }

  /// Acknowledge alert with enhanced tracking
  Future<void> acknowledgeAlert(int alertId, {String? note}) async {
    try {
      await _responseService.acknowledgeAlertEnhanced(
        alertId,
        acknowledgmentNote: note,
      );
      
      // Reload alerts to reflect changes
      await loadAlerts();
    } catch (e) {
      state = EmergencyAlertsState.error(e.toString());
    }
  }

  /// Resolve alert with enhanced tracking
  Future<void> resolveAlert(int alertId, {
    String? resolution,
    String? resolutionType,
    List<String>? followUpActions,
  }) async {
    try {
      await _responseService.resolveAlertEnhanced(
        alertId,
        resolutionType: resolutionType ?? 'resolved',
        resolutionNotes: resolution,
        followUpActions: followUpActions,
      );
      
      // If this was the active alert, clear it
      if (state is Triggered) {
        final triggeredState = state as Triggered;
        if (triggeredState.alert.id == alertId) {
          state = const EmergencyAlertsState.resolved();
        }
      }
      // Reload alerts to reflect changes
      await loadAlerts();
    } catch (e) {
      state = EmergencyAlertsState.error(e.toString());
    }
  }

  /// Manually escalate alert
  Future<void> escalateAlert(int alertId, String reason) async {
    try {
      await _responseService.escalateAlert(alertId, escalationReason: reason);
      
      // Reload alerts to reflect changes
      await loadAlerts();
    } catch (e) {
      state = EmergencyAlertsState.error(e.toString());
    }
  }

  /// Cancel alert
  Future<void> cancelAlert(int alertId, {String? reason}) async {
    try {
      await _emergencyService.cancelAlert(alertId, reason: reason);
      
      // Cancel escalation when cancelled
      _escalationService.cancelEscalation(alertId);
      
      // If this was the active alert, mark as cancelled
      if (state is Triggered) {
        final triggeredState = state as Triggered;
        if (triggeredState.alert.id == alertId) {
          state = const EmergencyAlertsState.cancelled();
        }
      }
      // Reload alerts to reflect changes
      await loadAlerts();
    } catch (e) {
      state = EmergencyAlertsState.error(e.toString());
    }
  }

  /// Update emergency location
  Future<void> updateLocation(int alertId, EmergencyLocation location) async {
    try {
      await _emergencyService.updateEmergencyLocation(alertId, location);
    } catch (e) {
      // Don't change state for location updates, just log error
      print('Failed to update emergency location: $e');
    }
  }

  /// Reset state
  void reset() {
    state = const EmergencyAlertsState.initial();
  }
}

/// Emergency alerts state sealed class
sealed class EmergencyAlertsState {
  const EmergencyAlertsState();
  
  const factory EmergencyAlertsState.initial() = Initial;
  const factory EmergencyAlertsState.loading() = Loading;
  const factory EmergencyAlertsState.triggering() = Triggering;
  const factory EmergencyAlertsState.triggered(EmergencyAlert alert) = Triggered;
  const factory EmergencyAlertsState.loaded(List<EmergencyAlert> alerts) = Loaded;
  const factory EmergencyAlertsState.resolved() = Resolved;
  const factory EmergencyAlertsState.cancelled() = Cancelled;
  const factory EmergencyAlertsState.error(String message) = EmergencyError;
}

class Initial extends EmergencyAlertsState {
  const Initial();
}

class Loading extends EmergencyAlertsState {
  const Loading();
}

class Triggering extends EmergencyAlertsState {
  const Triggering();
}

class Triggered extends EmergencyAlertsState {
  final EmergencyAlert alert;
  const Triggered(this.alert);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Triggered &&
          runtimeType == other.runtimeType &&
          alert == other.alert;

  @override
  int get hashCode => alert.hashCode;
}

class Loaded extends EmergencyAlertsState {
  final List<EmergencyAlert> alerts;
  const Loaded(this.alerts);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Loaded &&
          runtimeType == other.runtimeType &&
          alerts == other.alerts;

  @override
  int get hashCode => alerts.hashCode;
}

class Resolved extends EmergencyAlertsState {
  const Resolved();
}

class Cancelled extends EmergencyAlertsState {
  const Cancelled();
}

class EmergencyError extends EmergencyAlertsState {
  final String message;
  const EmergencyError(this.message);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Computed providers
final isEmergencyActiveProvider = Provider<bool>((ref) {
  final emergencyState = ref.watch(emergencyAlertsProvider);
  return emergencyState is Triggered;
});

final currentEmergencyAlertProvider = Provider<EmergencyAlert?>((ref) {
  final emergencyState = ref.watch(emergencyAlertsProvider);
  return emergencyState is Triggered ? emergencyState.alert : null;
});

final isEmergencyLoadingProvider = Provider<bool>((ref) {
  final emergencyState = ref.watch(emergencyAlertsProvider);
  return emergencyState is Loading || emergencyState is Triggering;
});

final emergencyErrorProvider = Provider<String?>((ref) {
  final emergencyState = ref.watch(emergencyAlertsProvider);
  return emergencyState is EmergencyError ? emergencyState.message : null;
});