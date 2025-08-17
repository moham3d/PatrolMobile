import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'performance_monitoring_service.dart';

/// Service for optimizing location tracking based on battery and performance
class LocationOptimizationService {
  static LocationOptimizationService? _instance;
  static LocationOptimizationService get instance => _instance ??= LocationOptimizationService._internal();
  
  LocationOptimizationService._internal();

  final PerformanceMonitoringService _performanceService = PerformanceMonitoringService.instance;
  
  Timer? _locationTimer;
  Position? _lastKnownPosition;
  DateTime? _lastLocationUpdate;
  
  // Location tracking settings
  bool _isLocationTrackingEnabled = true;
  int _updateIntervalSeconds = 30; // Default 30 seconds
  LocationAccuracy _currentAccuracy = LocationAccuracy.high;
  double _distanceFilterMeters = 10.0; // Only update if moved 10+ meters
  
  // Battery-optimized settings
  static const Map<int, Map<String, dynamic>> _batteryOptimizedSettings = {
    100: { // 80-100% battery
      'interval': 30,
      'accuracy': LocationAccuracy.high,
      'distance_filter': 10.0,
    },
    80: { // 60-79% battery
      'interval': 45,
      'accuracy': LocationAccuracy.high,
      'distance_filter': 15.0,
    },
    60: { // 40-59% battery
      'interval': 60,
      'accuracy': LocationAccuracy.medium,
      'distance_filter': 20.0,
    },
    40: { // 20-39% battery
      'interval': 120,
      'accuracy': LocationAccuracy.medium,
      'distance_filter': 30.0,
    },
    20: { // 10-19% battery
      'interval': 300,
      'accuracy': LocationAccuracy.low,
      'distance_filter': 50.0,
    },
    10: { // <10% battery - emergency only
      'interval': 600,
      'accuracy': LocationAccuracy.low,
      'distance_filter': 100.0,
    },
  };

  // Getters
  Position? get lastKnownPosition => _lastKnownPosition;
  DateTime? get lastLocationUpdate => _lastLocationUpdate;
  bool get isLocationTrackingEnabled => _isLocationTrackingEnabled;
  int get updateIntervalSeconds => _updateIntervalSeconds;
  LocationAccuracy get currentAccuracy => _currentAccuracy;
  double get distanceFilterMeters => _distanceFilterMeters;

  /// Initialize location optimization service
  Future<void> initialize() async {
    await _requestLocationPermissions();
    _optimizeLocationSettings();
    _startLocationTracking();
  }

