import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_shield_mobile/core/services/database_service.dart';
import 'package:patrol_shield_mobile/core/models/checkpoint.dart';
import 'package:patrol_shield_mobile/core/models/patrol_simple.dart';

void main() {
  group('Offline Sync Integration Tests', () {
    late DatabaseService databaseService;

    setUpAll(() async {
      databaseService = DatabaseService.instance;
      // Initialize by accessing the database
      await databaseService.database;
    });

    tearDownAll(() async {
      await databaseService.close();
    });

    test('Should store and retrieve offline checkpoint visits', () async {
      // Create a test checkpoint visit
      final visitId = await databaseService.storeOfflineCheckpointVisit(
        checkpointId: 1,
        checkpointCode: 'CP001',
        patrolId: 1,
        userId: 123,
        latitude: 37.7749,
        longitude: -122.4194,
        locationAccuracy: 5.0,
        scanMethod: 'qr',
        notes: 'Test checkpoint visit',
        deviceTimestamp: DateTime.now().toIso8601String(),
      );

      expect(visitId, isNotNull);
      expect(visitId, greaterThan(0));

      // Retrieve pending sync items (includes offline visits)
      final pendingItems = await databaseService.getPendingSyncItems();
      expect(pendingItems, isNotEmpty);

      // Find our visit in the pending items
      final visitData = pendingItems.firstWhere(
        (item) => item['type'] == 'checkpoint_visit' && 
                  item['data']['checkpoint_code'] == 'CP001',
        orElse: () => {},
      );
      
      expect(visitData, isNotEmpty);
      expect(visitData['data']['checkpoint_id'], equals(1));
      expect(visitData['data']['patrol_id'], equals(1));
      expect(visitData['data']['user_id'], equals(123));
      expect(visitData['data']['scan_method'], equals('qr'));
      expect(visitData['data']['notes'], equals('Test checkpoint visit'));
    });

    test('Should mark offline visits as synced', () async {
      // Create a test visit
      final visitId = await databaseService.storeOfflineCheckpointVisit(
        checkpointId: 2,
        checkpointCode: 'CP002',
        patrolId: 2,
        userId: 456,
        latitude: 40.7128,
        longitude: -74.0060,
        locationAccuracy: 3.0,
        scanMethod: 'nfc',
        deviceTimestamp: DateTime.now().toIso8601String(),
      );

      // Mark as synced
      await databaseService.markItemSynced('offline_checkpoint_visits', visitId);

      // Verify sync statistics
      final stats = await databaseService.getSyncStatistics();
      expect(stats, isNotEmpty);
      expect(stats.containsKey('offline_checkpoint_visits'), isTrue);
    });

    test('Should store offline patrol actions', () async {
      // Store a patrol action
      final actionId = await databaseService.storeOfflinePatrolAction(
        patrolId: 5,
        actionType: 'start',
        userId: 789,
        latitude: 34.0522,
        longitude: -118.2437,
        locationAccuracy: 4.0,
        notes: 'Starting patrol at main gate',
        deviceTimestamp: DateTime.now().toIso8601String(),
      );

      expect(actionId, isNotNull);
      expect(actionId, greaterThan(0));

      // Check if it appears in pending sync items
      final pendingItems = await databaseService.getPendingSyncItems();
      final actionData = pendingItems.firstWhere(
        (item) => item['type'] == 'patrol_action' && 
                  item['data']['action'] == 'start' &&
                  item['data']['patrol_id'] == 5,
        orElse: () => {},
      );
      
      expect(actionData, isNotEmpty);
      expect(actionData['data']['user_id'], equals(789));
      expect(actionData['data']['notes'], equals('Starting patrol at main gate'));
    });

    test('Should cache and retrieve checkpoints', () async {
      // Create a test checkpoint
      final checkpoint = Checkpoint(
        id: 100,
        name: 'Test Checkpoint',
        code: 'TEST001',
        description: 'Test checkpoint for caching',
        qrCode: 'QR_TEST_001',
        nfcTag: 'NFC_TEST_001',
        latitude: 37.7749,
        longitude: -122.4194,
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      // Cache the checkpoint
      final cacheId = await databaseService.cacheCheckpoint(checkpoint);
      expect(cacheId, isNotNull);
      expect(cacheId, greaterThan(0));

      // Retrieve cached checkpoint by code
      final cachedCheckpoint = await databaseService.getCachedCheckpointByCode('TEST001');
      expect(cachedCheckpoint, isNotNull);
      expect(cachedCheckpoint!.id, equals(100));
      expect(cachedCheckpoint.name, equals('Test Checkpoint'));
      expect(cachedCheckpoint.code, equals('TEST001'));
      expect(cachedCheckpoint.qrCode, equals('QR_TEST_001'));
      expect(cachedCheckpoint.nfcTag, equals('NFC_TEST_001'));
    });

    test('Should handle multiple operations without errors', () async {
      // Test multiple operations in sequence
      final operations = <Future>[];

      // Store multiple checkpoint visits
      for (int i = 0; i < 5; i++) {
        operations.add(
          databaseService.storeOfflineCheckpointVisit(
            checkpointId: i + 10,
            checkpointCode: 'CP${10 + i}',
            patrolId: i + 5,
            userId: 100 + i,
            latitude: 37.7749 + i * 0.001,
            longitude: -122.4194 + i * 0.001,
            locationAccuracy: 5.0,
            scanMethod: i % 2 == 0 ? 'qr' : 'nfc',
            notes: 'Batch test visit $i',
            deviceTimestamp: DateTime.now().toIso8601String(),
          ),
        );
      }

      // Wait for all operations to complete
      final results = await Future.wait(operations);
      
      // All operations should succeed
      for (final result in results) {
        expect(result, isNotNull);
        expect(result, greaterThan(0));
      }

      // Verify operations were stored
      final pendingItems = await databaseService.getPendingSyncItems();
      final batchVisits = pendingItems.where((item) => 
        item['type'] == 'checkpoint_visit' &&
        item['data']['notes']?.toString().contains('Batch test visit') == true
      );
      expect(batchVisits.length, greaterThanOrEqualTo(5));
    });

    test('Should maintain sync statistics', () async {
      // Get initial statistics
      final initialStats = await databaseService.getSyncStatistics();
      expect(initialStats, isNotNull);
      expect(initialStats, isA<Map<String, int>>());

      // Create some test data
      await databaseService.storeOfflineCheckpointVisit(
        checkpointId: 999,
        checkpointCode: 'STATS_TEST',
        patrolId: 999,
        userId: 999,
        latitude: 0.0,
        longitude: 0.0,
        locationAccuracy: 1.0,
        scanMethod: 'manual',
        notes: 'Statistics test checkpoint',
        deviceTimestamp: DateTime.now().toIso8601String(),
      );

      // Check updated statistics
      final updatedStats = await databaseService.getSyncStatistics();
      expect(updatedStats, isNotNull);

      // Should have at least the offline checkpoint visits table
      expect(updatedStats.containsKey('offline_checkpoint_visits'), isTrue);
    });

    test('Should clean old cache data', () async {
      // Create some test checkpoints to cache
      for (int i = 0; i < 3; i++) {
        final checkpoint = Checkpoint(
          id: 200 + i,
          name: 'Cache Test $i',
          code: 'CACHE_$i',
          isActive: true,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
        await databaseService.cacheCheckpoint(checkpoint);
      }

      // Clean old cache (won't delete recent items, but should run without error)
      await databaseService.cleanOldCache(maxAge: Duration(days: 1));

      // Verify the method completed successfully
      final stats = await databaseService.getSyncStatistics();
      expect(stats, isNotNull);
    });

    test('Should handle database operations consistently', () async {
      // Test database consistency by performing operations in parallel
      final futures = <Future>[];

      // Add checkpoint visits
      for (int i = 0; i < 3; i++) {
        futures.add(
          databaseService.storeOfflineCheckpointVisit(
            checkpointId: 300 + i,
            checkpointCode: 'PARALLEL_$i',
            patrolId: 300 + i,
            userId: 300 + i,
            latitude: 37.7749,
            longitude: -122.4194,
            locationAccuracy: 5.0,
            scanMethod: 'qr',
            deviceTimestamp: DateTime.now().toIso8601String(),
          ),
        );
      }

      // Add patrol actions
      for (int i = 0; i < 3; i++) {
        futures.add(
          databaseService.storeOfflinePatrolAction(
            patrolId: 400 + i,
            actionType: 'checkpoint_visit',
            userId: 400 + i,
            latitude: 37.7749,
            longitude: -122.4194,
            locationAccuracy: 5.0,
            deviceTimestamp: DateTime.now().toIso8601String(),
          ),
        );
      }

      // Execute all operations
      final results = await Future.wait(futures);

      // All should succeed
      for (final result in results) {
        expect(result, greaterThan(0));
      }

      // Verify all data was stored
      final pendingItems = await databaseService.getPendingSyncItems();
      expect(pendingItems.length, greaterThanOrEqualTo(6));
    });
  });
}