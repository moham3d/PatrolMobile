import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/messaging_service.dart';
import '../services/location_sharing_service.dart';

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

/// Messaging service provider
final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService.instance;
});

/// Location sharing service provider
final locationSharingServiceProvider = Provider<LocationSharingService>((ref) {
  return LocationSharingService.instance;
});

/// Real-time messaging provider
final messagesProvider = StreamProvider<List<EmergencyMessage>>((ref) {
  final messagingService = ref.read(messagingServiceProvider);
  return messagingService.messagesStream;
});

/// New message notifications provider
final newMessageProvider = StreamProvider<EmergencyMessage>((ref) {
  final messagingService = ref.read(messagingServiceProvider);
  return messagingService.newMessageStream;
});

/// Location updates provider
final locationUpdatesProvider = StreamProvider<LocationData>((ref) {
  final locationService = ref.read(locationSharingServiceProvider);
  return locationService.locationStream;
});

/// Current location provider
final currentLocationProvider = FutureProvider<LocationData?>((ref) {
  final locationService = ref.read(locationSharingServiceProvider);
  return locationService.getCurrentLocation();
});

/// Patrol tracking status provider
final patrolTrackingProvider = StateNotifierProvider<PatrolTrackingNotifier, PatrolTrackingState>((ref) {
  return PatrolTrackingNotifier(ref.read(locationSharingServiceProvider));
});

/// Emergency messaging provider
final emergencyMessagingProvider = StateNotifierProvider<EmergencyMessagingNotifier, EmergencyMessagingState>((ref) {
  return EmergencyMessagingNotifier(ref.read(messagingServiceProvider));
});

/// Patrol tracking state
class PatrolTrackingState {
  final bool isActive;
  final bool isSharing;
  final LocationData? lastLocation;
  final String? error;

  const PatrolTrackingState({
    this.isActive = false,
    this.isSharing = false,
    this.lastLocation,
    this.error,
  });

  PatrolTrackingState copyWith({
    bool? isActive,
    bool? isSharing,
    LocationData? lastLocation,
    String? error,
  }) {
    return PatrolTrackingState(
      isActive: isActive ?? this.isActive,
      isSharing: isSharing ?? this.isSharing,
      lastLocation: lastLocation ?? this.lastLocation,
      error: error ?? this.error,
    );
  }
}

/// Patrol tracking notifier
class PatrolTrackingNotifier extends StateNotifier<PatrolTrackingState> {
  final LocationSharingService _locationService;

  PatrolTrackingNotifier(this._locationService) : super(const PatrolTrackingState()) {
    // Listen to location updates
    _locationService.locationStream.listen((location) {
      state = state.copyWith(
        lastLocation: location,
        error: null,
      );
    });
  }

  /// Start patrol tracking
  Future<void> startPatrolTracking() async {
    try {
      await _locationService.startPatrolTracking();
      state = state.copyWith(
        isActive: true,
        isSharing: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Stop patrol tracking
  void stopPatrolTracking() {
    _locationService.stopPatrolTracking();
    state = state.copyWith(
      isActive: false,
      error: null,
    );
  }

  /// Start location sharing
  Future<void> startLocationSharing() async {
    try {
      await _locationService.startLocationSharing();
      state = state.copyWith(
        isSharing: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Stop location sharing
  void stopLocationSharing() {
    _locationService.stopLocationSharing();
    state = state.copyWith(
      isActive: false,
      isSharing: false,
      error: null,
    );
  }

  /// Start emergency tracking
  Future<void> startEmergencyTracking() async {
    try {
      await _locationService.startEmergencyTracking();
      state = state.copyWith(
        isSharing: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Emergency messaging state
class EmergencyMessagingState {
  final bool isSending;
  final String? error;
  final String? successMessage;

  const EmergencyMessagingState({
    this.isSending = false,
    this.error,
    this.successMessage,
  });

  EmergencyMessagingState copyWith({
    bool? isSending,
    String? error,
    String? successMessage,
  }) {
    return EmergencyMessagingState(
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

/// Emergency messaging notifier
class EmergencyMessagingNotifier extends StateNotifier<EmergencyMessagingState> {
  final MessagingService _messagingService;

  EmergencyMessagingNotifier(this._messagingService) : super(const EmergencyMessagingState());

  /// Send emergency message
  Future<void> sendEmergencyMessage({
    required String content,
    required List<int> recipientIds,
    String type = 'emergency',
    bool isUrgent = true,
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(isSending: true, error: null);
    
    try {
      await _messagingService.sendEmergencyMessage(
        content: content,
        recipientIds: recipientIds,
        type: type,
        isUrgent: isUrgent,
        metadata: metadata,
      );
      
      state = state.copyWith(
        isSending: false,
        successMessage: 'Emergency message sent successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: e.toString(),
      );
    }
  }

  /// Send SOS escalation
  Future<void> sendSOSEscalation({
    required int alertId,
    required String location,
    required double latitude,
    required double longitude,
  }) async {
    state = state.copyWith(isSending: true, error: null);
    
    try {
      await _messagingService.sendSOSEscalation(
        alertId: alertId,
        location: location,
        latitude: latitude,
        longitude: longitude,
      );
      
      state = state.copyWith(
        isSending: false,
        successMessage: 'SOS escalation sent successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: e.toString(),
      );
    }
  }

  /// Send checkpoint message
  Future<void> sendCheckpointMessage({
    required int checkpointId,
    required String checkpointName,
    required String status,
    String? notes,
  }) async {
    try {
      await _messagingService.sendCheckpointMessage(
        checkpointId: checkpointId,
        checkpointName: checkpointName,
        status: status,
        notes: notes,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(
      error: null,
      successMessage: null,
    );
  }
}