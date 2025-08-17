import 'package:dio/dio.dart';
import '../models/incident.dart';
import '../constants/app_constants.dart';
import '../exceptions/api_exception.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Service for handling incident-related API operations
class IncidentService {
  static IncidentService? _instance;
  static IncidentService get instance => _instance ??= IncidentService._internal();
  
  IncidentService._internal();

  final ApiService _apiService = ApiService.instance;
  final AuthService _authService = AuthService.instance;

  /// Create a new incident report
  Future<IncidentResponse> createIncident({
    required String title,
    required String description,
    required String category,
    required String priority,
    int? siteId,
    int? locationId,
    double? latitude,
    double? longitude,
    double? locationAccuracy,
    String? notes,
    List<String>? evidenceFiles,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw const ApiException(
          message: 'Authentication required',
          code: 'AUTH_REQUIRED',
        );
      }

      final request = IncidentRequest(
        title: title,
        description: description,
        category: category,
        priority: priority,
        siteId: siteId,
        locationId: locationId,
        latitude: latitude,
        longitude: longitude,
        locationAccuracy: locationAccuracy,
        notes: notes,
        evidenceFiles: evidenceFiles,
      );

      final response = await _apiService.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/incidents',
        data: request.toJson(),
      );

      return IncidentResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(
        message: 'Failed to create incident: $e',
        code: 'INCIDENT_CREATE_ERROR',
      );
    }
  }

  /// Get list of incidents with optional filters
  Future<List<Incident>> getIncidents({
    String? status,
    String? priority,
    String? category,
    int? siteId,
    int? assignedTo,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw const ApiException(
          message: 'Authentication required',
          code: 'AUTH_REQUIRED',
        );
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null) queryParams['status'] = status;
      if (priority != null) queryParams['priority'] = priority;
      if (category != null) queryParams['category'] = category;
      if (siteId != null) queryParams['site_id'] = siteId;
      if (assignedTo != null) queryParams['assigned_to'] = assignedTo;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _apiService.get<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/incidents',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data?['incidents'] ?? 
                                response.data?['data'] ?? [];

      return data.map((json) => Incident.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch incidents: $e',
        code: 'INCIDENTS_FETCH_ERROR',
      );
    }
  }

  /// Get a specific incident by ID
  Future<Incident> getIncident(int incidentId) async {
    try {
      if (!_authService.isAuthenticated) {
        throw const ApiException(
          message: 'Authentication required',
          code: 'AUTH_REQUIRED',
        );
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/incidents/$incidentId',
      );

      return Incident.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch incident: $e',
        code: 'INCIDENT_FETCH_ERROR',
      );
    }
  }

  /// Update incident status or details
  Future<IncidentResponse> updateIncident({
    required int incidentId,
    String? status,
    String? notes,
    int? assignedTo,
    String? resolutionNotes,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw const ApiException(
          message: 'Authentication required',
          code: 'AUTH_REQUIRED',
        );
      }

      final update = IncidentUpdate(
        status: status,
        notes: notes,
        assignedTo: assignedTo,
        resolutionNotes: resolutionNotes,
      );

      final response = await _apiService.put<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/incidents/$incidentId',
        data: update.toJson(),
      );

      return IncidentResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(
        message: 'Failed to update incident: $e',
        code: 'INCIDENT_UPDATE_ERROR',
      );
    }
  }

  /// Assign incident to a user
  Future<IncidentResponse> assignIncident({
    required int incidentId,
    required int assignedTo,
    String? notes,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw const ApiException(
          message: 'Authentication required',
          code: 'AUTH_REQUIRED',
        );
      }

      final response = await _apiService.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/incidents/$incidentId/assign',
        data: {
          'assigned_to': assignedTo,
          if (notes != null) 'notes': notes,
        },
      );

      return IncidentResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(
        message: 'Failed to assign incident: $e',
        code: 'INCIDENT_ASSIGN_ERROR',
      );
    }
  }

  /// Resolve incident
  Future<IncidentResponse> resolveIncident({
    required int incidentId,
    required String resolutionNotes,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw const ApiException(
          message: 'Authentication required',
          code: 'AUTH_REQUIRED',
        );
      }

      final response = await _apiService.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/incidents/$incidentId/resolve',
        data: {
          'resolution_notes': resolutionNotes,
        },
      );

      return IncidentResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(
        message: 'Failed to resolve incident: $e',
        code: 'INCIDENT_RESOLVE_ERROR',
      );
    }
  }

  /// Get incident statistics
  Future<IncidentStats> getIncidentStats({
    int? siteId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw const ApiException(
          message: 'Authentication required',
          code: 'AUTH_REQUIRED',
        );
      }

      final queryParams = <String, dynamic>{};
      if (siteId != null) queryParams['site_id'] = siteId;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _apiService.get<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/incidents/statistics',
        queryParameters: queryParams,
      );

      return IncidentStats.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch incident statistics: $e',
        code: 'INCIDENT_STATS_ERROR',
      );
    }
  }

  /// Upload evidence file for incident
  Future<String> uploadEvidence({
    required int incidentId,
    required String filePath,
    required String fileName,
    String? description,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw const ApiException(
          message: 'Authentication required',
          code: 'AUTH_REQUIRED',
        );
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        if (description != null) 'description': description,
      });

      final response = await _apiService.post<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/incidents/$incidentId/evidence',
        data: formData,
      );

      return response.data?['file_url'] ?? '';
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(
        message: 'Failed to upload evidence: $e',
        code: 'EVIDENCE_UPLOAD_ERROR',
      );
    }
  }

  /// Get incidents assigned to current user
  Future<List<Incident>> getMyIncidents({
    String? status,
    String? priority,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw const ApiException(
          message: 'Authentication required',
          code: 'AUTH_REQUIRED',
        );
      }

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw const ApiException(
          message: 'User information not available',
          code: 'USER_INFO_ERROR',
        );
      }

      return getIncidents(
        assignedTo: currentUser.id,
        status: status,
        priority: priority,
        page: page,
        limit: limit,
      );
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch my incidents: $e',
        code: 'MY_INCIDENTS_ERROR',
      );
    }
  }

  /// Get recent incidents for dashboard
  Future<List<Incident>> getRecentIncidents({
    int limit = 10,
    int? siteId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'sort': 'created_at',
        'order': 'desc',
      };

      if (siteId != null) queryParams['site_id'] = siteId;

      final response = await _apiService.get<Map<String, dynamic>>(
        '${AppConstants.mobileApiBase}/incidents/recent',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data?['incidents'] ?? 
                                response.data?['data'] ?? [];

      return data.map((json) => Incident.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch recent incidents: $e',
        code: 'RECENT_INCIDENTS_ERROR',
      );
    }
  }
}