import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../models/checkpoint.dart';
import '../models/patrol_simple.dart';
import '../models/sync_models.dart';
import '../exceptions/api_exception.dart';
import 'database_service.dart';
import 'connectivity_service.dart';
import 'api_service.dart';

/// Data synchronization service for offline/online data sync
class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._internal();

  SyncService._internal();

  final DatabaseService _databaseService = DatabaseService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;

  bool _isSyncing = false;
  Timer? _syncTimer;
  StreamSubscription<bool>? _connectivitySubscription;

  final StreamController<SyncStatus> _syncStatusController =
      StreamController.broadcast();

  /// Stream of sync status updates
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Current sync status
  bool get isSyncing => _isSyncing;

  /// Initialize sync service
  Future<void> initialize() async {
    // Listen to connectivity changes and trigger sync when online
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      _onConnectivityChanged,
    );

    // Start periodic sync timer
    _startPeriodicSync();

    // Initial sync if online
    if (_connectivityService.isOnline) {
      await syncPendingData();
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(bool isOnline) {
    print(
      'Sync service: Connectivity changed - ${isOnline ? 'ONLINE' : 'OFFLINE'}',
    );

    if (isOnline) {
      // Trigger immediate sync when coming back online
      Future.delayed(const Duration(seconds: 2), () {
        syncPendingData();
      });
    }
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(minutes: AppConstants.syncIntervalMinutes),
      (timer) async {
        if (_connectivityService.isOnline && !_isSyncing) {
          await syncPendingData();
        }
      },
    );
  }

  /// Sync all pending data to backend
  Future<bool> syncPendingData() async {
    if (_isSyncing || !_connectivityService.isOnline) {
      print('Sync skipped: ${_isSyncing ? 'already syncing' : 'offline'}');
      return false;
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      print('Starting data sync...');
      final pendingItems = await _databaseService.getPendingSyncItems();

      if (pendingItems.isEmpty) {
        print('No pending items to sync');
        _syncStatusController.add(SyncStatus.completed);
        return true;
      }

      print('Found ${pendingItems.length} items to sync');

      int syncedCount = 0;
      int errorCount = 0;

      for (final item in pendingItems) {
        try {
          final success = await _syncSingleItem(item);
          if (success) {
            syncedCount++;
          } else {
            errorCount++;
          }
        } catch (e) {
          print('Error syncing item: $e');
          errorCount++;
        }

        // Small delay between syncs to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
      }

      print('Sync completed: $syncedCount synced, $errorCount errors');

      _syncStatusController.add(SyncStatus.completed);
      return errorCount == 0;
    } catch (e) {
      print('Sync failed: $e');
      _syncStatusController.add(SyncStatus.error);
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single item
  Future<bool> _syncSingleItem(Map<String, dynamic> item) async {
    final type = item['type'] as String;
    final data = item['data'] as Map<String, dynamic>;

    try {
      switch (type) {
        case 'checkpoint_visit':
          return await _syncCheckpointVisit(data);
        case 'patrol_action':
          return await _syncPatrolAction(data);
        default:
          print('Unknown sync item type: $type');
          return false;
      }
    } catch (e) {
      print('Error syncing $type: $e');
      await _handleSyncError(type, data['id'], e.toString());
      return false;
    }
  }

  /// Sync checkpoint visit to backend
  Future<bool> _syncCheckpointVisit(Map<String, dynamic> data) async {
    try {
      // Map stored data keys to model constructor names
      final visitRequest = CheckpointVisitRequest(
        checkpointId: data['checkpoint_id'] as int?,
        checkpointCode: data['checkpoint_code'] as String?,
        scanMethod: data['scan_method'] as String? ?? 'unknown',
        scannedCode:
            (data['scanned_code'] as String?) ??
            (data['checkpoint_code'] as String?) ??
            '',
        latitude: (data['latitude'] as num?)?.toDouble(),
        longitude: (data['longitude'] as num?)?.toDouble(),
        locationAccuracy: (data['location_accuracy'] as num?)?.toDouble(),
        notes: data['notes'] as String?,
        deviceTimestamp:
            data['device_timestamp'] as String? ??
            DateTime.now().toIso8601String(),
      );

      // Try to sync with patrol-specific endpoint first
      if (data['patrol_id'] != null) {
        try {
          final response = await ApiService.instance.post<Map<String, dynamic>>(
            '${AppConstants.mobileApiBase}/patrols/${data['patrol_id']}/checkpoints/visit',
            data: visitRequest.toJson(),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            await _databaseService.markItemSynced(
              'offline_checkpoint_visits',
              data['id'],
            );
            return true;
          }
        } catch (e) {
          print('Patrol-specific sync failed, trying generic endpoint: $e');
        }
      }

      // Fallback to generic checkpoint visit endpoint
      final response = await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.checkpointsEndpoint}/visit',
        data: visitRequest.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _databaseService.markItemSynced(
          'offline_checkpoint_visits',
          data['id'],
        );
        return true;
      }

      return false;
    } catch (e) {
      await _handleSyncError('checkpoint_visit', data['id'], e.toString());
      return false;
    }
  }

  /// Sync patrol action to backend
  Future<bool> _syncPatrolAction(Map<String, dynamic> data) async {
    try {
      final actionRequest = PatrolActionRequest(
        action: data['action_type'],
        latitude: data['latitude'],
        longitude: data['longitude'],
        locationAccuracy: data['location_accuracy'],
        notes: data['notes'],
        reason: data['reason'],
        deviceTimestamp: data['device_timestamp'],
      );

      final response = await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/${data['patrol_id']}/action',
        data: actionRequest.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _databaseService.markItemSynced(
          'offline_patrol_actions',
          data['id'],
        );
        return true;
      }

      return false;
    } catch (e) {
      await _handleSyncError('patrol_action', data['id'], e.toString());
      return false;
    }
  }

  /// Handle sync errors with retry logic
  Future<void> _handleSyncError(String type, int id, String error) async {
    final tableName = type == 'checkpoint_visit'
        ? 'offline_checkpoint_visits'
        : 'offline_patrol_actions';

    await _databaseService.markItemSyncFailed(tableName, id, error);
  }

  /// Download and cache data for offline use
  Future<bool> downloadDataForOfflineUse({int? siteId, int? userId}) async {
    if (!_connectivityService.isOnline) {
      print('Cannot download data: offline');
      return false;
    }

    try {
      print('Downloading data for offline use...');

      // Download and cache checkpoints
      await _downloadCheckpoints(siteId);

      // Download and cache assigned patrols
      await _downloadPatrols(userId);

      print('Offline data download completed');
      return true;
    } catch (e) {
      print('Error downloading offline data: $e');
      return false;
    }
  }

  /// Download and cache checkpoints
  Future<void> _downloadCheckpoints(int? siteId) async {
    try {
      final queryParams = <String, dynamic>{};
      if (siteId != null) queryParams['site_id'] = siteId;

      final response = await ApiService.instance.get<Map<String, dynamic>>(
        AppConstants.checkpointsEndpoint,
        queryParameters: queryParams,
      );

      final List<dynamic> checkpointsData =
          response.data?['checkpoints'] ?? response.data?['data'] ?? [];

      for (final checkpointData in checkpointsData) {
        final checkpoint = Checkpoint.fromJson(checkpointData);
        await _databaseService.cacheCheckpoint(checkpoint);
      }

      print('Cached ${checkpointsData.length} checkpoints');
    } catch (e) {
      print('Error downloading checkpoints: $e');
    }
  }

  /// Download and cache patrols
  Future<void> _downloadPatrols(int? userId) async {
    try {
      final response = await ApiService.instance.get<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/assigned',
      );

      final List<dynamic> patrolsData =
          response.data?['patrols'] ?? response.data?['data'] ?? [];

      for (final patrolData in patrolsData) {
        final patrol = Patrol.fromJson(patrolData);
        await _databaseService.cachePatrol(patrol);
      }

      print('Cached ${patrolsData.length} patrols');
    } catch (e) {
      print('Error downloading patrols: $e');
    }
  }

  /// Handle conflict resolution when sync fails due to conflicts
  Future<bool> resolveConflict({
    required String itemType,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.serverWins,
  }) async {
    print('Resolving conflict for $itemType with strategy: $strategy');

    switch (strategy) {
      case ConflictResolutionStrategy.serverWins:
        // Server data takes precedence, discard local changes
        final tableName = itemType == 'checkpoint_visit'
            ? 'offline_checkpoint_visits'
            : 'offline_patrol_actions';
        await _databaseService.markItemSynced(tableName, localData['id']);
        return true;

      case ConflictResolutionStrategy.clientWins:
        // Force sync local data, overriding server
        return await _forceSyncItem(itemType, localData);

      case ConflictResolutionStrategy.merge:
        // Attempt to merge data (simplified merge logic)
        final mergedData = _mergeData(localData, serverData);
        return await _forceSyncItem(itemType, mergedData);

      case ConflictResolutionStrategy.manual:
        // Requires manual intervention - mark for manual review
        return false;
    }
  }

  /// Force sync an item (used in conflict resolution)
  Future<bool> _forceSyncItem(
    String itemType,
    Map<String, dynamic> data,
  ) async {
    // This would implement forced sync with conflict override
    // For now, use the same sync logic
    return await _syncSingleItem({'type': itemType, 'data': data});
  }

  /// Simple data merge logic
  Map<String, dynamic> _mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
  ) {
    // Simple merge: prefer local timestamps, server for other data
    final merged = Map<String, dynamic>.from(serverData);
    merged['device_timestamp'] = localData['device_timestamp'];
    merged['notes'] = localData['notes'] ?? serverData['notes'];
    return merged;
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    final dbStats = await _databaseService.getSyncStatistics();

    return {
      ...dbStats,
      'is_syncing': _isSyncing,
      'is_online': _connectivityService.isOnline,
      'last_sync': DateTime.now()
          .toIso8601String(), // TODO: Store actual last sync time
    };
  }

  /// Force immediate sync
  Future<bool> forceSyncNow() async {
    if (!_connectivityService.isOnline) {
      throw Exception('Cannot sync: device is offline');
    }

    return await syncPendingData();
  }

  /// Sync a specific operation (used by background sync optimization)
  Future<SyncResult> syncOperation(SyncOperation operation) async {
    try {
      final success = await _syncSingleItem({
        'type': operation.type,
        'data': operation.data,
      });

      return SyncResult(
        operation: operation,
        success: success,
        error: success ? null : 'Sync failed',
        syncedAt: success ? DateTime.now() : null,
      );
    } catch (e) {
      return SyncResult(
        operation: operation,
        success: false,
        error: e.toString(),
        syncedAt: null,
      );
    }
  }

  /// Clean up old data
  Future<void> cleanup() async {
    await _databaseService.cleanOldCache();
    await _databaseService.clearSyncedItems();
  }

  /// Sync only critical data (emergency alerts, panic alerts)
  Future<void> syncCriticalData() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      print('Syncing critical data only...');

      // Sync emergency alerts and panic alerts only
      await _syncEmergencyData();

      print('Critical data sync completed');
      _syncStatusController.add(SyncStatus.completed);
    } catch (e) {
      print('Critical data sync failed: $e');
      _syncStatusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync recent data (last 24 hours)
  Future<void> syncRecentData() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      print('Syncing recent data...');

      // Sync data from last 24 hours
      final since = DateTime.now().subtract(const Duration(hours: 24));
      await _syncDataSince(since);

      print('Recent data sync completed');
      _syncStatusController.add(SyncStatus.completed);
    } catch (e) {
      print('Recent data sync failed: $e');
      _syncStatusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  /// Perform full synchronization
  Future<void> performFullSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      print('Performing full sync...');

      // Upload all pending offline data
      await _uploadPendingData();

      // Download updates
      final result = await downloadDataForOfflineUse();

      if (result) {
        print('Full sync completed successfully');
        _syncStatusController.add(SyncStatus.completed);
      } else {
        print('Full sync completed with warnings');
        _syncStatusController.add(SyncStatus.completed);
      }
    } catch (e) {
      print('Full sync failed: $e');
      _syncStatusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  /// Check if there's pending offline data to sync
  Future<bool> hasPendingOfflineData() async {
    try {
      // Check for pending checkpoint visits
      final pendingCheckpoints = await _databaseService
          .getPendingCheckpointVisits();
      if (pendingCheckpoints.isNotEmpty) return true;

      // Check for pending patrol actions
      final pendingPatrols = await _databaseService.getPendingPatrolActions();
      if (pendingPatrols.isNotEmpty) return true;

      // Check for pending emergency data
      final pendingEmergency = await _databaseService.getPendingEmergencyData();
      if (pendingEmergency.isNotEmpty) return true;

      return false;
    } catch (e) {
      print('Error checking pending offline data: $e');
      return false;
    }
  }

  /// Sync offline data when back online
  Future<void> syncOfflineData() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      print('Syncing offline data...');

      // Upload all pending offline data
      await _uploadPendingData();

      print('Offline data sync completed');
      _syncStatusController.add(SyncStatus.completed);
    } catch (e) {
      print('Offline data sync failed: $e');
      _syncStatusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync emergency data (critical priority)
  Future<void> _syncEmergencyData() async {
    try {
      // Upload pending emergency alerts
      final pendingEmergency = await _databaseService.getPendingEmergencyData();

      for (final emergencyData in pendingEmergency) {
        try {
          // Upload emergency data to backend
          await _uploadEmergencyData(emergencyData);
        } catch (e) {
          print('Failed to upload emergency data: $e');
        }
      }
    } catch (e) {
      print('Error syncing emergency data: $e');
    }
  }

  /// Sync data since a specific date
  Future<void> _syncDataSince(DateTime since) async {
    try {
      // Upload pending data first
      await _uploadPendingData();

      // Download recent updates
      await _downloadRecentUpdates(since);
    } catch (e) {
      print('Error syncing data since $since: $e');
    }
  }

  /// Upload emergency data to backend
  Future<void> _uploadEmergencyData(Map<String, dynamic> emergencyData) async {
    // Implementation would depend on specific emergency data structure
    print('Uploading emergency data: ${emergencyData['id']}');
  }

  /// Upload all pending checkpoint visits and patrol actions
  Future<void> _uploadPendingData() async {
    try {
      // Upload pending checkpoint visits
      final pendingCheckpoints = await _databaseService
          .getPendingCheckpointVisits();
      for (final cp in pendingCheckpoints) {
        try {
          await _syncCheckpointVisit(cp);
        } catch (e) {
          print('Failed to upload checkpoint visit id=${cp['id']}: $e');
        }
      }

      // Upload pending patrol actions
      final pendingPatrols = await _databaseService.getPendingPatrolActions();
      for (final pa in pendingPatrols) {
        try {
          await _syncPatrolAction(pa);
        } catch (e) {
          print('Failed to upload patrol action id=${pa['id']}: $e');
        }
      }
    } catch (e) {
      print('Error uploading pending data: $e');
    }
  }

  /// Download recent updates from backend
  Future<void> _downloadRecentUpdates(DateTime since) async {
    try {
      // Download recent checkpoints
      await _downloadCheckpointsSince(null, since);

      // Download recent patrols
      await _downloadPatrolsSince(null, since);

      print('Downloaded recent updates since $since');
    } catch (e) {
      print('Error downloading recent updates: $e');
    }
  }

  /// Download checkpoints with date filter
  Future<void> _downloadCheckpointsSince(int? siteId, DateTime since) async {
    try {
      final queryParams = <String, dynamic>{'since': since.toIso8601String()};
      if (siteId != null) queryParams['site_id'] = siteId;

      final response = await ApiService.instance.get<Map<String, dynamic>>(
        AppConstants.checkpointsEndpoint,
        queryParameters: queryParams,
      );

      final List<dynamic> checkpointsData =
          response.data?['checkpoints'] ?? response.data?['data'] ?? [];

      for (final checkpointData in checkpointsData) {
        final checkpoint = Checkpoint.fromJson(checkpointData);
        await _databaseService.cacheCheckpoint(checkpoint);
      }

      print('Cached ${checkpointsData.length} recent checkpoints');
    } catch (e) {
      print('Error downloading recent checkpoints: $e');
    }
  }

  /// Download patrols with date filter
  Future<void> _downloadPatrolsSince(int? userId, DateTime since) async {
    try {
      final queryParams = <String, dynamic>{'since': since.toIso8601String()};
      if (userId != null) queryParams['assigned_to'] = userId;

      final response = await ApiService.instance.get<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/assigned',
        queryParameters: queryParams,
      );

      final List<dynamic> patrolsData =
          response.data?['patrols'] ?? response.data?['data'] ?? [];

      for (final patrolData in patrolsData) {
        final patrol = Patrol.fromJson(patrolData);
        await _databaseService.cachePatrol(patrol);
      }

      print('Cached ${patrolsData.length} recent patrols');
    } catch (e) {
      print('Error downloading recent patrols: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }
}

/// Sync status enum
enum SyncStatus { idle, syncing, completed, error }

/// Conflict resolution strategies
enum ConflictResolutionStrategy { serverWins, clientWins, merge, manual }
