import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'performance_monitoring_service.dart';
import 'sync_service.dart';
import 'connectivity_service.dart';
import 'auth_service.dart';

/// Intelligent sync scheduling service using workmanager for background tasks
class IntelligentSyncSchedulingService {
  static IntelligentSyncSchedulingService? _instance;
  static IntelligentSyncSchedulingService get instance =>
      _instance ??= IntelligentSyncSchedulingService._internal();

  IntelligentSyncSchedulingService._internal();

  static const String _syncTaskName = 'intelligent_sync_task';
  static const String _batteryOptimizedSyncTask = 'battery_optimized_sync';
  static const String _criticalDataSyncTask = 'critical_data_sync';
  static const String _offlineDataSyncTask = 'offline_data_sync';

  final PerformanceMonitoringService _performanceService =
      PerformanceMonitoringService.instance;
  final SyncService _syncService = SyncService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final AuthService _authService = AuthService.instance;

  Timer? _adaptiveScheduleTimer;
  bool _isInitialized = false;

  // Scheduling configuration
  Duration _currentSyncInterval = const Duration(minutes: 15);
  final Duration _lastKnownGoodInterval = const Duration(minutes: 15);

  // Battery-optimized intervals
  static const Map<int, Duration> _batteryOptimizedIntervals = {
    100: Duration(minutes: 10), // 80-100% battery: every 10 minutes
    80: Duration(minutes: 15), // 60-79% battery: every 15 minutes
    60: Duration(minutes: 30), // 40-59% battery: every 30 minutes
    40: Duration(minutes: 60), // 20-39% battery: every hour
    20: Duration(minutes: 120), // 10-19% battery: every 2 hours
    10: Duration(minutes: 300), // <10% battery: every 5 hours
    0: Duration(minutes: 600), // Critical battery: every 10 hours
  };

  // Connectivity-based intervals
  static const Map<ConnectivityResult, Duration> _connectivityBasedIntervals = {
    ConnectivityResult.wifi: Duration(minutes: 10),
    ConnectivityResult.mobile: Duration(minutes: 20),
    ConnectivityResult.ethernet: Duration(minutes: 5),
    ConnectivityResult.none: Duration(
      hours: 1,
    ), // Retry less frequently when offline
  };

  /// Initialize the intelligent sync scheduling service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize workmanager
      await Workmanager().initialize(
        _callbackDispatcher,
        isInDebugMode: false, // Set to false in production
      );

      print('IntelligentSyncSchedulingService: Workmanager initialized');

      // Start adaptive scheduling
      await _startAdaptiveScheduling();

      // Register background tasks
      await _registerBackgroundTasks();

