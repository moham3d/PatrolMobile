import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

/// Connectivity monitoring service to track online/offline status
class ConnectivityService {
  static ConnectivityService? _instance;
  static ConnectivityService get instance =>
      _instance ??= ConnectivityService._internal();

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController =
      StreamController.broadcast();

  bool _isOnline = false;
  StreamSubscription<dynamic>? _connectivitySubscription;
  Timer? _apiHealthCheckTimer;

  /// Stream of connectivity status
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current connectivity status
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();

    // Listen to connectivity changes (newer connectivity_plus may emit List<ConnectivityResult>)
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (event) => _onConnectivityChanged(event),
    );

    // Start periodic API health checks
    _startApiHealthChecks();
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      await _onConnectivityChanged(result);
    } catch (e) {
      print('Error checking connectivity: $e');
      _updateConnectionStatus(false);
    }
  }

  /// Handle connectivity changes
  Future<void> _onConnectivityChanged(dynamic event) async {
    final connectivityResult = _normalizeConnectivity(event);
    print('Connectivity changed: $connectivityResult');

    switch (connectivityResult) {
      case ConnectivityResult.none:
        _updateConnectionStatus(false);
        break;
      case ConnectivityResult.mobile:
      case ConnectivityResult.wifi:
      case ConnectivityResult.ethernet:
        // Even if device says it's connected, verify with API
        await _verifyApiConnectivity();
        break;
      default:
        _updateConnectionStatus(false);
    }
  }

  /// Normalize connectivity events which may be a single ConnectivityResult or a List<ConnectivityResult>
  ConnectivityResult _normalizeConnectivity(dynamic event) {
    if (event is ConnectivityResult) return event;
    if (event is List) {
      for (final item in event) {
        if (item is ConnectivityResult && item != ConnectivityResult.none)
          return item;
      }
      if (event.isNotEmpty && event.first is ConnectivityResult)
        return event.first as ConnectivityResult;
    }
    return ConnectivityResult.none;
  }

  /// Verify actual API connectivity
  Future<void> _verifyApiConnectivity() async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 5);
      dio.options.receiveTimeout = const Duration(seconds: 5);

      // Try to reach the health endpoint
      final response = await dio.get(
        '${AppConstants.apiBaseUrl}/health',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final isConnected =
          response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 500;

      _updateConnectionStatus(isConnected);
    } catch (e) {
      print('API connectivity check failed: $e');
      _updateConnectionStatus(false);
    }
  }

  /// Update connection status and notify listeners
  void _updateConnectionStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectivityController.add(isOnline);

      print('Connection status changed: ${isOnline ? 'ONLINE' : 'OFFLINE'}');

      // Trigger sync when coming back online
      if (isOnline) {
        _onConnectionRestored();
      }
    }
  }

  /// Handle connection restoration
  void _onConnectionRestored() {
    print('Connection restored - triggering data sync');
    // The sync service will listen to this stream and trigger sync
  }

  /// Start periodic API health checks
  void _startApiHealthChecks() {
    _apiHealthCheckTimer?.cancel();
    _apiHealthCheckTimer = Timer.periodic(
      const Duration(minutes: 1), // Check every minute
      (timer) async {
        if (_isOnline) {
          await _verifyApiConnectivity();
        } else {
          // If we think we're offline, check if we're back online
          await _checkConnectivity();
        }
      },
    );
  }

  /// Manually trigger connectivity check
  Future<void> forceConnectivityCheck() async {
    await _checkConnectivity();
  }

  /// Check if specific endpoint is reachable
  Future<bool> isEndpointReachable(String endpoint) async {
    if (!_isOnline) return false;

    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 3);
      dio.options.receiveTimeout = const Duration(seconds: 3);

      final response = await dio.head(endpoint);
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 500;
    } catch (e) {
      return false;
    }
  }

  /// Get detailed connectivity info
  Future<Map<String, dynamic>> getConnectivityInfo() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final locationPermission = await _checkLocationPermission();

    return {
      'is_online': _isOnline,
      'connectivity_type': connectivityResult.toString(),
      'api_reachable': _isOnline,
      'location_permission': locationPermission,
      'last_check': DateTime.now().toIso8601String(),
    };
  }

  /// Check location permission status (important for GPS-based features)
  Future<bool> _checkLocationPermission() async {
    try {
      // This is a simplified check - in a real app you'd use permission_handler
      return true; // Assume granted for now
    } catch (e) {
      return false;
    }
  }

  /// Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _apiHealthCheckTimer?.cancel();
    _connectivityController.close();
  }
}

/// Connectivity status enum for better type safety
enum ConnectivityStatus { online, offline, checking }

/// Connectivity status with additional metadata
class ConnectivityInfo {
  final ConnectivityStatus status;
  final ConnectivityResult connectionType;
  final bool apiReachable;
  final DateTime lastChecked;
  final String? errorMessage;

  const ConnectivityInfo({
    required this.status,
    required this.connectionType,
    required this.apiReachable,
    required this.lastChecked,
    this.errorMessage,
  });

  bool get isOnline => status == ConnectivityStatus.online && apiReachable;
  bool get isOffline => status == ConnectivityStatus.offline || !apiReachable;

  @override
  String toString() {
    return 'ConnectivityInfo(status: $status, type: $connectionType, api: $apiReachable)';
  }
}
