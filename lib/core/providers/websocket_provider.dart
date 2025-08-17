import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/websocket_service.dart';
import '../providers/auth_provider.dart';
import '../models/emergency.dart';

/// WebSocket service provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService.instance;
});

/// WebSocket connection status provider
final webSocketConnectionProvider = StateNotifierProvider<WebSocketConnectionNotifier, WebSocketConnectionStatus>((ref) {
  return WebSocketConnectionNotifier(ref.read(webSocketServiceProvider));
});

/// WebSocket messages stream provider
final webSocketMessagesProvider = StreamProvider<WebSocketMessage>((ref) {
  final service = ref.read(webSocketServiceProvider);
  return service.messages;
});

/// Auto-connect WebSocket when user is authenticated
final webSocketAutoConnectProvider = Provider<void>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final webSocketService = ref.read(webSocketServiceProvider);
  final connectionNotifier = ref.read(webSocketConnectionProvider.notifier);
  
  if (authState is Authenticated) {
    final user = authState.user;
    final token = authState.token; // Use real token from auth state
    connectionNotifier.connect(user.id.toString(), token);
  } else {
    connectionNotifier.disconnect();
  }
});

/// WebSocket connection notifier
class WebSocketConnectionNotifier extends StateNotifier<WebSocketConnectionStatus> {
  final WebSocketService _webSocketService;
  
  WebSocketConnectionNotifier(this._webSocketService) : super(WebSocketConnectionStatus.disconnected);

  /// Connect to WebSocket
  Future<void> connect(String userId, String token) async {
    state = WebSocketConnectionStatus.reconnecting;
    try {
      await _webSocketService.connect(userId, token);
      state = WebSocketConnectionStatus.connected;
    } catch (e) {
      state = WebSocketConnectionStatus.disconnected;
    }
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _webSocketService.disconnect();
    state = WebSocketConnectionStatus.disconnected;
  }

  /// Send emergency alert
  void sendEmergencyAlert(EmergencyAlert emergencyAlert) {
    _webSocketService.sendEmergencyAlert(emergencyAlert);
  }

  /// Send location update
  void sendLocationUpdate(double latitude, double longitude, {String? address}) {
    _webSocketService.sendLocationUpdate(latitude, longitude, address: address);
  }
}