import 'dart:math' show sin, cos, atan2, sqrt, pi;
import 'package:dio/dio.dart';
import '../models/checkpoint.dart';
import '../constants/app_constants.dart';
import '../exceptions/api_exception.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'connectivity_service.dart';
import 'auth_service.dart';

/// Enhanced checkpoint service with offline capabilities
class OfflineCheckpointService {
  static OfflineCheckpointService? _instance;
  static OfflineCheckpointService get instance => _instance ??= OfflineCheckpointService._internal();
  
  OfflineCheckpointService._internal();

  final ApiService _apiService = ApiService.instance;
  final DatabaseService _databaseService = DatabaseService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final AuthService _authService = AuthService.instance;

  /// Scan checkpoint with offline support
  Future<CheckpointScanResult> scanCheckpoint({
    required String code,
    required String scanMethod,
    int? patrolId,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final deviceTimestamp = DateTime.now().toIso8601String();

    try {
      // First, verify the checkpoint code (online or offline)
      final verification = await verifyCheckpointCode(
        code: code,
        scanMethod: scanMethod,
        latitude: latitude,
        longitude: longitude,
      );

      if (!verification.isValid) {
        return CheckpointScanResult(
          success: false,
          message: verification.message,
          errorCode: verification.errorCode,
          isOffline: !_connectivityService.isOnline,
        );
      }

      final checkpoint = verification.checkpoint!;

      // Try to submit immediately if online
      if (_connectivityService.isOnline) {
        try {
          final visitRequest = CheckpointVisitRequest(
            checkpointId: checkpoint.id,
            code: code,
            scanMethod: scanMethod,
            patrolId: patrolId,
            latitude: latitude,
            longitude: longitude,
            locationAccuracy: accuracy,
            notes: notes,
            deviceTimestamp: deviceTimestamp,
          );

          final response = await _submitCheckpointVisit(visitRequest);
          
          return CheckpointScanResult(
            success: true,
            message: 'Checkpoint scanned successfully',
            checkpoint: checkpoint,
            visitResponse: response,
            isOffline: false,
          );
        } catch (e) {
          print('Online submission failed, falling back to offline: $e');
          // Fall through to offline storage
        }
      }

      // Store offline for later sync
      final offlineId = await _databaseService.storeOfflineCheckpointVisit(
        checkpointId: checkpoint.id,
        checkpointCode: code,
        patrolId: patrolId,
        userId: user.id,
        latitude: latitude,
        longitude: longitude,
        locationAccuracy: accuracy,
        scanMethod: scanMethod,
        notes: notes,
        deviceTimestamp: deviceTimestamp,
      );

      return CheckpointScanResult(
        success: true,
        message: 'Checkpoint scanned (stored offline)',
        checkpoint: checkpoint,
        isOffline: true,
        offlineId: offlineId,
      );

    } catch (e) {
      return CheckpointScanResult(
        success: false,
        message: 'Scan failed: ${e.toString()}',
        isOffline: !_connectivityService.isOnline,
      );
    }
  }

  /// Verify checkpoint code (works offline with cached data)
  Future<CheckpointVerification> verifyCheckpointCode({
    required String code,
    required String scanMethod,
    double? latitude,
    double? longitude,
  }) async {
    // Try online verification first if connected
    if (_connectivityService.isOnline) {
      try {
        final response = await _apiService.post<Map<String, dynamic>>(
          '${AppConstants.checkpointsEndpoint}/verify',
          data: {
            'code': code,
            'scan_method': scanMethod,
            'latitude': latitude,
            'longitude': longitude,
          },
        );

        final data = response.data!;
        return CheckpointVerification(
          isValid: data['is_valid'] ?? false,
          message: data['message'] ?? '',
          errorCode: data['error_code'],
          checkpoint: data['checkpoint'] != null 
              ? Checkpoint.fromJson(data['checkpoint'])
              : null,
        );
      } catch (e) {
        print('Online verification failed, trying offline: $e');
        // Fall through to offline verification
      }
    }

    // Offline verification using cached data
    return await _verifyCheckpointOffline(code, latitude, longitude);
  }

  /// Verify checkpoint using offline cached data
  Future<CheckpointVerification> _verifyCheckpointOffline(
    String code,
    double? latitude,
    double? longitude,
  ) async {
    try {
      final checkpoint = await _databaseService.getCachedCheckpointByCode(code);
      
      if (checkpoint == null) {
        return CheckpointVerification(
          isValid: false,
          message: 'Checkpoint not found in offline cache',
          errorCode: 'CHECKPOINT_NOT_CACHED',
        );
      }

      if (!checkpoint.isActive) {
        return CheckpointVerification(
          isValid: false,
          message: 'Checkpoint is not active',
          errorCode: 'CHECKPOINT_INACTIVE',
        );
      }

      // Verify location if provided and checkpoint has coordinates
      if (latitude != null && longitude != null && 
          checkpoint.latitude != null && checkpoint.longitude != null) {
        final distance = _calculateDistance(
          latitude, longitude,
          checkpoint.latitude!, checkpoint.longitude!,
        );

        // Allow up to 50 meters variance for GPS accuracy
        if (distance > 50.0) {
          return CheckpointVerification(
            isValid: false,
            message: 'You are too far from the checkpoint location',
            errorCode: 'LOCATION_TOO_FAR',
            checkpoint: checkpoint,
          );
        }
      }

      return CheckpointVerification(
        isValid: true,
        message: 'Checkpoint verified (offline)',
        checkpoint: checkpoint,
      );
    } catch (e) {
      return CheckpointVerification(
        isValid: false,
        message: 'Offline verification failed: ${e.toString()}',
        errorCode: 'OFFLINE_VERIFICATION_ERROR',
      );
    }
  }

  /// Submit checkpoint visit to API
  Future<CheckpointVisitResponse> _submitCheckpointVisit(
    CheckpointVisitRequest request,
  ) async {
    try {
      // Try patrol-specific endpoint first if patrol ID is provided
      if (request.patrolId != null) {
        try {
          final response = await _apiService.post<Map<String, dynamic>>(
            '${AppConstants.mobileApiBase}/patrols/${request.patrolId}/checkpoints/visit',
            data: request.toJson(),
          );
          return CheckpointVisitResponse.fromJson(response.data!);
        } catch (e) {
          print('Patrol-specific visit failed, trying generic: $e');
        }
      }

      // Fallback to generic checkpoint visit endpoint
      final response = await _apiService.post<Map<String, dynamic>>(
        '${AppConstants.checkpointsEndpoint}/visit',
        data: request.toJson(),
      );
      
      return CheckpointVisitResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get checkpoints with offline fallback
  Future<List<Checkpoint>> getCheckpoints({
    int? siteId,
    bool? isActive,
    bool forceOffline = false,
  }) async {
    if (!forceOffline && _connectivityService.isOnline) {
      try {
        // Online fetch
        final queryParams = <String, dynamic>{};
        if (siteId != null) queryParams['site_id'] = siteId;
        if (isActive != null) queryParams['is_active'] = isActive;

        final response = await _apiService.get<Map<String, dynamic>>(
          AppConstants.checkpointsEndpoint,
          queryParameters: queryParams,
        );

        final List<dynamic> data = response.data?['checkpoints'] ?? 
                                  response.data?['data'] ?? [];
        
        final checkpoints = data.map((json) => Checkpoint.fromJson(json)).toList();
        
        // Cache the fetched data for offline use
        for (final checkpoint in checkpoints) {
          await _databaseService.cacheCheckpoint(checkpoint);
        }
        
        return checkpoints;
      } catch (e) {
        print('Online fetch failed, falling back to offline: $e');
      }
    }

    // Offline fallback - return cached checkpoints
    // This would require implementing a method in database service to get all cached checkpoints
    // For now, return empty list as placeholder
    return [];
  }

  /// Get checkpoint by ID with offline fallback
  Future<Checkpoint?> getCheckpoint(int checkpointId, {bool forceOffline = false}) async {
    if (!forceOffline && _connectivityService.isOnline) {
      try {
        final response = await _apiService.get<Map<String, dynamic>>(
          '${AppConstants.checkpointsEndpoint}/$checkpointId',
        );

        final checkpoint = Checkpoint.fromJson(response.data!);
        
        // Cache for offline use
        await _databaseService.cacheCheckpoint(checkpoint);
        
        return checkpoint;
      } catch (e) {
        print('Online fetch failed, trying offline: $e');
      }
    }

    // Try to get from cache
    return await _databaseService.getCachedPatrol(checkpointId) as Checkpoint?;
  }

  /// Calculate distance between two coordinates in meters
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Convert degrees to radians
  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Get offline scan statistics
  Future<Map<String, dynamic>> getOfflineStatistics() async {
    return await _databaseService.getSyncStatistics();
  }
}

/// Result of checkpoint scanning operation
class CheckpointScanResult {
  final bool success;
  final String message;
  final String? errorCode;
  final Checkpoint? checkpoint;
  final CheckpointVisitResponse? visitResponse;
  final bool isOffline;
  final int? offlineId;

  const CheckpointScanResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.checkpoint,
    this.visitResponse,
    required this.isOffline,
    this.offlineId,
  });

  @override
  String toString() {
    return 'CheckpointScanResult(success: $success, offline: $isOffline, message: $message)';
  }
}

/// Checkpoint verification result
class CheckpointVerification {
  final bool isValid;
  final String message;
  final String? errorCode;
  final Checkpoint? checkpoint;

  const CheckpointVerification({
    required this.isValid,
    required this.message,
    this.errorCode,
    this.checkpoint,
  });
}

