import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_shield_mobile/core/models/incident.dart';
import 'package:patrol_shield_mobile/core/models/user.dart';
import 'package:patrol_shield_mobile/core/models/emergency.dart';

void main() {
  group('Incident Model Tests', () {
    test('Incident should be created with required fields', () {
      final incident = Incident(
        id: 1,
        title: 'Security Breach',
        description: 'Unauthorized access detected',
        category: 'Security Breach',
        priority: 'high',
        status: 'open',
        createdBy: 123,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(incident.id, equals(1));
      expect(incident.title, equals('Security Breach'));
      expect(incident.category, equals('Security Breach'));
      expect(incident.priority, equals('high'));
      expect(incident.status, equals('open'));
      expect(incident.priorityLevel, equals(3)); // high priority
      expect(incident.isOpen, isTrue);
      expect(incident.isResolved, isFalse);
    });

    test('Incident priority levels should be correct', () {
      const priorities = ['low', 'medium', 'high', 'critical'];
      const expectedLevels = [1, 2, 3, 4];

      for (int i = 0; i < priorities.length; i++) {
        final incident = Incident(
          id: i,
          title: 'Test Incident',
          description: 'Test Description',
          category: 'Test',
          priority: priorities[i],
          status: 'open',
          createdBy: 123,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(incident.priorityLevel, equals(expectedLevels[i]),
          reason: 'Priority ${priorities[i]} should have level ${expectedLevels[i]}');
      }
    });

    test('Incident status checks should work correctly', () {
      // Test open status
      final openIncident = Incident(
        id: 1,
        title: 'Open Incident',
        description: 'Test',
        category: 'Test',
        priority: 'medium',
        status: 'open',
        createdBy: 123,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(openIncident.isOpen, isTrue);
      expect(openIncident.isInProgress, isFalse);
      expect(openIncident.isResolved, isFalse);

      // Test in progress status
      final inProgressIncident = Incident(
        id: 2,
        title: 'In Progress Incident',
        description: 'Test',
        category: 'Test',
        priority: 'medium',
        status: 'in_progress',
        createdBy: 123,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(inProgressIncident.isOpen, isFalse);
      expect(inProgressIncident.isInProgress, isTrue);
      expect(inProgressIncident.isResolved, isFalse);

      // Test resolved status
      final resolvedIncident = Incident(
        id: 3,
        title: 'Resolved Incident',
        description: 'Test',
        category: 'Test',
        priority: 'medium',
        status: 'resolved',
        createdBy: 123,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        resolvedAt: DateTime.now(),
      );

      expect(resolvedIncident.isOpen, isFalse);
      expect(resolvedIncident.isInProgress, isFalse);
      expect(resolvedIncident.isResolved, isTrue);
    });

    test('IncidentRequest should serialize correctly', () {
      final request = IncidentRequest(
        title: 'Test Incident',
        description: 'Test Description',
        category: 'Security Breach',
        priority: 'high',
        latitude: 37.7749,
        longitude: -122.4194,
        notes: 'Additional notes',
      );

      final json = request.toJson();

      expect(json['title'], equals('Test Incident'));
      expect(json['description'], equals('Test Description'));
      expect(json['category'], equals('Security Breach'));
      expect(json['priority'], equals('high'));
      expect(json['latitude'], equals(37.7749));
      expect(json['longitude'], equals(-122.4194));
      expect(json['notes'], equals('Additional notes'));

      // Test round-trip serialization
      final fromJson = IncidentRequest.fromJson(json);
      expect(fromJson.title, equals(request.title));
      expect(fromJson.description, equals(request.description));
      expect(fromJson.category, equals(request.category));
      expect(fromJson.priority, equals(request.priority));
    });
  });

  group('User Model Tests', () {
    test('User should have correct role checks', () {
      final guard = User(
        id: 1,
        username: 'testguard',
        email: 'guard@test.com',
        firstName: 'Test',
        lastName: 'Guard',
        role: 'guard',
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      expect(guard.isGuard, isTrue);
      expect(guard.isSupervisor, isFalse);
      expect(guard.isSiteManager, isFalse);
      expect(guard.isAdmin, isFalse);

      final supervisor = User(
        id: 2,
        username: 'testsupervisor',
        email: 'supervisor@test.com',
        firstName: 'Test',
        lastName: 'Supervisor',
        role: 'supervisor',
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      expect(supervisor.isGuard, isFalse);
      expect(supervisor.isSupervisor, isTrue);
      expect(supervisor.isSiteManager, isFalse);
      expect(supervisor.isAdmin, isFalse);
    });

    test('User role priorities should be correct', () {
      final roles = ['guard', 'supervisor', 'site manager', 'admin'];
      final expectedPriorities = [0, 1, 2, 4];

      for (int i = 0; i < roles.length; i++) {
        final user = User(
          id: i,
          username: 'test$i',
          email: 'test$i@example.com',
          firstName: 'Test',
          lastName: 'User',
          role: roles[i],
          isActive: true,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        expect(user.rolePriority, equals(expectedPriorities[i]),
          reason: 'Role ${roles[i]} should have priority ${expectedPriorities[i]}');
      }
    });

    test('User can access should work correctly', () {
      final siteManager = User(
        id: 1,
        username: 'manager',
        email: 'manager@test.com',
        firstName: 'Site',
        lastName: 'Manager',
        role: 'site manager',
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      // Site manager should be able to access all lower roles
      expect(siteManager.canAccess('guard'), isTrue);
      expect(siteManager.canAccess('supervisor'), isTrue);
      expect(siteManager.canAccess('site manager'), isTrue);
      expect(siteManager.canAccess('admin'), isFalse);

      final guard = User(
        id: 2,
        username: 'guard',
        email: 'guard@test.com',
        firstName: 'Test',
        lastName: 'Guard',
        role: 'guard',
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      // Guard should only access guard level
      expect(guard.canAccess('guard'), isTrue);
      expect(guard.canAccess('supervisor'), isFalse);
      expect(guard.canAccess('site manager'), isFalse);
      expect(guard.canAccess('admin'), isFalse);
    });
  });

  group('Emergency Alert Tests', () {
    test('EmergencyAlert should have correct status checks', () {
      final activeAlert = EmergencyAlert(
        id: 1,
        alertType: 'sos',
        severity: 'critical',
        status: 'active',
        userId: 123,
        triggeredAt: DateTime.now().toIso8601String(),
      );

      expect(activeAlert.isActive, isTrue);
      expect(activeAlert.isAcknowledged, isFalse);
      expect(activeAlert.isResolved, isFalse);

      final acknowledgedAlert = EmergencyAlert(
        id: 2,
        alertType: 'sos',
        severity: 'high',
        status: 'acknowledged',
        userId: 123,
        triggeredAt: DateTime.now().toIso8601String(),
        acknowledgedAt: DateTime.now().toIso8601String(),
        acknowledgedBy: 456,
      );

      expect(acknowledgedAlert.isActive, isFalse);
      expect(acknowledgedAlert.isAcknowledged, isTrue);
      expect(acknowledgedAlert.isResolved, isFalse);

      final resolvedAlert = EmergencyAlert(
        id: 3,
        alertType: 'sos',
        severity: 'medium',
        status: 'resolved',
        userId: 123,
        triggeredAt: DateTime.now().toIso8601String(),
        acknowledgedAt: DateTime.now().toIso8601String(),
        acknowledgedBy: 456,
        resolvedAt: DateTime.now().toIso8601String(),
        resolvedBy: 456,
      );

      expect(resolvedAlert.isActive, isFalse);
      expect(resolvedAlert.isAcknowledged, isTrue);
      expect(resolvedAlert.isResolved, isTrue);
    });

    test('EmergencyAlert should serialize correctly', () {
      final alert = EmergencyAlert(
        id: 1,
        alertType: 'sos',
        severity: 'critical',
        status: 'active',
        userId: 123,
        userName: 'Test User',
        latitude: 37.7749,
        longitude: -122.4194,
        locationName: 'San Francisco, CA',
        description: 'Emergency situation',
        triggeredAt: '2024-01-01T12:00:00.000Z',
      );

      final json = alert.toJson();

      expect(json['id'], equals(1));
      expect(json['alert_type'], equals('sos'));
      expect(json['severity'], equals('critical'));
      expect(json['status'], equals('active'));
      expect(json['user_id'], equals(123));
      expect(json['user_name'], equals('Test User'));
      expect(json['latitude'], equals(37.7749));
      expect(json['longitude'], equals(-122.4194));
      expect(json['location_name'], equals('San Francisco, CA'));

      // Test round-trip serialization
      final fromJson = EmergencyAlert.fromJson(json);
      expect(fromJson.id, equals(alert.id));
      expect(fromJson.alertType, equals(alert.alertType));
      expect(fromJson.severity, equals(alert.severity));
      expect(fromJson.status, equals(alert.status));
      expect(fromJson.userId, equals(alert.userId));
    });
  });
}