      _isInitialized = true;
      print('IntelligentSyncSchedulingService: Initialization complete');
    } catch (e) {
      print('IntelligentSyncSchedulingService: Failed to initialize: $e');
    }
  }

  /// Start adaptive scheduling based on device conditions
  Future<void> _startAdaptiveScheduling() async {
    // Cancel existing timer
    _adaptiveScheduleTimer?.cancel();

    // Start timer that adjusts sync intervals based on performance
    _adaptiveScheduleTimer = Timer.periodic(
      const Duration(minutes: 5), // Check every 5 minutes
      (timer) async => await _adaptSyncSchedule(),
    );

    // Do an initial adaptation
    await _adaptSyncSchedule();
  }

  /// Adapt sync schedule based on current device conditions
  Future<void> _adaptSyncSchedule() async {
    try {
      final batteryLevel = _performanceService.batteryLevel;
      final rawConnectivity = await Connectivity().checkConnectivity();
      final connectivity = _normalizeConnectivity(rawConnectivity);
      final isLowPowerMode = _performanceService.isLowPowerMode;

      Duration newInterval = _calculateOptimalInterval(
        batteryLevel: batteryLevel,
        connectivity: connectivity,
        isLowPowerMode: isLowPowerMode,
      );

      // Only update if interval changed significantly (more than 5 minutes difference)
      if ((_currentSyncInterval - newInterval).abs() >
          const Duration(minutes: 5)) {
        _currentSyncInterval = newInterval;
        await _rescheduleBackgroundSync();

        print(
          'IntelligentSyncSchedulingService: Adapted sync interval to ${newInterval.inMinutes} minutes '
          '(battery: $batteryLevel%, connectivity: $connectivity, low power: $isLowPowerMode)',
        );
      }
    } catch (e) {
      print('IntelligentSyncSchedulingService: Error adapting schedule: $e');
    }
  }

  ConnectivityResult _normalizeConnectivity(dynamic event) {
    if (event is ConnectivityResult) return event;
    if (event is List && event.isNotEmpty) {
      final first = event.first;
      if (first is ConnectivityResult) return first;
    }
    return ConnectivityResult.none;
  }

  /// Calculate optimal sync interval based on device conditions
  Duration _calculateOptimalInterval({
    required int batteryLevel,
    required ConnectivityResult connectivity,
    required bool isLowPowerMode,
  }) {
    // Start with battery-optimized interval
    Duration interval = _getBatteryOptimizedInterval(batteryLevel);

    // Adjust for connectivity
    final connectivityInterval =
        _connectivityBasedIntervals[connectivity] ??
        const Duration(minutes: 30);

    // Use the longer of the two for battery conservation
    if (connectivityInterval > interval) {
      interval = connectivityInterval;
    }

    // In low power mode, double the interval
    if (isLowPowerMode) {
      interval = Duration(minutes: interval.inMinutes * 2);
    }

    // Ensure minimum interval of 5 minutes and maximum of 12 hours
    if (interval.inMinutes < 5) {
      interval = const Duration(minutes: 5);
    } else if (interval.inHours > 12) {
      interval = const Duration(hours: 12);
    }

    return interval;
  }

  /// Get battery-optimized sync interval
  Duration _getBatteryOptimizedInterval(int batteryLevel) {
    for (final entry in _batteryOptimizedIntervals.entries) {
      if (batteryLevel >= entry.key) {
        return entry.value;
      }
    }
    return _batteryOptimizedIntervals[0]!; // Fallback to most conservative
  }

  /// Register background sync tasks
  Future<void> _registerBackgroundTasks() async {
    try {
      // Cancel existing tasks
      await Workmanager().cancelAll();

      // Register periodic sync task
      await Workmanager().registerPeriodicTask(
        _syncTaskName,
        _syncTaskName,
        frequency: _currentSyncInterval,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false, // Allow even on low battery
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: true,
        ),
        inputData: {'task_type': 'intelligent_sync', 'priority': 'normal'},
      );

      // Register critical data sync (more frequent, for emergency data)
      await Workmanager().registerPeriodicTask(
        _criticalDataSyncTask,
        _criticalDataSyncTask,
        frequency: const Duration(
          minutes: 5,
        ), // Always every 5 minutes for critical data
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        inputData: {'task_type': 'critical_sync', 'priority': 'high'},
      );

      // Register offline data sync (when back online)
      await Workmanager().registerPeriodicTask(
        _offlineDataSyncTask,
        _offlineDataSyncTask,
        frequency: const Duration(
          minutes: 2,
        ), // Check frequently for connectivity
        constraints: Constraints(networkType: NetworkType.connected),
        inputData: {'task_type': 'offline_sync', 'priority': 'normal'},
      );

      print('IntelligentSyncSchedulingService: Background tasks registered');
    } catch (e) {
      print('IntelligentSyncSchedulingService: Failed to register tasks: $e');
    }
  }

  /// Reschedule background sync with new interval
  Future<void> _rescheduleBackgroundSync() async {
    try {
      // Cancel existing sync task
      await Workmanager().cancelByUniqueName(_syncTaskName);

      // Register with new interval
      await Workmanager().registerPeriodicTask(
        _syncTaskName,
        _syncTaskName,
        frequency: _currentSyncInterval,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: true,
        ),
        inputData: {
          'task_type': 'intelligent_sync',
          'priority': 'normal',
          'interval_minutes': _currentSyncInterval.inMinutes,
        },
      );

      print(
        'IntelligentSyncSchedulingService: Rescheduled sync task with ${_currentSyncInterval.inMinutes} minute interval',
      );
    } catch (e) {
      print('IntelligentSyncSchedulingService: Failed to reschedule: $e');
    }
  }

  /// Trigger immediate sync for critical data
  Future<void> triggerImmediateSync({
    bool criticalOnly = false,
    String? reason,
  }) async {
    try {
      await Workmanager().registerOneOffTask(
        'immediate_sync_${DateTime.now().millisecondsSinceEpoch}',
        _syncTaskName,
        constraints: Constraints(networkType: NetworkType.connected),
        inputData: {
          'task_type': criticalOnly ? 'critical_sync' : 'immediate_sync',
          'priority': 'high',
          'reason': reason ?? 'manual_trigger',
        },
      );

      print(
        'IntelligentSyncSchedulingService: Triggered immediate sync (critical: $criticalOnly, reason: $reason)',
      );
    } catch (e) {
      print(
        'IntelligentSyncSchedulingService: Failed to trigger immediate sync: $e',
      );
    }
  }

  /// Pause all background sync (e.g., during low battery)
  Future<void> pauseBackgroundSync() async {
    try {
      await Workmanager().cancelAll();
      _adaptiveScheduleTimer?.cancel();
      print('IntelligentSyncSchedulingService: Background sync paused');
    } catch (e) {
      print('IntelligentSyncSchedulingService: Failed to pause sync: $e');
    }
  }

  /// Resume background sync
  Future<void> resumeBackgroundSync() async {
    try {
      await _registerBackgroundTasks();
      await _startAdaptiveScheduling();
      print('IntelligentSyncSchedulingService: Background sync resumed');
    } catch (e) {
      print('IntelligentSyncSchedulingService: Failed to resume sync: $e');
    }
  }

  /// Get current sync statistics
  Map<String, dynamic> getSyncStatistics() {
    return {
      'current_interval_minutes': _currentSyncInterval.inMinutes,
      'battery_level': _performanceService.batteryLevel,
      'is_low_power_mode': _performanceService.isLowPowerMode,
      'connectivity': _connectivityService.isOnline
          ? 'connected'
          : 'disconnected',
      'is_initialized': _isInitialized,
      'last_adaptation': DateTime.now().toIso8601String(),
    };
  }

  /// Dispose resources
  void dispose() {
    _adaptiveScheduleTimer?.cancel();
    _isInitialized = false;
  }
}

