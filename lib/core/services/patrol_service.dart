import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../models/patrol_simple.dart';
import '../models/checkpoint.dart';
import '../models/patrol_history.dart';
import '../exceptions/api_exception.dart';
import 'api_service.dart';

/// Service for managing patrol operations via API
class PatrolService {
  static PatrolService? _instance;
  static PatrolService get instance => _instance ??= PatrolService._internal();

  PatrolService._internal();

  /// Get assigned patrols for current user
  Future<List<Patrol>> getAssignedPatrols({String? status, int? siteId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (siteId != null) queryParams['site_id'] = siteId;

      final response = await ApiService.instance.get<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/assigned',
        queryParameters: queryParams,
      );

      final List<dynamic> patrolsData =
          response.data?['patrols'] ?? response.data?['data'] ?? [];
      return patrolsData.map((patrol) => Patrol.fromJson(patrol)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get patrol details by ID
  Future<Patrol> getPatrol(int patrolId) async {
    try {
      final response = await ApiService.instance.get<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/$patrolId/optimized',
      );

      return Patrol.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get patrol route with checkpoints
  Future<PatrolRoute> getPatrolRoute(int patrolId) async {
    try {
      final response = await ApiService.instance.get<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/$patrolId/checkpoints',
      );

      final data = response.data!;
      return PatrolRoute(
        patrolId: patrolId,
        name: data['name'] ?? 'Patrol Route',
        description: data['description'],
        checkpoints:
            (data['checkpoints'] as List<dynamic>?)
                ?.map((c) => Checkpoint.fromJson(c))
                .toList() ??
            [],
        totalDistance: data['total_distance']?.toDouble(),
        estimatedDuration: data['estimated_duration'],
        optimizedSequence: (data['optimized_sequence'] as List<dynamic>?)
            ?.map((id) => id as int)
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get patrol progress
  Future<PatrolProgress> getPatrolProgress(int patrolId) async {
    try {
      final response = await ApiService.instance.get<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/$patrolId/progress',
      );

      final data = response.data!;
      return PatrolProgress(
        patrolId: patrolId,
        totalCheckpoints: data['total_checkpoints'] ?? 0,
        visitedCheckpoints: data['visited_checkpoints'] ?? 0,
        completionPercentage: (data['completion_percentage'] ?? 0.0).toDouble(),
        startTime: data['start_time'],
        currentCheckpoint: data['current_checkpoint'] != null
            ? Checkpoint.fromJson(data['current_checkpoint'])
            : null,
        nextCheckpoint: data['next_checkpoint'] != null
            ? Checkpoint.fromJson(data['next_checkpoint'])
            : null,
        recentVisits: (data['recent_visits'] as List<dynamic>?)
            ?.map((v) => CheckpointVisit.fromJson(v))
            .toList(),
        estimatedCompletionTime: data['estimated_completion_time'],
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Start patrol
  Future<PatrolActionResponse> startPatrol(
    int patrolId, {
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) async {
    try {
      final request = PatrolActionRequest.start(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        notes: notes,
      );

      final response = await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/$patrolId/start',
        data: request.toJson(),
      );

      return PatrolActionResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// End patrol
  Future<PatrolActionResponse> endPatrol(
    int patrolId, {
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) async {
    try {
      final request = PatrolActionRequest.end(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        notes: notes,
      );

      final response = await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/$patrolId/end',
        data: request.toJson(),
      );

      return PatrolActionResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Complete patrol
  Future<PatrolActionResponse> completePatrol(
    int patrolId, {
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) async {
    try {
      final request = PatrolActionRequest.complete(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        notes: notes,
      );

      final response = await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/$patrolId/complete',
        data: request.toJson(),
      );

      return PatrolActionResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Cancel patrol
  Future<PatrolActionResponse> cancelPatrol(
    int patrolId, {
    String? reason,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) async {
    try {
      final request = PatrolActionRequest.cancel(
        reason: reason,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        notes: notes,
      );

      final response = await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/$patrolId/cancel',
        data: request.toJson(),
      );

      return PatrolActionResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Perform patrol action (generic)
  Future<PatrolActionResponse> performPatrolAction(
    int patrolId,
    PatrolActionRequest request,
  ) async {
    try {
      final response = await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/$patrolId/action',
        data: request.toJson(),
      );

      return PatrolActionResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Visit checkpoint during patrol
  Future<CheckpointVisitResponse> visitCheckpointDuringPatrol(
    int patrolId,
    CheckpointVisitRequest visitRequest,
  ) async {
    try {
      final response = await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/$patrolId/checkpoints/visit',
        data: visitRequest.toJson(),
      );

      return CheckpointVisitResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Visit checkpoint during patrol (optimized endpoint)
  Future<CheckpointVisitResponse> visitCheckpointOptimized(
    int patrolId,
    CheckpointVisitRequest visitRequest,
  ) async {
    try {
      final response = await ApiService.instance.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/$patrolId/checkpoints/visit/optimized',
        data: visitRequest.toJson(),
      );

      return CheckpointVisitResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get patrol history
  Future<List<PatrolHistoryEntry>> getPatrolHistory({
    int? userId,
    int? siteId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) queryParams['user_id'] = userId;
      if (siteId != null) queryParams['site_id'] = siteId;
      if (status != null) queryParams['status'] = status;
      if (startDate != null)
        queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit;

      final response = await ApiService.instance.get<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/history',
        queryParameters: queryParams,
      );

      final List<dynamic> historyData =
          response.data?['history'] ?? response.data?['data'] ?? [];
      return historyData
          .map((entry) => PatrolHistoryEntry.fromJson(entry))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get active patrols for monitoring (supervisor/manager view)
  Future<List<Patrol>> getActivePatrols({int? siteId, int? assignedTo}) async {
    try {
      final queryParams = <String, dynamic>{'status': 'in_progress'};
      if (siteId != null) queryParams['site_id'] = siteId;
      if (assignedTo != null) queryParams['assigned_to'] = assignedTo;

      final response = await ApiService.instance.get<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols',
        queryParameters: queryParams,
      );

      final List<dynamic> patrolsData =
          response.data?['patrols'] ?? response.data?['data'] ?? [];
      return patrolsData.map((patrol) => Patrol.fromJson(patrol)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get patrol statistics
  Future<Map<String, dynamic>> getPatrolStatistics({
    int? siteId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (siteId != null) queryParams['site_id'] = siteId;
      if (startDate != null)
        queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await ApiService.instance.get<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/statistics',
        queryParameters: queryParams,
      );

      return response.data ?? {};
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Search patrols
  Future<List<Patrol>> searchPatrols({
    String? query,
    String? status,
    int? siteId,
    int? assignedTo,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (query != null && query.isNotEmpty) queryParams['q'] = query;
      if (status != null) queryParams['status'] = status;
      if (siteId != null) queryParams['site_id'] = siteId;
      if (assignedTo != null) queryParams['assigned_to'] = assignedTo;
      if (startDate != null)
        queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await ApiService.instance.get<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/patrols/search',
        queryParameters: queryParams,
      );

      final List<dynamic> patrolsData =
          response.data?['patrols'] ?? response.data?['data'] ?? [];
      return patrolsData.map((patrol) => Patrol.fromJson(patrol)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get patrol performance metrics
  Future<Map<String, dynamic>> getPatrolPerformance(int patrolId) async {
    try {
      final response = await ApiService.instance.get<Map<String, dynamic>>(
        '/checkpoints/patrols/$patrolId/performance',
      );

      return response.data ?? {};
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Optimize patrol route
  Future<PatrolRoute> optimizePatrolRoute(int patrolId) async {
    try {
      final response = await ApiService.instance.post<Map<String, dynamic>>(
        '/checkpoints/optimize-route',
        data: {'patrol_id': patrolId},
      );

      final data = response.data!;
      return PatrolRoute(
        patrolId: patrolId,
        name: data['name'] ?? 'Optimized Route',
        description: data['description'],
        checkpoints:
            (data['checkpoints'] as List<dynamic>?)
                ?.map((c) => Checkpoint.fromJson(c))
                .toList() ??
            [],
        totalDistance: data['total_distance']?.toDouble(),
        estimatedDuration: data['estimated_duration'],
        optimizedSequence: (data['optimized_sequence'] as List<dynamic>?)
            ?.map((id) => id as int)
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get live patrol status (for monitoring)
  Future<List<Map<String, dynamic>>> getLivePatrolStatus({int? siteId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (siteId != null) queryParams['site_id'] = siteId;

      final response = await ApiService.instance.get<Map<String, dynamic>>(
        '/live/patrols/active',
        queryParameters: queryParams,
      );

      final List<dynamic> statusData =
          response.data?['patrols'] ?? response.data?['data'] ?? [];
      return statusData
          .map((status) => status as Map<String, dynamic>)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
