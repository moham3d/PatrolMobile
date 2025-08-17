import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'performance_monitoring_service.dart';
import 'sync_service.dart';

/// Service for optimizing background synchronization based on performance and connectivity
class BackgroundSyncOptimizationService {
  static BackgroundSyncOptimizationService? _instance;
  static BackgroundSyncOptimizationService get instance => _instance ??= BackgroundSyncOptimizationService._internal();
  
  BackgroundSyncOptimizationService._internal();

  final PerformanceMonitoringService _performanceService = PerformanceMonitoringService.instance;
  final SyncService _syncService = SyncService.instance;
  final Connectivity _connectivity = Connectivity();
  
  Timer? _syncTimer;
  bool _isSyncEnabled = true;
  ConnectivityResult _currentConnectivity = ConnectivityResult.none;
  
  // Sync optimization settings
  int _syncIntervalMinutes = 15; // Default 15 minutes
  int _maxBatchSize = 50; // Maximum items per sync batch
  bool _wifiOnlyMode = false;
  bool _adaptiveSyncEnabled = true;
  
  // Battery-optimized sync intervals (minutes)
  static const Map<int, int> _batteryOptimizedIntervals = {
    100: 10,  // 80-100% battery: every 10 minutes
    80: 15,   // 60-79% battery: every 15 minutes
    60: 30,   // 40-59% battery: every 30 minutes
    40: 60,   // 20-39% battery: every hour
    20: 120,  // 10-19% battery: every 2 hours
    10: 300,  // <10% battery: every 5 hours
  };
  
  // Connectivity-based settings
  static const Map<ConnectivityResult, Map<String, dynamic>> _connectivitySettings = {
    ConnectivityResult.wifi: {
      'max_batch_size': 100,
      'compression_enabled': false,
      'retry_attempts': 3,
    },
    ConnectivityResult.mobile: {
      'max_batch_size': 25,
      'compression_enabled': true,
      'retry_attempts': 2,
    },
    ConnectivityResult.ethernet: {
      'max_batch_size': 100,
      'compression_enabled': false,
      'retry_attempts': 3,
    },
  };

  // Sync queue for batching operations
  final List<SyncOperation> _pendingSyncOperations = [];
  int _consecutiveFailures = 0;
  DateTime? _lastSyncAttempt;
  DateTime? _lastSuccessfulSync;

  // Getters
  bool get isSyncEnabled => _isSyncEnabled;
  int get syncIntervalMinutes => _syncIntervalMinutes;
  ConnectivityResult get currentConnectivity => _currentConnectivity;
  bool get wifiOnlyMode => _wifiOnlyMode;
  bool get adaptiveSyncEnabled => _adaptiveSyncEnabled;
  int get pendingOperationsCount => _pendingSyncOperations.length;
  DateTime? get lastSyncAttempt => _lastSyncAttempt;
  DateTime? get lastSuccessfulSync => _lastSuccessfulSync;

  /// Initialize background sync optimization
  Future<void> initialize() async {
    await _checkConnectivity();
    _startConnectivityMonitoring();
    _optimizeSyncSettings();
    _startBackgroundSync();
  }

  /// Check current connectivity
  Future<void> _checkConnectivity() async {
    try {
      _currentConnectivity = await _connectivity.checkConnectivity();
    } catch (e) {
      print('Error checking connectivity: $e');
      _currentConnectivity = ConnectivityResult.none;
    }
  }

  /// Start monitoring connectivity changes
  void _startConnectivityMonitoring() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _currentConnectivity = result;
      _optimizeSyncSettings();
      
