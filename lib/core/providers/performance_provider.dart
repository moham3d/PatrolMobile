import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/performance_monitoring_service.dart';
import '../services/location_optimization_service.dart';
import '../services/background_sync_optimization_service.dart';

/// Performance monitoring service provider
final performanceServiceProvider = Provider<PerformanceMonitoringService>((ref) {
  return PerformanceMonitoringService.instance;
});

/// Location optimization service provider
final locationOptimizationServiceProvider = Provider<LocationOptimizationService>((ref) {
  return LocationOptimizationService.instance;
});

/// Background sync optimization service provider
final backgroundSyncOptimizationServiceProvider = Provider<BackgroundSyncOptimizationService>((ref) {
  return BackgroundSyncOptimizationService.instance;
});

/// Performance metrics state
class PerformanceMetrics {
  final int batteryLevel;
  final String batteryState;
  final int memoryUsageMB;
  final double cpuUsage;
  final String deviceModel;
  final bool isLowPowerMode;
  final bool isLocationOptimized;
  final bool isSyncOptimized;

  const PerformanceMetrics({
    required this.batteryLevel,
    required this.batteryState,
    required this.memoryUsageMB,
    required this.cpuUsage,
    required this.deviceModel,
    required this.isLowPowerMode,
    required this.isLocationOptimized,
    required this.isSyncOptimized,
  });

  PerformanceMetrics copyWith({
    int? batteryLevel,
    String? batteryState,
    int? memoryUsageMB,
    double? cpuUsage,
    String? deviceModel,
    bool? isLowPowerMode,
    bool? isLocationOptimized,
    bool? isSyncOptimized,
  }) {
    return PerformanceMetrics(
      batteryLevel: batteryLevel ?? this.batteryLevel,
      batteryState: batteryState ?? this.batteryState,
      memoryUsageMB: memoryUsageMB ?? this.memoryUsageMB,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      deviceModel: deviceModel ?? this.deviceModel,
      isLowPowerMode: isLowPowerMode ?? this.isLowPowerMode,
      isLocationOptimized: isLocationOptimized ?? this.isLocationOptimized,
      isSyncOptimized: isSyncOptimized ?? this.isSyncOptimized,
    );
  }
}

/// Performance metrics notifier
class PerformanceMetricsNotifier extends StateNotifier<PerformanceMetrics> {
  final PerformanceMonitoringService _performanceService;
  final LocationOptimizationService _locationService;
  final BackgroundSyncOptimizationService _syncService;

  PerformanceMetricsNotifier(
    this._performanceService,
    this._locationService,
    this._syncService,
  ) : super(const PerformanceMetrics(
          batteryLevel: 100,
          batteryState: 'unknown',
          memoryUsageMB: 0,
          cpuUsage: 0.0,
          deviceModel: 'Unknown',
          isLowPowerMode: false,
          isLocationOptimized: false,
          isSyncOptimized: false,
        ));

  /// Update performance metrics
  void updateMetrics() {
    state = PerformanceMetrics(
      batteryLevel: _performanceService.batteryLevel,
      batteryState: _performanceService.batteryState,
      memoryUsageMB: _performanceService.memoryUsageMB,
      cpuUsage: _performanceService.cpuUsage,
      deviceModel: _performanceService.deviceModel,
      isLowPowerMode: _performanceService.isLowPowerMode,
      isLocationOptimized: _locationService.isLocationTrackingEnabled,
      isSyncOptimized: _syncService.isSyncEnabled,
    );
  }

  /// Toggle low power mode
  void toggleLowPowerMode(bool enabled) {
    if (enabled) {
      _enableLowPowerMode();
    } else {
      _disableLowPowerMode();
    }
    updateMetrics();
  }

  /// Enable low power mode
  void _enableLowPowerMode() {
    // Optimize location tracking
    _locationService.updateLocationSettings(
      intervalSeconds: 300, // 5 minutes
      accuracy: LocationAccuracy.low,
      distanceFilter: 50.0,
    );

    // Optimize sync
    _syncService.updateSyncSettings(
      intervalMinutes: 60, // 1 hour
      wifiOnlyMode: true,
    );

    // Update performance service settings
    _performanceService.updateBatteryOptimizationSettings(
      locationOptimization: true,
      backgroundSync: false,
      syncInterval: 60,
    );
  }

  /// Disable low power mode
  void _disableLowPowerMode() {
    // Restore normal location tracking
    _locationService.updateLocationSettings(
      intervalSeconds: 30, // 30 seconds
      accuracy: LocationAccuracy.high,
      distanceFilter: 10.0,
    );

    // Restore normal sync
    _syncService.updateSyncSettings(
      intervalMinutes: 15, // 15 minutes
      wifiOnlyMode: false,
    );

    // Update performance service settings
    _performanceService.updateBatteryOptimizationSettings(
      locationOptimization: false,
      backgroundSync: true,
      syncInterval: 15,
    );
  }

  /// Force location update
  Future<void> forceLocationUpdate() async {
    await _locationService.forceLocationUpdate();
  }

  /// Force sync
  Future<void> forceSync() async {
    await _syncService.forceSyncNow();
  }

  /// Enable location tracking
  void enableLocationTracking() {
    _locationService.enableLocationTracking();
    updateMetrics();
  }

  /// Disable location tracking
  void disableLocationTracking() {
    _locationService.disableLocationTracking();
    updateMetrics();
  }

  /// Enable background sync
  void enableBackgroundSync() {
    _syncService.enableBackgroundSync();
    updateMetrics();
  }

  /// Disable background sync
  void disableBackgroundSync() {
    _syncService.disableBackgroundSync();
    updateMetrics();
  }
}

/// Performance metrics provider
final performanceMetricsProvider = StateNotifierProvider<PerformanceMetricsNotifier, PerformanceMetrics>((ref) {
  return PerformanceMetricsNotifier(
    ref.read(performanceServiceProvider),
    ref.read(locationOptimizationServiceProvider),
    ref.read(backgroundSyncOptimizationServiceProvider),
  );
});

/// Battery status provider
final batteryStatusProvider = Provider<String>((ref) {
  final performanceService = ref.read(performanceServiceProvider);
  return performanceService.batteryStatusText;
});

/// Memory status provider
final memoryStatusProvider = Provider<String>((ref) {
  final performanceService = ref.read(performanceServiceProvider);
  return performanceService.memoryStatusText;
});

/// Location status provider
final locationStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final locationService = ref.read(locationOptimizationServiceProvider);
  return locationService.getLocationStatus();
});

/// Sync statistics provider
final syncStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final syncService = ref.read(backgroundSyncOptimizationServiceProvider);
  return syncService.getSyncStatistics();
});

/// Performance report provider
final performanceReportProvider = Provider<Map<String, dynamic>>((ref) {
  final performanceService = ref.read(performanceServiceProvider);
  return performanceService.getPerformanceReport();
});

/// Battery optimization settings provider
final batteryOptimizationSettingsProvider = Provider<Map<String, dynamic>>((ref) {
  final performanceService = ref.read(performanceServiceProvider);
  return performanceService.getBatteryOptimizationSettings();
});

/// Initialize all performance services provider
final initializePerformanceServicesProvider = FutureProvider<void>((ref) async {
  final performanceService = ref.read(performanceServiceProvider);
  final locationService = ref.read(locationOptimizationServiceProvider);
  final syncService = ref.read(backgroundSyncOptimizationServiceProvider);

  await Future.wait([
    performanceService.initialize(),
    locationService.initialize(),
    syncService.initialize(),
  ]);
});