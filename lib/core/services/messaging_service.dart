import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'websocket_service.dart';

/// Message model for in-app communications
class EmergencyMessage {
  final int id;
  final String type;
  final String content;
  final int senderId;
  final String senderName;
  final List<int> recipientIds;
  final DateTime timestamp;
  final bool isUrgent;
  final Map<String, dynamic>? metadata;

  const EmergencyMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.recipientIds,
    required this.timestamp,
    this.isUrgent = false,
    this.metadata,
  });

  factory EmergencyMessage.fromJson(Map<String, dynamic> json) {
    return EmergencyMessage(
      id: json['id'],
      type: json['type'] ?? 'general',
      content: json['content'],
      senderId: json['sender_id'],
      senderName: json['sender_name'] ?? 'Unknown',
      recipientIds: List<int>.from(json['recipient_ids'] ?? []),
      timestamp: DateTime.parse(json['timestamp']),
      isUrgent: json['is_urgent'] ?? false,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'content': content,
    'sender_id': senderId,
    'sender_name': senderName,
    'recipient_ids': recipientIds,
    'timestamp': timestamp.toIso8601String(),
    'is_urgent': isUrgent,
    'metadata': metadata,
  };
}

/// Messaging service for emergency communications
class MessagingService {
  static MessagingService? _instance;
  static MessagingService get instance => _instance ??= MessagingService._internal();
  
  MessagingService._internal();

  final ApiService _apiService = ApiService.instance;
  final AuthService _authService = AuthService.instance;
  final WebSocketService _webSocketService = WebSocketService.instance;
  
  final StreamController<List<EmergencyMessage>> _messagesController = 
      StreamController.broadcast();
  final StreamController<EmergencyMessage> _newMessageController = 
      StreamController.broadcast();
  
  List<EmergencyMessage> _cachedMessages = [];
  
  /// Stream of all messages
  Stream<List<EmergencyMessage>> get messagesStream => _messagesController.stream;
  
  /// Stream of new incoming messages
  Stream<EmergencyMessage> get newMessageStream => _newMessageController.stream;
  
  /// Get cached messages
  List<EmergencyMessage> get cachedMessages => List.unmodifiable(_cachedMessages);
  
  /// Initialize messaging service
  Future<void> initialize() async {
    // Listen to WebSocket messages for real-time message updates
    _webSocketService.messages.listen((wsMessage) {
      if (wsMessage.type == 'new_message' && wsMessage.data != null) {
        _handleNewMessage(wsMessage.data!);
      } else if (wsMessage.type == 'emergency_broadcast' && wsMessage.data != null) {
        _handleEmergencyBroadcast(wsMessage.data!);
      }
    });
    
    // Load initial messages
    await loadMessages();
  }
  
  /// Load messages from API
  Future<void> loadMessages() async {
    try {
      final response = await _apiService.get<List<dynamic>>('/messages');
      
      if (response.data != null) {
        _cachedMessages = response.data!
            .map((json) => EmergencyMessage.fromJson(json))
            .toList();
        
        _cachedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _messagesController.add(_cachedMessages);
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }
  
  /// Send emergency message
  Future<void> sendEmergencyMessage({
    required String content,
    required List<int> recipientIds,
    String type = 'emergency',
    bool isUrgent = true,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    try {
      final requestData = {
        'type': type,
        'content': content,
        'recipient_ids': recipientIds,
        'is_urgent': isUrgent,
        'metadata': metadata,
      };
      
      final response = await _apiService.post<Map<String, dynamic>>(
        '/messages',
        data: requestData,
      );
      
      if (response.data != null) {
        final message = EmergencyMessage.fromJson(response.data!);
        _addMessageToCache(message);
        
        // Send via WebSocket for real-time delivery
        _webSocketService.sendMessage({
          'type': 'new_message',
          'data': message.toJson(),
        });
      }
    } catch (e) {
      print('Error sending emergency message: $e');
      rethrow;
    }
  }
  
  /// Send broadcast message to all supervisors
  Future<void> sendEmergencyBroadcast({
    required String content,
    String type = 'emergency_broadcast',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final requestData = {
        'type': type,
        'content': content,
        'broadcast_to': 'supervisors',
        'is_urgent': true,
        'metadata': metadata,
      };
      
      await _apiService.post<Map<String, dynamic>>(
        '/messages/broadcast',
        data: requestData,
      );
      
      // Send via WebSocket for real-time delivery
      _webSocketService.sendMessage({
        'type': 'emergency_broadcast',
        'data': requestData,
      });
    } catch (e) {
      print('Error sending emergency broadcast: $e');
      rethrow;
    }
  }
  
  /// Send SOS escalation message
  Future<void> sendSOSEscalation({
    required int alertId,
    required String location,
    required double latitude,
    required double longitude,
  }) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final content = 'SOS ALERT: ${user.displayName} has triggered an emergency alert at $location. '
                   'Immediate assistance required!';
    
    await sendEmergencyBroadcast(
      content: content,
      type: 'sos_escalation',
      metadata: {
        'alert_id': alertId,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'user_id': user.id,
        'user_name': user.displayName,
      },
    );
  }
  
  /// Send checkpoint completion message
  Future<void> sendCheckpointMessage({
    required int checkpointId,
    required String checkpointName,
    required String status,
    String? notes,
  }) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final content = '${user.displayName} has $status checkpoint: $checkpointName'
                   '${notes != null ? '. Notes: $notes' : ''}';
    
    // Send to supervisors only
    await sendEmergencyMessage(
      content: content,
      recipientIds: [], // Will be handled by backend to send to supervisors
      type: 'checkpoint_update',
      isUrgent: false,
      metadata: {
        'checkpoint_id': checkpointId,
        'checkpoint_name': checkpointName,
        'status': status,
        'notes': notes,
        'user_id': user.id,
        'user_name': user.displayName,
      },
    );
  }
  
  /// Mark message as read
  Future<void> markMessageAsRead(int messageId) async {
    try {
      await _apiService.put('/messages/$messageId/read');
      
      // Update cached message
      final index = _cachedMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        // Note: In a full implementation, we'd update the read status
        // For now, just trigger a reload
        await loadMessages();
      }
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }
  
  /// Handle new message from WebSocket
  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final message = EmergencyMessage.fromJson(data);
      _addMessageToCache(message);
      _newMessageController.add(message);
    } catch (e) {
      print('Error handling new message: $e');
    }
  }
  
  /// Handle emergency broadcast from WebSocket
  void _handleEmergencyBroadcast(Map<String, dynamic> data) {
    try {
      final message = EmergencyMessage.fromJson(data);
      _addMessageToCache(message);
      _newMessageController.add(message);
    } catch (e) {
      print('Error handling emergency broadcast: $e');
    }
  }
  
  /// Add message to cache
  void _addMessageToCache(EmergencyMessage message) {
    _cachedMessages.insert(0, message);
    _cachedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _messagesController.add(_cachedMessages);
  }
  
  /// Dispose streams
  void dispose() {
    _messagesController.close();
    _newMessageController.close();
  }
}