      // Trigger immediate sync when connectivity is restored
      if (result != ConnectivityResult.none && _pendingSyncOperations.isNotEmpty) {
        _performSync();
      }
    });
  }

  /// Optimize sync settings based on battery and connectivity
  void _optimizeSyncSettings() {
    final batteryLevel = _performanceService.batteryLevel;
    final isLowPowerMode = _performanceService.isLowPowerMode;
    
    // Optimize sync interval based on battery
    int baseInterval = 15; // Default
    for (final threshold in _batteryOptimizedIntervals.keys.toList()..sort((a, b) => b.compareTo(a))) {
      if (batteryLevel >= threshold) {
        baseInterval = _batteryOptimizedIntervals[threshold]!;
        break;
      }
    }
    
    // Apply low power mode multiplier
    if (isLowPowerMode) {
      baseInterval *= 2;
    }
    
    _syncIntervalMinutes = baseInterval;
    
    // Optimize batch size based on connectivity
    final connectivitySettings = _connectivitySettings[_currentConnectivity];
    if (connectivitySettings != null) {
      _maxBatchSize = connectivitySettings['max_batch_size'] as int;
    } else {
      _maxBatchSize = 10; // Conservative default for poor connectivity
    }
    
    // Enable WiFi-only mode in low battery situations
    if (batteryLevel <= 20 || isLowPowerMode) {
      _wifiOnlyMode = true;
    } else {
      _wifiOnlyMode = false;
    }
    
    print('Sync settings optimized: interval=${_syncIntervalMinutes}min, '
          'batch_size=$_maxBatchSize, wifi_only=$_wifiOnlyMode');
  }

  /// Start background sync timer
  void _startBackgroundSync() {
    if (!_isSyncEnabled) return;
    
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(minutes: _syncIntervalMinutes),
      (_) => _performSync(),
    );
  }

  /// Perform sync operation
  Future<void> _performSync() async {
    if (!_isSyncEnabled || !_shouldSync()) {
      return;
    }
    
    _lastSyncAttempt = DateTime.now();
    
    try {
      // Batch pending operations
      final batch = _getBatchToSync();
      if (batch.isEmpty) {
        return;
      }
      
      print('Starting sync batch of ${batch.length} operations...');
      
      // Perform sync operations
      final results = await _syncBatch(batch);
      
      // Process results
      _processSyncResults(results);
      
      _lastSuccessfulSync = DateTime.now();
      _consecutiveFailures = 0;
      
      print('Sync completed successfully');
      
    } catch (e) {
      _consecutiveFailures++;
      print('Sync failed: $e (consecutive failures: $_consecutiveFailures)');
      
      // Implement exponential backoff for failures
      if (_consecutiveFailures >= 3) {
        _syncIntervalMinutes = (_syncIntervalMinutes * 1.5).round();
        _startBackgroundSync();
      }
    }
  }

  /// Check if sync should be performed
  bool _shouldSync() {
    // Don't sync if no connectivity
    if (_currentConnectivity == ConnectivityResult.none) {
      return false;
    }
    
    // Check WiFi-only mode
    if (_wifiOnlyMode && _currentConnectivity != ConnectivityResult.wifi) {
      return false;
    }
    
    // Don't sync in critical battery conditions
    if (_performanceService.isCriticalBatteryLevel) {
      return false;
    }
    
    // Check if we have pending operations
    return _pendingSyncOperations.isNotEmpty;
  }

  /// Get batch of operations to sync
  List<SyncOperation> _getBatchToSync() {
    final batchSize = _maxBatchSize;
    
    if (_pendingSyncOperations.length <= batchSize) {
      return List.from(_pendingSyncOperations);
    }
    
    // Prioritize operations by importance
    _pendingSyncOperations.sort((a, b) => b.priority.compareTo(a.priority));
    return _pendingSyncOperations.take(batchSize).toList();
  }

  /// Sync a batch of operations
  Future<List<SyncResult>> _syncBatch(List<SyncOperation> batch) async {
    final results = <SyncResult>[];
    
    for (final operation in batch) {
      try {
        final result = await _syncService.syncOperation(operation);
        results.add(result);
      } catch (e) {
        results.add(SyncResult(
          operation: operation,
          success: false,
          error: e.toString(),
        ));
      }
    }
    
    return results;
  }

  /// Process sync results
  void _processSyncResults(List<SyncResult> results) {
    for (final result in results) {
      if (result.success) {
        // Remove successful operations from pending queue
        _pendingSyncOperations.removeWhere((op) => op.id == result.operation.id);
      } else {
        // Increment retry count for failed operations
        result.operation.retryCount++;
        
        // Remove operations that have exceeded max retries
        if (result.operation.retryCount >= result.operation.maxRetries) {
          _pendingSyncOperations.removeWhere((op) => op.id == result.operation.id);
          print('Operation ${result.operation.id} removed after max retries');
        }
      }
    }
  }

  /// Add operation to sync queue
  void queueSyncOperation(SyncOperation operation) {
    _pendingSyncOperations.add(operation);
    
    // Trigger immediate sync for high-priority operations if connected
    if (operation.priority >= SyncPriority.high && 
        _currentConnectivity != ConnectivityResult.none) {
      _performSync();
    }
  }

  /// Force immediate sync
  Future<void> forceSyncNow() async {
    print('Force sync requested');
    await _performSync();
  }

  /// Enable background sync
  void enableBackgroundSync() {
    if (_isSyncEnabled) return;
    
    _isSyncEnabled = true;
    _startBackgroundSync();
    print('Background sync enabled');
  }

  /// Disable background sync
  void disableBackgroundSync() {
    _isSyncEnabled = false;
    _syncTimer?.cancel();
    _syncTimer = null;
    print('Background sync disabled');
  }

  /// Update sync settings
  void updateSyncSettings({
    int? intervalMinutes,
    int? maxBatchSize,
    bool? wifiOnlyMode,
    bool? adaptiveSyncEnabled,
  }) {
    bool settingsChanged = false;
    
    if (intervalMinutes != null && intervalMinutes > 0) {
      _syncIntervalMinutes = intervalMinutes;
      settingsChanged = true;
    }
    
    if (maxBatchSize != null && maxBatchSize > 0) {
      _maxBatchSize = maxBatchSize;
    }
    
    if (wifiOnlyMode != null) {
      _wifiOnlyMode = wifiOnlyMode;
    }
    
    if (adaptiveSyncEnabled != null) {
      _adaptiveSyncEnabled = adaptiveSyncEnabled;
    }
    
    if (settingsChanged && _isSyncEnabled) {
      _startBackgroundSync();
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    return {
      'sync_enabled': _isSyncEnabled,
      'sync_interval_minutes': _syncIntervalMinutes,
      'pending_operations': _pendingSyncOperations.length,
      'consecutive_failures': _consecutiveFailures,
      'last_sync_attempt': _lastSyncAttempt?.toIso8601String(),
      'last_successful_sync': _lastSuccessfulSync?.toIso8601String(),
      'current_connectivity': _currentConnectivity.toString(),
      'wifi_only_mode': _wifiOnlyMode,
      'max_batch_size': _maxBatchSize,
    };
  }

  /// Clear all pending operations
  void clearPendingOperations() {
    _pendingSyncOperations.clear();
    print('All pending sync operations cleared');
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _pendingSyncOperations.clear();
  }
}

/// Sync operation model
class SyncOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final SyncPriority priority;
  final int maxRetries;
  int retryCount;
  final DateTime createdAt;

  SyncOperation({
    required this.id,
    required this.type,
    required this.data,
    this.priority = SyncPriority.normal,
    this.maxRetries = 3,
    this.retryCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Sync priority levels
enum SyncPriority {
  low(1),
  normal(2),
  high(3),
  critical(4);

  const SyncPriority(this.value);
  final int value;
}

/// Sync result model
class SyncResult {
  final SyncOperation operation;
  final bool success;
  final String? error;
  final Map<String, dynamic>? response;

  SyncResult({
    required this.operation,
    required this.success,
    this.error,
    this.response,
  });
}