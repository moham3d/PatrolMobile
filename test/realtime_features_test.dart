import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_shield_mobile/core/services/notification_service.dart';
import 'package:patrol_shield_mobile/core/services/messaging_service.dart';
import 'package:patrol_shield_mobile/core/services/location_sharing_service.dart';
import 'package:patrol_shield_mobile/core/services/websocket_service.dart';

/// Integration tests for real-time features
void main() {
  group('Real-time Features Integration Tests', () {
    
    test('NotificationService should initialize correctly', () {
      final notificationService = NotificationService.instance;
      expect(notificationService, isNotNull);
      expect(notificationService.fcmToken, isNull); // Not initialized yet
    });

    test('MessagingService should initialize correctly', () {
      final messagingService = MessagingService.instance;
      expect(messagingService, isNotNull);
      expect(messagingService.cachedMessages, isEmpty);
    });

    test('LocationSharingService should initialize correctly', () {
      final locationService = LocationSharingService.instance;
      expect(locationService, isNotNull);
      expect(locationService.isSharing, isFalse);
      expect(locationService.isPatrolActive, isFalse);
      expect(locationService.lastLocation, isNull);
    });

    test('WebSocketService should have correct initial state', () {
      final webSocketService = WebSocketService.instance;
      expect(webSocketService, isNotNull);
      expect(webSocketService.isConnected, isFalse);
    });

    test('EmergencyMessage model should serialize correctly', () {
      final message = EmergencyMessage(
        id: 1,
        type: 'emergency',
        content: 'Test emergency message',
        senderId: 123,
        senderName: 'Test User',
        recipientIds: [456, 789],
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        isUrgent: true,
        metadata: {'test': 'data'},
      );

      final json = message.toJson();
      expect(json['id'], equals(1));
      expect(json['type'], equals('emergency'));
      expect(json['content'], equals('Test emergency message'));
      expect(json['sender_id'], equals(123));
      expect(json['sender_name'], equals('Test User'));
      expect(json['recipient_ids'], equals([456, 789]));
      expect(json['is_urgent'], equals(true));
      expect(json['metadata'], equals({'test': 'data'}));

      final messageFromJson = EmergencyMessage.fromJson(json);
      expect(messageFromJson.id, equals(message.id));
      expect(messageFromJson.type, equals(message.type));
      expect(messageFromJson.content, equals(message.content));
      expect(messageFromJson.senderId, equals(message.senderId));
      expect(messageFromJson.senderName, equals(message.senderName));
      expect(messageFromJson.recipientIds, equals(message.recipientIds));
      expect(messageFromJson.isUrgent, equals(message.isUrgent));
    });

    test('LocationData model should create from position correctly', () {
      // Mock position data
      final mockPosition = MockPosition(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 5.0,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        speed: 10.0,
        heading: 45.0,
      );

      final locationData = LocationData.fromPosition(mockPosition, address: 'San Francisco, CA');
      
      expect(locationData.latitude, equals(37.7749));
      expect(locationData.longitude, equals(-122.4194));
      expect(locationData.accuracy, equals(5.0));
      expect(locationData.address, equals('San Francisco, CA'));
      expect(locationData.speed, equals(10.0));
      expect(locationData.heading, equals(45.0));

      final json = locationData.toJson();
      expect(json['latitude'], equals(37.7749));
      expect(json['longitude'], equals(-122.4194));
      expect(json['accuracy'], equals(5.0));
      expect(json['address'], equals('San Francisco, CA'));
      expect(json['speed'], equals(10.0));
      expect(json['heading'], equals(45.0));
    });

    test('Services should be singletons', () {
      final notificationService1 = NotificationService.instance;
      final notificationService2 = NotificationService.instance;
      expect(identical(notificationService1, notificationService2), isTrue);

      final messagingService1 = MessagingService.instance;
      final messagingService2 = MessagingService.instance;
      expect(identical(messagingService1, messagingService2), isTrue);

      final locationService1 = LocationSharingService.instance;
      final locationService2 = LocationSharingService.instance;
      expect(identical(locationService1, locationService2), isTrue);

      final webSocketService1 = WebSocketService.instance;
      final webSocketService2 = WebSocketService.instance;
      expect(identical(webSocketService1, webSocketService2), isTrue);
    });

    group('Emergency Message Types', () {
      test('should format SOS escalation correctly', () {
        final message = EmergencyMessage(
          id: 1,
          type: 'sos_escalation',
          content: 'SOS ALERT: John Doe has triggered an emergency alert at Main Building. Immediate assistance required!',
          senderId: 123,
          senderName: 'System',
          recipientIds: [456, 789],
          timestamp: DateTime.now(),
          isUrgent: true,
          metadata: {
            'alert_id': 42,
            'location': 'Main Building',
            'latitude': 37.7749,
            'longitude': -122.4194,
            'user_id': 123,
            'user_name': 'John Doe',
          },
        );

        expect(message.type, equals('sos_escalation'));
        expect(message.isUrgent, isTrue);
        expect(message.metadata?['alert_id'], equals(42));
        expect(message.metadata?['location'], equals('Main Building'));
      });

      test('should format checkpoint message correctly', () {
        final message = EmergencyMessage(
          id: 2,
          type: 'checkpoint_update',
          content: 'John Doe has completed checkpoint: Gate A',
          senderId: 123,
          senderName: 'John Doe',
          recipientIds: [456],
          timestamp: DateTime.now(),
          isUrgent: false,
          metadata: {
            'checkpoint_id': 15,
            'checkpoint_name': 'Gate A',
            'status': 'completed',
            'user_id': 123,
            'user_name': 'John Doe',
          },
        );

        expect(message.type, equals('checkpoint_update'));
        expect(message.isUrgent, isFalse);
        expect(message.metadata?['checkpoint_id'], equals(15));
        expect(message.metadata?['status'], equals('completed'));
      });
    });
  });
}

/// Mock Position class for testing
class MockPosition {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final double speed;
  final double heading;

  MockPosition({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.speed,
    required this.heading,
  });
}