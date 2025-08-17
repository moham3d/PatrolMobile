import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../constants/app_constants.dart';
import '../models/emergency.dart';

/// WebSocket service for real-time communication
class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._internal();
  
  WebSocketService._internal();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  final StreamController<WebSocketMessage> _messageController = 
      StreamController.broadcast();
  
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  String? _userId;
  String? _token;
  
  /// Stream of incoming WebSocket messages
  Stream<WebSocketMessage> get messages => _messageController.stream;
  
  /// Check if WebSocket is connected
  bool get isConnected => _isConnected;
  
  /// Current connection status
  WebSocketConnectionStatus get connectionStatus {
    if (_isConnected) return WebSocketConnectionStatus.connected;
    if (_reconnectTimer?.isActive == true) return WebSocketConnectionStatus.reconnecting;
    return WebSocketConnectionStatus.disconnected;
  }

  /// Connect to WebSocket server
  Future<void> connect(String userId, String token) async {
    _userId = userId;
    _token = token;
    
    if (_isConnected) {
      print('WebSocket already connected');
      return;
    }

    try {
      final uri = Uri.parse('${AppConstants.wsBaseUrl}/$userId?token=$token');
      print('Connecting to WebSocket: $uri');
      
      _channel = WebSocketChannel.connect(uri);
      
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
      );
      
      _isConnected = true;
      _reconnectAttempts = 0;
      _startHeartbeat();
      
      print('WebSocket connected successfully');
      
      // Send connection confirmation
      _sendMessage({
        'type': 'connection',
        'status': 'connected',
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      print('WebSocket connection failed: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }
  
  /// Disconnect from WebSocket server
  void disconnect() {
    print('Disconnecting WebSocket');
    
    _isConnected = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    
    _channel?.sink.close(status.goingAway);
    _channel = null;
    
    _messageController.add(const WebSocketMessage.disconnected());
  }
  
  /// Send emergency alert via WebSocket
  void sendEmergencyAlert(EmergencyAlert alert) {
    if (!_isConnected) {
      print('WebSocket not connected, cannot send emergency alert');
      return;
    }
    
    _sendMessage({
      'type': 'emergency_alert',
      'data': {
        'alert_id': alert.id,
        'user_id': alert.userId,
        'severity': alert.severity,
        'description': alert.description,
        'location': alert.location != null ? {
          'latitude': alert.location!.latitude,
          'longitude': alert.location!.longitude,
          'address': alert.location!.locationName,
        } : null,
        'triggered_at': alert.triggeredAt,
        'status': alert.status,
      },
    });
  }
  
  /// Send location update
  void sendLocationUpdate(double latitude, double longitude, {String? address}) {
    if (!_isConnected) return;
    
    _sendMessage({
      'type': 'location_update',
      'data': {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'timestamp': DateTime.now().toIso8601String(),
      },
    });
  }
  
  /// Send acknowledgment for emergency alert
  void sendEmergencyAcknowledgment(int alertId) {
    if (!_isConnected) return;
    
    _sendMessage({
      'type': 'emergency_acknowledgment',
      'data': {
        'alert_id': alertId,
        'acknowledged_by': _userId,
        'acknowledged_at': DateTime.now().toIso8601String(),
      },
    });
  }

  /// Handle incoming messages
  void _onMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final wsMessage = WebSocketMessage.fromJson(data);
      
      print('WebSocket message received: ${wsMessage.type}');
      _messageController.add(wsMessage);
      
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }
  
  /// Handle WebSocket errors
  void _onError(dynamic error) {
    print('WebSocket error: $error');
    _isConnected = false;
    _messageController.add(WebSocketMessage.error(error.toString()));
    _scheduleReconnect();
  }
  
  /// Handle WebSocket disconnection
  void _onDisconnected() {
    print('WebSocket disconnected');
    _isConnected = false;
    _heartbeatTimer?.cancel();
    _messageController.add(const WebSocketMessage.disconnected());
    _scheduleReconnect();
  }
  
  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      _messageController.add(const WebSocketMessage.error('Max reconnection attempts reached'));
      return;
    }
    
    if (_userId == null || _token == null) {
      print('No credentials available for reconnection');
      return;
    }
    
    _reconnectAttempts++;
    final delay = Duration(seconds: math.pow(2, _reconnectAttempts).toInt());
    print('Scheduling WebSocket reconnection in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    
    _reconnectTimer = Timer(delay, () {
      print('Attempting WebSocket reconnection...');
      connect(_userId!, _token!);
    });
  }
  
  /// Send message to WebSocket server
  void _sendMessage(Map<String, dynamic> message) {
    if (_channel?.sink != null) {
      try {
        _channel!.sink.add(json.encode(message));
      } catch (e) {
        print('Error sending WebSocket message: $e');
      }
    }
  }
  
  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isConnected) {
        _sendMessage({
          'type': 'heartbeat',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }
  
  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
  }
}

/// WebSocket message model
class WebSocketMessage {
  final String type;
  final Map<String, dynamic>? data;
  final String? error;
  final DateTime timestamp;

  const WebSocketMessage({
    required this.type,
    this.data,
    this.error,
    required this.timestamp,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>?,
      error: json['error'] as String?,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }

  factory WebSocketMessage.connected() => WebSocketMessage(
    type: 'connected',
    timestamp: DateTime.now(),
  );
  
  factory WebSocketMessage.disconnected() => WebSocketMessage(
    type: 'disconnected',
    timestamp: DateTime.now(),
  );
  
  factory WebSocketMessage.error(String error) => WebSocketMessage(
    type: 'error',
    error: error,
    timestamp: DateTime.now(),
  );
  
  factory WebSocketMessage.emergencyAlert(Map<String, dynamic> data) => WebSocketMessage(
    type: 'emergency_alert',
    data: data,
    timestamp: DateTime.now(),
  );
  
  factory WebSocketMessage.notification(Map<String, dynamic> data) => WebSocketMessage(
    type: 'notification',
    data: data,
    timestamp: DateTime.now(),
  );
  
  factory WebSocketMessage.locationUpdate(Map<String, dynamic> data) => WebSocketMessage(
    type: 'location_update',
    data: data,
    timestamp: DateTime.now(),
  );

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'WebSocketMessage(type: $type, data: $data, error: $error, timestamp: $timestamp)';
  }
}

/// WebSocket connection status
enum WebSocketConnectionStatus {
  connected,
  disconnected,
  reconnecting,
}