/// Background task dispatcher for workmanager
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print(
        'IntelligentSyncSchedulingService: Executing background task: $task',
      );

      final taskType = inputData?['task_type'] ?? 'unknown';
      final priority = inputData?['priority'] ?? 'normal';

      // Initialize services for background context
      final syncService = SyncService.instance;
      final authService = AuthService.instance;

      // Check if user is authenticated
      if (!authService.isAuthenticated) {
        print(
          'IntelligentSyncSchedulingService: User not authenticated, skipping sync',
        );
        return false;
      }

      switch (taskType) {
        case 'critical_sync':
          await _performCriticalSync(syncService);
          break;

        case 'offline_sync':
          await _performOfflineDataSync(syncService);
          break;

        case 'intelligent_sync':
        case 'immediate_sync':
        default:
          await _performIntelligentSync(syncService, priority);
          break;
      }

      print(
        'IntelligentSyncSchedulingService: Background task completed: $task',
      );
      return true;
    } catch (e) {
      print(
        'IntelligentSyncSchedulingService: Background task failed: $task, error: $e',
      );
      return false;
    }
  });
}

/// Perform critical data sync (emergency alerts, SOS)
Future<void> _performCriticalSync(SyncService syncService) async {
  try {
    // Sync only critical data - emergency alerts, panic alerts, etc.
    await syncService.syncCriticalData();
    print('IntelligentSyncSchedulingService: Critical sync completed');
  } catch (e) {
    print('IntelligentSyncSchedulingService: Critical sync failed: $e');
  }
}

/// Perform offline data sync when back online
Future<void> _performOfflineDataSync(SyncService syncService) async {
  try {
    // Check if there's pending offline data
    final hasPendingData = await syncService.hasPendingOfflineData();

    if (hasPendingData) {
      await syncService.syncOfflineData();
      print('IntelligentSyncSchedulingService: Offline data sync completed');
    }
  } catch (e) {
    print('IntelligentSyncSchedulingService: Offline data sync failed: $e');
  }
}

/// Perform intelligent sync based on current conditions
Future<void> _performIntelligentSync(
  SyncService syncService,
  String priority,
) async {
  try {
    final performanceService = PerformanceMonitoringService.instance;
    final batteryLevel = performanceService.batteryLevel;

    // Adjust sync scope based on battery level
    if (batteryLevel < 20) {
      // Low battery: only sync critical data
      await _performCriticalSync(syncService);
    } else if (batteryLevel < 50) {
      // Medium battery: sync recent data
      await syncService.syncRecentData();
    } else {
      // Good battery: full sync
      await syncService.performFullSync();
    }

    print(
      'IntelligentSyncSchedulingService: Intelligent sync completed (battery: $batteryLevel%, priority: $priority)',
    );
  } catch (e) {
    print('IntelligentSyncSchedulingService: Intelligent sync failed: $e');
  }
}
