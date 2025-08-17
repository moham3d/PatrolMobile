import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency.dart';
import '../services/emergency_service.dart';
import '../services/emergency_escalation_service.dart';

/// Emergency service provider
final emergencyServiceProvider = Provider<EmergencyService>((ref) {
  return EmergencyService.instance;
});

/// Emergency escalation service provider
final emergencyEscalationServiceProvider = Provider<EmergencyEscalationService>((ref) {
  return EmergencyEscalationService.instance;
});

/// Emergency alerts provider
final emergencyAlertsProvider = StateNotifierProvider<EmergencyAlertsNotifier, EmergencyAlertsState>((ref) {
  return EmergencyAlertsNotifier(
    ref.read(emergencyServiceProvider),
    ref.read(emergencyEscalationServiceProvider),
  );
});

/// Active emergency alert provider
final activeEmergencyProvider = StateProvider<EmergencyAlert?>((ref) {
  return null;
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
  
  EmergencyAlertsNotifier(this._emergencyService, this._escalationService) : super(const EmergencyAlertsState.initial());

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
      // Note: WebSocketService will be injected via provider in the actual implementation
      // For now, we'll just print that the alert would be broadcast
      print('Broadcasting emergency alert via WebSocket: ${alert.id}');
      // WebSocketService.instance.sendEmergencyAlert(alert);
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

  /// Acknowledge alert
  Future<void> acknowledgeAlert(int alertId) async {
    try {
      await _emergencyService.acknowledgeAlert(alertId);
      
      // Cancel escalation when acknowledged
      _escalationService.cancelEscalation(alertId);
      
      // Reload alerts to reflect changes
      await loadAlerts();
    } catch (e) {
      state = EmergencyAlertsState.error(e.toString());
    }
  }

  /// Resolve alert
  Future<void> resolveAlert(int alertId, {String? resolution}) async {
    try {
      await _emergencyService.resolveAlert(alertId, resolution: resolution);
      
      // Cancel escalation when resolved
      _escalationService.cancelEscalation(alertId);
      
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