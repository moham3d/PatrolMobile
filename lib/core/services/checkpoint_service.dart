import 'package:dio/dio.dart';
import '../models/checkpoint.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

/// Service for checkpoint-related operations
class CheckpointService {
  static final CheckpointService instance = CheckpointService._internal();
  CheckpointService._internal();

  final ApiService _apiService = ApiService.instance;

  /// Get all checkpoints for the authenticated user
  Future<List<Checkpoint>> getCheckpoints({
    int? siteId,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (siteId != null) queryParams['site_id'] = siteId;
      if (isActive != null) queryParams['is_active'] = isActive;

      final response = await _apiService.get(
        AppConstants.checkpointsEndpoint,
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => Checkpoint.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to fetch checkpoints: $e');
    }
  }

  /// Get a specific checkpoint by ID
  Future<Checkpoint> getCheckpoint(int checkpointId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.checkpointsEndpoint}/$checkpointId',
      );

      return Checkpoint.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to fetch checkpoint: $e');
    }
  }

  /// Get checkpoint by QR code or NFC tag
  Future<Checkpoint?> getCheckpointByCode(String code) async {
    try {
      final response = await _apiService.get(
        AppConstants.checkpointsEndpoint,
        queryParameters: {'code': code},
      );

      final List<dynamic> data = response.data['data'] ?? response.data;
      if (data.isEmpty) return null;
      
      return Checkpoint.fromJson(data.first);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to find checkpoint: $e');
    }
  }

  /// Record a checkpoint visit (scan)
  Future<CheckpointVisitResponse> recordVisit(CheckpointVisitRequest request) async {
    try {
      final response = await _apiService.post(
        AppConstants.scanEndpoint,
        data: request.toJson(),
      );

      return CheckpointVisitResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to record checkpoint visit: $e');
    }
  }

  /// Get checkpoint visit history
  Future<List<CheckpointVisit>> getVisitHistory({
    int? checkpointId,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (checkpointId != null) queryParams['checkpoint_id'] = checkpointId;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _apiService.get(
        '${AppConstants.checkpointsEndpoint}/visits',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => CheckpointVisit.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to fetch visit history: $e');
    }
  }

  /// Get checkpoint statistics
  Future<CheckpointStats> getCheckpointStats() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.checkpointsEndpoint}/stats',
      );

      return CheckpointStats.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to fetch checkpoint stats: $e');
    }
  }

  /// Verify QR code or NFC tag against backend
  Future<CheckpointVerificationResult> verifyCode({
    required String code,
    required String scanMethod,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.checkpointsEndpoint}/verify',
        data: {
          'code': code,
          'scan_method': scanMethod,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      return CheckpointVerificationResult.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to verify code: $e');
    }
  }

  /// Handle API errors
  Exception _handleError(DioException e) {
    final message = e.response?.data?['message'] ?? 
                   e.response?.data?['error'] ?? 
                   e.message ?? 
                   'Unknown error occurred';
    
    switch (e.response?.statusCode) {
      case 400:
        return Exception('Invalid request: $message');
      case 401:
        return Exception('Authentication required');
      case 403:
        return Exception('Access denied: $message');
      case 404:
        return Exception('Checkpoint not found');
      case 422:
        return Exception('Validation error: $message');
      case 500:
        return Exception('Server error. Please try again later.');
      default:
        return Exception('Network error: $message');
    }
  }
}

/// Checkpoint verification result
class CheckpointVerificationResult {
  final bool isValid;
  final String message;
  final Checkpoint? checkpoint;
  final String? errorCode;

  const CheckpointVerificationResult({
    required this.isValid,
    required this.message,
    this.checkpoint,
    this.errorCode,
  });

  factory CheckpointVerificationResult.fromJson(Map<String, dynamic> json) {
    return CheckpointVerificationResult(
      isValid: json['is_valid'] ?? json['valid'] ?? false,
      message: json['message'] ?? '',
      checkpoint: json['checkpoint'] != null 
        ? Checkpoint.fromJson(json['checkpoint'])
        : null,
      errorCode: json['error_code'],
    );
  }

  @override
  String toString() {
    return 'CheckpointVerificationResult(isValid: $isValid, message: $message)';
  }
}