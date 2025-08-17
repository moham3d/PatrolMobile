import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../models/emergency.dart';
import '../exceptions/api_exception.dart';
import 'api_service.dart';
import 'emergency_escalation_service.dart';

/// Emergency service for handling SOS alerts and panic buttons
class EmergencyService {
  static EmergencyService? _instance;
  static EmergencyService get instance => _instance ??= EmergencyService._internal();
  
  EmergencyService._internal();

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final permission = await Permission.location.status;
    return permission == PermissionStatus.granted;
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status == PermissionStatus.granted;
  }

  /// Check if location service is enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

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

      final alertResponse = EmergencyAlertResponse.fromJson(response.data!);
      
      // Start automatic escalation timer
      EmergencyEscalationService.instance.startEscalation(alertResponse.alert);
      
      return alertResponse;
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
      
      // Cancel escalation if alert is acknowledged
      EmergencyEscalationService.instance.cancelEscalation(alertId);
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
      
      // Cancel escalation if alert is resolved
      EmergencyEscalationService.instance.cancelEscalation(alertId);
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
      
      // Cancel escalation if alert is cancelled
      EmergencyEscalationService.instance.cancelEscalation(alertId);
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

  /// Get emergency contacts
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    try {
      final response = await ApiService.instance.get<List<dynamic>>(
        '${AppConstants.mobileApiBase}/emergency/contacts',
      );

      if (response.data == null) {
        // Return default emergency contacts if API fails
        return _getDefaultEmergencyContacts();
      }

      return response.data!
          .map((json) => EmergencyContact.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return default emergency contacts if API fails
      return _getDefaultEmergencyContacts();
    }
  }

  /// Get default emergency contacts (fallback)
  List<EmergencyContact> _getDefaultEmergencyContacts() {
    return [
      const EmergencyContact(
        id: 1,
        name: 'Emergency Services',
        phone: '911',
        type: 'emergency',
        description: 'Emergency services (911)',
        isActive: true,
      ),
      const EmergencyContact(
        id: 2,
        name: 'Site Security',
        phone: '+1-555-0101',
        type: 'security',
        description: 'Site security office',
        isActive: true,
      ),
      const EmergencyContact(
        id: 3,
        name: 'Site Manager',
        phone: '+1-555-0102',
        type: 'management',
        description: 'Site manager',
        isActive: true,
      ),
    ];
  }

  /// Call emergency contact
  Future<bool> callEmergencyContact(EmergencyContact contact) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: contact.phone);
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(
          phoneUri,
          mode: LaunchMode.externalApplication,
        );
        return true;
      } else {
        throw EmergencyException(
          message: 'Cannot make phone calls on this device',
          code: 'PHONE_NOT_SUPPORTED',
        );
      }
    } catch (e) {
      throw EmergencyException(
        message: 'Failed to call emergency contact: $e',
        code: 'CALL_FAILED',
      );
    }
  }

  /// Call emergency services (911)
  Future<bool> callEmergencyServices() async {
    const emergencyContact = EmergencyContact(
      id: 0,
      name: 'Emergency Services',
      phone: '911',
      type: 'emergency',
      description: 'Emergency services',
      isActive: true,
    );
    
    return await callEmergencyContact(emergencyContact);
  }

  /// Trigger immediate emergency call with optional alert
  Future<void> triggerEmergencyCall({
    bool createAlert = true,
    String? description,
  }) async {
    try {
      // First, call emergency services
      await callEmergencyServices();
      
      // Then create emergency alert if requested
      if (createAlert) {
        await triggerSOS(
          description: description ?? 'Emergency call initiated - Immediate assistance required',
        );
      }
    } catch (e) {
      throw EmergencyException(
        message: 'Emergency call failed: $e',
        code: 'EMERGENCY_CALL_FAILED',
      );
    }
  }
}