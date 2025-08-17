import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'websocket_service.dart';
import 'database_service.dart';

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String? address;
  final double? speed;
  final double? heading;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.address,
    this.speed,
    this.heading,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'timestamp': timestamp.toIso8601String(),
    'address': address,
    'speed': speed,
    'heading': heading,
  };

  factory LocationData.fromPosition(Position position, {String? address}) {
    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp ?? DateTime.now(),
      address: address,
      speed: position.speed,
      heading: position.heading,
    );
  }
}

/// Location sharing service for real-time patrol tracking
class LocationSharingService {
  static LocationSharingService? _instance;
  static LocationSharingService get instance => _instance ??= LocationSharingService._internal();
  
  LocationSharingService._internal();

  final ApiService _apiService = ApiService.instance;
  final AuthService _authService = AuthService.instance;
  final WebSocketService _webSocketService = WebSocketService.instance;
  final DatabaseService _databaseService = DatabaseService.instance;
  
  final StreamController<LocationData> _locationController = 
      StreamController.broadcast();
  
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionSubscription;
  bool _isSharing = false;
  bool _isPatrolActive = false;
  LocationData? _lastLocation;
  
  /// Location settings for different modes
  static const LocationSettings _highAccuracySettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // Update every 5 meters
  );
  
  static const LocationSettings _patrolSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 1, // Update every 1 meter during patrol
  );
  
  static const LocationSettings _emergencySettings = LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 0, // Update continuously during emergency
  );
  
  /// Stream of location updates
  Stream<LocationData> get locationStream => _locationController.stream;
  
  /// Check if location sharing is active
  bool get isSharing => _isSharing;
  
  /// Check if patrol tracking is active
  bool get isPatrolActive => _isPatrolActive;
  
  /// Get last known location
  LocationData? get lastLocation => _lastLocation;
  
  /// Initialize location sharing service
  Future<void> initialize() async {
    // Check location permissions
    await _checkLocationPermissions();
  }
  
  /// Start location sharing for general monitoring
  Future<void> startLocationSharing() async {
    if (_isSharing) return;
    
    await _checkLocationPermissions();
    
    _isSharing = true;
    
    // Start periodic location updates every 30 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _getCurrentLocation(_highAccuracySettings);
    });
    
    // Get initial location
    await _getCurrentLocation(_highAccuracySettings);
    
    print('Location sharing started');
  }
  
  /// Start patrol tracking with high-frequency updates
  Future<void> startPatrolTracking() async {
    if (_isPatrolActive) return;
    
    await _checkLocationPermissions();
    
    _isPatrolActive = true;
    _isSharing = true;
    
    // Cancel any existing timer
    _locationTimer?.cancel();
    
    // Start continuous location stream for patrol
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _patrolSettings,
    ).listen((position) {
      final locationData = LocationData.fromPosition(position);
      _handleLocationUpdate(locationData);
    });
    
    print('Patrol tracking started');
  }
  
  /// Start emergency location tracking with maximum accuracy
  Future<void> startEmergencyTracking() async {
    await _checkLocationPermissions();
    
    // Cancel existing subscriptions
    _stopLocationUpdates();
    
    _isSharing = true;
    
    // Start high-frequency emergency tracking
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _emergencySettings,
    ).listen((position) {
      final locationData = LocationData.fromPosition(position);
      _handleLocationUpdate(locationData, isEmergency: true);
    });
    
    print('Emergency tracking started');
  }
  
  /// Stop patrol tracking
  void stopPatrolTracking() {
    if (!_isPatrolActive) return;
    
    _isPatrolActive = false;
    _stopLocationUpdates();
    
    // Resume normal location sharing if needed
    if (_isSharing) {
      startLocationSharing();
    }
    
    print('Patrol tracking stopped');
  }
  
  /// Stop all location sharing
  void stopLocationSharing() {
    _isSharing = false;
    _isPatrolActive = false;
    _stopLocationUpdates();
    
    print('Location sharing stopped');
  }
  
  /// Get current location once
  Future<LocationData?> getCurrentLocation() async {
    await _checkLocationPermissions();
    return await _getCurrentLocation(_highAccuracySettings);
  }
  
  /// Get current location with specific settings
  Future<LocationData?> _getCurrentLocation(LocationSettings settings) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: settings.accuracy,
        timeLimit: settings.timeLimit,
      );
      
      final locationData = LocationData.fromPosition(position);
      _handleLocationUpdate(locationData);
      
      return locationData;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }
  
  /// Handle location update
  void _handleLocationUpdate(LocationData locationData, {bool isEmergency = false}) {
    _lastLocation = locationData;
    _locationController.add(locationData);
    
    // Send to WebSocket for real-time sharing
    if (_webSocketService.isConnected) {
      _webSocketService.sendLocationUpdate(
        locationData.latitude,
        locationData.longitude,
        address: locationData.address,
      );
    }
    
    // Send to API
    _sendLocationToAPI(locationData, isEmergency: isEmergency);
    
    // Store offline
    _storeLocationOffline(locationData);
  }
  
  /// Send location to API
  Future<void> _sendLocationToAPI(LocationData locationData, {bool isEmergency = false}) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;
      
      final data = {
        ...locationData.toJson(),
        'user_id': user.id,
        'is_emergency': isEmergency,
        'is_patrol': _isPatrolActive,
      };
      
      await _apiService.post('/gps/locations', data: data);
    } catch (e) {
      print('Error sending location to API: $e');
    }
  }
  
  /// Store location offline for later sync
  Future<void> _storeLocationOffline(LocationData locationData) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;
      
      await _databaseService.storeOfflineLocation(
        userId: user.id,
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        accuracy: locationData.accuracy,
        timestamp: locationData.timestamp,
        address: locationData.address,
        speed: locationData.speed,
        heading: locationData.heading,
        isPatrol: _isPatrolActive,
      );
    } catch (e) {
      print('Error storing location offline: $e');
    }
  }
  
  /// Check and request location permissions
  Future<void> _checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
    
    // Request background location permission for patrol tracking
    if (permission == LocationPermission.whileInUse) {
      // Show dialog to user about background location benefits
      print('Background location permission recommended for patrol tracking');
    }
  }
  
  /// Stop location updates
  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _positionSubscription?.cancel();
    _locationTimer = null;
    _positionSubscription = null;
  }
  
  /// Dispose service
  void dispose() {
    _stopLocationUpdates();
    _locationController.close();
  }
}

/// Extension to DatabaseService for location storage
extension LocationDatabaseExtension on DatabaseService {
  /// Store offline location data
  Future<void> storeOfflineLocation({
    required int userId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime timestamp,
    String? address,
    double? speed,
    double? heading,
    bool isPatrol = false,
  }) async {
    final db = await database;
    
    await db.insert('offline_locations', {
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
      'speed': speed,
      'heading': heading,
      'is_patrol': isPatrol ? 1 : 0,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
  /// Get unsynced location data
  Future<List<Map<String, dynamic>>> getUnsyncedLocations() async {
    final db = await database;
    
    return await db.query(
      'offline_locations',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
  }
  
  /// Mark location as synced
  Future<void> markLocationSynced(int id) async {
    final db = await database;
    
    await db.update(
      'offline_locations',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}