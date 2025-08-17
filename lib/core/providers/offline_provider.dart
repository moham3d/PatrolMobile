import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../services/offline_checkpoint_service.dart';

/// Provider for database service
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

/// Provider for connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

/// Provider for sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService.instance;
});

/// Provider for offline checkpoint service
final offlineCheckpointServiceProvider = Provider<OfflineCheckpointService>((ref) {
  return OfflineCheckpointService.instance;
});

/// Connectivity state
sealed class ConnectivityState {
  const ConnectivityState();
}

class ConnectivityOnline extends ConnectivityState {
  const ConnectivityOnline();
}

class ConnectivityOffline extends ConnectivityState {
  const ConnectivityOffline();
}

class ConnectivityChecking extends ConnectivityState {
  const ConnectivityChecking();
}

/// Connectivity notifier
class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final ConnectivityService _connectivityService;

  ConnectivityNotifier(this._connectivityService) : super(const ConnectivityChecking()) {
    _initialize();
  }

  void _initialize() {
    // Set initial state
    state = _connectivityService.isOnline 
        ? const ConnectivityOnline() 
        : const ConnectivityOffline();
    
    // Listen to connectivity changes
    _connectivityService.connectivityStream.listen((isOnline) {
      state = isOnline ? const ConnectivityOnline() : const ConnectivityOffline();
    });
  }

  /// Force connectivity check
  Future<void> checkConnectivity() async {
    state = const ConnectivityChecking();
    await _connectivityService.forceConnectivityCheck();
  }

  /// Get connectivity info
  Future<Map<String, dynamic>> getConnectivityInfo() async {
    return await _connectivityService.getConnectivityInfo();
  }
}

/// Connectivity provider
final connectivityNotifierProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return ConnectivityNotifier(connectivityService);
});

/// Sync state
sealed class SyncState {
  const SyncState();
}

class SyncIdle extends SyncState {
  const SyncIdle();
}

class SyncInProgress extends SyncState {
  const SyncInProgress();
}

class SyncCompleted extends SyncState {
  final int syncedItems;
  final DateTime completedAt;
  
  const SyncCompleted({
    required this.syncedItems,
    required this.completedAt,
  });
}

class SyncError extends SyncState {
  final String message;
  final DateTime errorAt;
  
  const SyncError({
    required this.message,
    required this.errorAt,
  });
}

/// Sync notifier
class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;

  SyncNotifier(this._syncService) : super(const SyncIdle()) {
    _initialize();
  }

  void _initialize() {
    // Listen to sync status changes
    _syncService.syncStatusStream.listen((status) {
      switch (status) {
        case SyncStatus.idle:
          state = const SyncIdle();
          break;
        case SyncStatus.syncing:
          state = const SyncInProgress();
          break;
        case SyncStatus.completed:
          state = SyncCompleted(
            syncedItems: 0, // TODO: Get actual count
            completedAt: DateTime.now(),
          );
          break;
        case SyncStatus.error:
          state = SyncError(
            message: 'Sync failed',
            errorAt: DateTime.now(),
          );
          break;
      }
    });
  }

  /// Trigger manual sync
  Future<bool> triggerSync() async {
    try {
      return await _syncService.forceSyncNow();
    } catch (e) {
      state = SyncError(
        message: e.toString(),
        errorAt: DateTime.now(),
      );
      return false;
    }
  }

  /// Download data for offline use
  Future<bool> downloadOfflineData({int? siteId, int? userId}) async {
    return await _syncService.downloadDataForOfflineUse(
      siteId: siteId,
      userId: userId,
    );
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    return await _syncService.getSyncStatistics();
  }

  /// Clean up old data
  Future<void> cleanup() async {
    await _syncService.cleanup();
  }
}

/// Sync provider
final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SyncNotifier(syncService);
});

/// Offline checkpoint scan state
sealed class OfflineCheckpointScanState {
  const OfflineCheckpointScanState();
}

class OfflineCheckpointScanIdle extends OfflineCheckpointScanState {
  const OfflineCheckpointScanIdle();
}

class OfflineCheckpointScanScanning extends OfflineCheckpointScanState {
  const OfflineCheckpointScanScanning();
}

class OfflineCheckpointScanSuccess extends OfflineCheckpointScanState {
  final CheckpointScanResult result;
  
  const OfflineCheckpointScanSuccess(this.result);
}

class OfflineCheckpointScanError extends OfflineCheckpointScanState {
  final String message;
  final String? errorCode;
  
  const OfflineCheckpointScanError(this.message, {this.errorCode});
}

/// Offline checkpoint scan notifier
class OfflineCheckpointScanNotifier extends StateNotifier<OfflineCheckpointScanState> {
  final OfflineCheckpointService _checkpointService;

  OfflineCheckpointScanNotifier(this._checkpointService) 
      : super(const OfflineCheckpointScanIdle());

  /// Scan checkpoint with offline support
  Future<void> scanCheckpoint({
    required String code,
    required String scanMethod,
    int? patrolId,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) async {
    state = const OfflineCheckpointScanScanning();

    try {
      final result = await _checkpointService.scanCheckpoint(
        code: code,
        scanMethod: scanMethod,
        patrolId: patrolId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        notes: notes,
      );

      if (result.success) {
        state = OfflineCheckpointScanSuccess(result);
      } else {
        state = OfflineCheckpointScanError(
          result.message,
          errorCode: result.errorCode,
        );
      }
    } catch (e) {
      state = OfflineCheckpointScanError(e.toString());
    }
  }

  /// Reset to idle state
  void reset() {
    state = const OfflineCheckpointScanIdle();
  }

  /// Get offline statistics
  Future<Map<String, dynamic>> getOfflineStatistics() async {
    return await _checkpointService.getOfflineStatistics();
  }
}

/// Offline checkpoint scan provider
final offlineCheckpointScanNotifierProvider = 
    StateNotifierProvider<OfflineCheckpointScanNotifier, OfflineCheckpointScanState>((ref) {
  final checkpointService = ref.watch(offlineCheckpointServiceProvider);
  return OfflineCheckpointScanNotifier(checkpointService);
});

/// Offline queue statistics provider
final offlineQueueStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getSyncStatistics();
});

/// Current connectivity status provider (simplified)
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityState = ref.watch(connectivityNotifierProvider);
  return connectivityState is ConnectivityOnline;
});