  /// Request location permissions
  Future<bool> _requestLocationPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return false;
      }

      return true;
    } catch (e) {
      print('Error requesting location permissions: $e');
      return false;
    }
  }

  /// Optimize location settings based on battery level
  void _optimizeLocationSettings() {
    final batteryLevel = _performanceService.batteryLevel;
    final isLowPowerMode = _performanceService.isLowPowerMode;
    
    // Find the appropriate settings based on battery level
    Map<String, dynamic>? settings;
    for (final threshold in _batteryOptimizedSettings.keys.toList()..sort((a, b) => b.compareTo(a))) {
      if (batteryLevel >= threshold) {
        settings = _batteryOptimizedSettings[threshold];
        break;
      }
    }
    
    // Fallback to lowest battery settings
    settings ??= _batteryOptimizedSettings[10];
    
    // Apply additional optimizations for low power mode
    if (isLowPowerMode) {
      _updateIntervalSeconds = (settings!['interval'] as int) * 2;
      _currentAccuracy = LocationAccuracy.low;
      _distanceFilterMeters = (settings['distance_filter'] as double) * 1.5;
    } else {
      _updateIntervalSeconds = settings!['interval'] as int;
      _currentAccuracy = settings['accuracy'] as LocationAccuracy;
      _distanceFilterMeters = settings['distance_filter'] as double;
    }
    
    print('Location settings optimized: interval=${_updateIntervalSeconds}s, '
          'accuracy=$_currentAccuracy, filter=${_distanceFilterMeters}m');
  }

  /// Start location tracking with optimized settings
  void _startLocationTracking() {
    if (!_isLocationTrackingEnabled) return;
    
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      Duration(seconds: _updateIntervalSeconds),
      (_) => _updateLocation(),
    );
  }

  /// Update current location
  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _currentAccuracy,
        timeLimit: Duration(seconds: _updateIntervalSeconds ~/ 2),
      );
      
      // Check if we've moved enough to warrant an update
      if (_shouldUpdateLocation(position)) {
        _lastKnownPosition = position;
        _lastLocationUpdate = DateTime.now();
        
        // Re-optimize settings periodically
        _optimizeLocationSettings();
        
        // Restart timer if interval changed
        if (_locationTimer?.tick != null) {
          _startLocationTracking();
        }
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  /// Check if location should be updated based on distance filter
  bool _shouldUpdateLocation(Position newPosition) {
    if (_lastKnownPosition == null) return true;
    
    final distance = Geolocator.distanceBetween(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    
    return distance >= _distanceFilterMeters;
  }

  /// Get current location immediately (ignores optimization)
  Future<Position?> getCurrentLocationImmediate() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      _lastKnownPosition = position;
      _lastLocationUpdate = DateTime.now();
      
      return position;
    } catch (e) {
      print('Error getting immediate location: $e');
      return _lastKnownPosition;
    }
  }

  /// Enable location tracking
  void enableLocationTracking() {
    if (_isLocationTrackingEnabled) return;
    
    _isLocationTrackingEnabled = true;
    _startLocationTracking();
    print('Location tracking enabled');
  }

  /// Disable location tracking
  void disableLocationTracking() {
    _isLocationTrackingEnabled = false;
    _locationTimer?.cancel();
    _locationTimer = null;
    print('Location tracking disabled');
  }

  /// Force location update (for emergencies)
  Future<Position?> forceLocationUpdate() async {
    print('Force location update requested');
    return await getCurrentLocationImmediate();
  }

  /// Get location tracking status
  Map<String, dynamic> getLocationStatus() {
    return {
      'tracking_enabled': _isLocationTrackingEnabled,
      'last_update': _lastLocationUpdate?.toIso8601String(),
      'update_interval_seconds': _updateIntervalSeconds,
      'accuracy': _currentAccuracy.toString(),
      'distance_filter_meters': _distanceFilterMeters,
      'last_position': _lastKnownPosition != null ? {
        'latitude': _lastKnownPosition!.latitude,
        'longitude': _lastKnownPosition!.longitude,
        'accuracy': _lastKnownPosition!.accuracy,
        'timestamp': _lastKnownPosition!.timestamp?.toIso8601String(),
      } : null,
    };
  }

  /// Update location settings manually
  void updateLocationSettings({
    int? intervalSeconds,
    LocationAccuracy? accuracy,
    double? distanceFilter,
  }) {
    bool settingsChanged = false;
    
    if (intervalSeconds != null && intervalSeconds > 0) {
      _updateIntervalSeconds = intervalSeconds;
      settingsChanged = true;
    }
    
    if (accuracy != null) {
      _currentAccuracy = accuracy;
      settingsChanged = true;
    }
    
    if (distanceFilter != null && distanceFilter > 0) {
      _distanceFilterMeters = distanceFilter;
      settingsChanged = true;
    }
    
    if (settingsChanged && _isLocationTrackingEnabled) {
      _startLocationTracking();
    }
  }

  /// Check if location is stale (hasn't been updated recently)
  bool get isLocationStale {
    if (_lastLocationUpdate == null) return true;
    
    final staleThreshold = Duration(seconds: _updateIntervalSeconds * 3);
    return DateTime.now().difference(_lastLocationUpdate!) > staleThreshold;
  }

  /// Get time since last location update
  Duration? get timeSinceLastUpdate {
    if (_lastLocationUpdate == null) return null;
    return DateTime.now().difference(_lastLocationUpdate!);
  }

  /// Dispose resources
  void dispose() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }
}