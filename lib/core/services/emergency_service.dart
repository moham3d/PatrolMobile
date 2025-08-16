import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';
import '../models/emergency.dart';
import '../exceptions/api_exception.dart';
import 'api_service.dart';

/// Emergency service for handling SOS alerts and panic buttons
class EmergencyService {
  static EmergencyService? _instance;
  static EmergencyService get instance => _instance ??= EmergencyService._internal();
  
  EmergencyService._internal();

  /// Trigger SOS emergency alert
  Future<EmergencyAlertResponse> triggerSOS({
    String? description,
    bool includeLocation = true,
  }) async {
    try {
      EmergencyLocation? location;
      
      if (includeLocation) {
        location = await _getCurrentLocation();
      }

      final request = EmergencyAlertRequest.sos(
        latitude: location?.latitude,
        longitude: location?.longitude,
        locationName: location?.locationName,
        description: description ?? 'SOS emergency alert triggered',
      );

      final response = await ApiService.instance.post<Map<String, dynamic>>(
        AppConstants.sosEndpoint,
        data: request.toJson(),
      );

      if (response.data == null) {
        throw const EmergencyException(
          message: 'Failed to send emergency alert',
          code: 'SOS_FAILED',
        );
      }

      return EmergencyAlertResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw EmergencyException(
        message: ApiException.fromDioError(e).message,
        statusCode: e.response?.statusCode,
        code: 'SOS_API_ERROR',
      );
    } catch (e) {
      throw EmergencyException(
        message: 'Emergency alert failed: $e',
        code: 'SOS_ERROR',
      );
    }
  }

  /// Trigger panic alert
  Future<EmergencyAlertResponse> triggerPanic({
    String? description,
    bool includeLocation = true,
  }) async {
    try {
      EmergencyLocation? location;
      
      if (includeLocation) {
        location = await _getCurrentLocation();
      }

      final request = EmergencyAlertRequest.panic(
        latitude: location?.latitude,
        longitude: location?.longitude,
        locationName: location?.locationName,
        description: description ?? 'Panic alert triggered',
      );

      final response = await ApiService.instance.post<Map<String, dynamic>>(
        AppConstants.panicEndpoint,
        data: request.toJson(),
      );

      if (response.data == null) {
        throw const EmergencyException(
          message: 'Failed to send panic alert',
          code: 'PANIC_FAILED',
        );
      }

      return EmergencyAlertResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw EmergencyException(
        message: ApiException.fromDioError(e).message,
        statusCode: e.response?.statusCode,
        code: 'PANIC_API_ERROR',
      );
    } catch (e) {
      throw EmergencyException(
        message: 'Panic alert failed: $e',
        code: 'PANIC_ERROR',
      );
    }
  }

  /// Get list of emergency alerts
  Future<List<EmergencyAlert>> getEmergencyAlerts({
    String? status,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (limit != null) queryParams['limit'] = limit;

      final response = await ApiService.instance.get<List<dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/alerts',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data == null) {
        return [];
      }

      return response.data!
          .map((json) => EmergencyAlert.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw EmergencyException(
        message: ApiException.fromDioError(e).message,
        statusCode: e.response?.statusCode,
        code: 'GET_ALERTS_ERROR',
      );
    }
  }

  /// Acknowledge emergency alert
  Future<void> acknowledgeAlert(int alertId) async {
    try {
      await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/alerts/$alertId/acknowledge',
      );
    } on DioException catch (e) {
      throw EmergencyException(
        message: ApiException.fromDioError(e).message,
        statusCode: e.response?.statusCode,
        code: 'ACKNOWLEDGE_ERROR',
      );
    }
  }

  /// Resolve emergency alert
  Future<void> resolveAlert(int alertId, {String? resolution}) async {
    try {
      final data = <String, dynamic>{};
      if (resolution != null) data['resolution'] = resolution;

      await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/alerts/$alertId/resolve',
        data: data.isNotEmpty ? data : null,
      );
    } on DioException catch (e) {
      throw EmergencyException(
        message: ApiException.fromDioError(e).message,
        statusCode: e.response?.statusCode,
        code: 'RESOLVE_ERROR',
      );
    }
  }

  /// Cancel active emergency alert
  Future<void> cancelAlert(int alertId, {String? reason}) async {
    try {
      final data = <String, dynamic>{
        'status': 'cancelled',
      };
      if (reason != null) data['cancellation_reason'] = reason;

      await ApiService.instance.put<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/alerts/$alertId',
        data: data,
      );
    } on DioException catch (e) {
      throw EmergencyException(
        message: ApiException.fromDioError(e).message,
        statusCode: e.response?.statusCode,
        code: 'CANCEL_ERROR',
      );
    }
  }

  /// Update emergency location during active alert
  Future<void> updateEmergencyLocation(int alertId, EmergencyLocation location) async {
    try {
      await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/alerts/$alertId/location',
        data: location.toJson(),
      );
    } on DioException catch (e) {
      throw EmergencyException(
        message: ApiException.fromDioError(e).message,
        statusCode: e.response?.statusCode,
        code: 'LOCATION_UPDATE_ERROR',
      );
    }
  }

  /// Get current GPS location
  Future<EmergencyLocation?> _getCurrentLocation() async {
    try {
      // Check and request location permissions
      await _requestLocationPermission();

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const EmergencyException(
          message: 'Location services are disabled. Please enable location services.',
          code: 'LOCATION_DISABLED',
        );
      }

      // Get current position with high accuracy for emergency
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Try to get location name (reverse geocoding would be done here in production)
      String? locationName;
      try {
        // In a real app, you would use geocoding service here
        // final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        // locationName = placemarks.first.name ?? placemarks.first.street;
        locationName = 'Current Location';
      } catch (e) {
        // Ignore geocoding errors in emergency situations
        locationName = null;
      }

      return EmergencyLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: DateTime.now().toIso8601String(),
        locationName: locationName,
      );
    } catch (e) {
      if (e is EmergencyException) rethrow;
      
      throw EmergencyException(
        message: 'Failed to get current location: $e',
        code: 'LOCATION_ERROR',
      );
    }
  }

  /// Request location permission
  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const EmergencyException(
        message: 'Location permission denied. Location is required for emergency alerts.',
        code: 'PERMISSION_DENIED',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const EmergencyException(
        message: 'Location permission permanently denied. Please enable location access in settings.',
        code: 'PERMISSION_DENIED_FOREVER',
      );
    }
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      return false;
    }
  }

  /// Get distance between two points (useful for location tracking)
  double getDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}