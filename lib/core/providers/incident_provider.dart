import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';
import '../exceptions/api_exception.dart';

/// Incident service provider
final incidentServiceProvider = Provider<IncidentService>((ref) {
  return IncidentService.instance;
});

/// Incident list state
class IncidentListState {
  final List<Incident> incidents;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const IncidentListState({
    this.incidents = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  IncidentListState copyWith({
    List<Incident>? incidents,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return IncidentListState(
      incidents: incidents ?? this.incidents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Incident list notifier
class IncidentListNotifier extends StateNotifier<IncidentListState> {
  final IncidentService _incidentService;
  
  IncidentListNotifier(this._incidentService) : super(const IncidentListState());

  /// Load incidents with optional filters
  Future<void> loadIncidents({
    String? status,
    String? priority,
    String? category,
    int? siteId,
    bool refresh = false,
  }) async {
    if (state.isLoading) return;

    if (refresh) {
      state = const IncidentListState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final incidents = await _incidentService.getIncidents(
        status: status,
        priority: priority,
        category: category,
        siteId: siteId,
        page: refresh ? 1 : state.currentPage,
        limit: 20,
      );

      if (refresh) {
        state = IncidentListState(
          incidents: incidents,
          isLoading: false,
          hasMore: incidents.length >= 20,
          currentPage: 1,
        );
      } else {
        state = state.copyWith(
          incidents: [...state.incidents, ...incidents],
          isLoading: false,
          hasMore: incidents.length >= 20,
          currentPage: state.currentPage + 1,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is ApiException ? e.message : e.toString(),
      );
    }
  }

  /// Load more incidents
  Future<void> loadMore({
    String? status,
    String? priority,
    String? category,
    int? siteId,
  }) async {
    if (!state.hasMore || state.isLoading) return;

    await loadIncidents(
      status: status,
      priority: priority,
      category: category,
      siteId: siteId,
      refresh: false,
    );
  }

  /// Refresh incidents
  Future<void> refresh({
    String? status,
    String? priority,
    String? category,
    int? siteId,
  }) async {
    await loadIncidents(
      status: status,
      priority: priority,
      category: category,
      siteId: siteId,
      refresh: true,
    );
  }

  /// Clear incidents list
  void clear() {
    state = const IncidentListState();
  }
}

/// Incident list provider
final incidentListProvider = StateNotifierProvider<IncidentListNotifier, IncidentListState>((ref) {
  return IncidentListNotifier(ref.read(incidentServiceProvider));
});

/// Incident creation state
class IncidentCreationState {
  final bool isLoading;
  final String? error;
  final IncidentResponse? response;

  const IncidentCreationState({
    this.isLoading = false,
    this.error,
    this.response,
  });

  IncidentCreationState copyWith({
    bool? isLoading,
    String? error,
    IncidentResponse? response,
  }) {
    return IncidentCreationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      response: response ?? this.response,
    );
  }
}

/// Incident creation notifier
class IncidentCreationNotifier extends StateNotifier<IncidentCreationState> {
  final IncidentService _incidentService;
  
  IncidentCreationNotifier(this._incidentService) : super(const IncidentCreationState());

  /// Create a new incident
  Future<bool> createIncident({
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
    state = const IncidentCreationState(isLoading: true);

    try {
      final response = await _incidentService.createIncident(
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

      state = IncidentCreationState(
        isLoading: false,
        response: response,
      );

      return response.success;
    } catch (e) {
      state = IncidentCreationState(
        isLoading: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      return false;
    }
  }

  /// Reset creation state
  void reset() {
    state = const IncidentCreationState();
  }
}

/// Incident creation provider
final incidentCreationProvider = StateNotifierProvider<IncidentCreationNotifier, IncidentCreationState>((ref) {
  return IncidentCreationNotifier(ref.read(incidentServiceProvider));
});

/// Single incident provider
final incidentProvider = FutureProvider.family<Incident, int>((ref, incidentId) async {
  final incidentService = ref.read(incidentServiceProvider);
  return await incidentService.getIncident(incidentId);
});

/// My incidents provider (assigned to current user)
final myIncidentsProvider = FutureProvider<List<Incident>>((ref) async {
  final incidentService = ref.read(incidentServiceProvider);
  return await incidentService.getMyIncidents();
});

/// Recent incidents provider
final recentIncidentsProvider = FutureProvider.family<List<Incident>, int?>((ref, siteId) async {
  final incidentService = ref.read(incidentServiceProvider);
  return await incidentService.getRecentIncidents(siteId: siteId);
});

/// Incident statistics provider
final incidentStatsProvider = FutureProvider.family<IncidentStats, int?>((ref, siteId) async {
  final incidentService = ref.read(incidentServiceProvider);
  return await incidentService.getIncidentStats(siteId: siteId);
});

/// Incident update state
class IncidentUpdateState {
  final bool isLoading;
  final String? error;
  final IncidentResponse? response;

  const IncidentUpdateState({
    this.isLoading = false,
    this.error,
    this.response,
  });

  IncidentUpdateState copyWith({
    bool? isLoading,
    String? error,
    IncidentResponse? response,
  }) {
    return IncidentUpdateState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      response: response ?? this.response,
    );
  }
}

/// Incident update notifier
class IncidentUpdateNotifier extends StateNotifier<IncidentUpdateState> {
  final IncidentService _incidentService;
  
  IncidentUpdateNotifier(this._incidentService) : super(const IncidentUpdateState());

  /// Update incident status
  Future<bool> updateIncident({
    required int incidentId,
    String? status,
    String? notes,
    int? assignedTo,
    String? resolutionNotes,
  }) async {
    state = const IncidentUpdateState(isLoading: true);

    try {
      final response = await _incidentService.updateIncident(
        incidentId: incidentId,
        status: status,
        notes: notes,
        assignedTo: assignedTo,
        resolutionNotes: resolutionNotes,
      );

      state = IncidentUpdateState(
        isLoading: false,
        response: response,
      );

      return response.success;
    } catch (e) {
      state = IncidentUpdateState(
        isLoading: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      return false;
    }
  }

  /// Assign incident
  Future<bool> assignIncident({
    required int incidentId,
    required int assignedTo,
    String? notes,
  }) async {
    state = const IncidentUpdateState(isLoading: true);

    try {
      final response = await _incidentService.assignIncident(
        incidentId: incidentId,
        assignedTo: assignedTo,
        notes: notes,
      );

      state = IncidentUpdateState(
        isLoading: false,
        response: response,
      );

      return response.success;
    } catch (e) {
      state = IncidentUpdateState(
        isLoading: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      return false;
    }
  }

  /// Resolve incident
  Future<bool> resolveIncident({
    required int incidentId,
    required String resolutionNotes,
  }) async {
    state = const IncidentUpdateState(isLoading: true);

    try {
      final response = await _incidentService.resolveIncident(
        incidentId: incidentId,
        resolutionNotes: resolutionNotes,
      );

      state = IncidentUpdateState(
        isLoading: false,
        response: response,
      );

      return response.success;
    } catch (e) {
      state = IncidentUpdateState(
        isLoading: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      return false;
    }
  }

  /// Reset update state
  void reset() {
    state = const IncidentUpdateState();
  }
}

/// Incident update provider
final incidentUpdateProvider = StateNotifierProvider<IncidentUpdateNotifier, IncidentUpdateState>((ref) {
  return IncidentUpdateNotifier(ref.read(incidentServiceProvider));
});

/// Evidence upload state
class EvidenceUploadState {
  final bool isLoading;
  final String? error;
  final String? fileUrl;

  const EvidenceUploadState({
    this.isLoading = false,
    this.error,
    this.fileUrl,
  });

  EvidenceUploadState copyWith({
    bool? isLoading,
    String? error,
    String? fileUrl,
  }) {
    return EvidenceUploadState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      fileUrl: fileUrl ?? this.fileUrl,
    );
  }
}

/// Evidence upload notifier
class EvidenceUploadNotifier extends StateNotifier<EvidenceUploadState> {
  final IncidentService _incidentService;
  
  EvidenceUploadNotifier(this._incidentService) : super(const EvidenceUploadState());

  /// Upload evidence file
  Future<String?> uploadEvidence({
    required int incidentId,
    required String filePath,
    required String fileName,
    String? description,
  }) async {
    state = const EvidenceUploadState(isLoading: true);

    try {
      final fileUrl = await _incidentService.uploadEvidence(
        incidentId: incidentId,
        filePath: filePath,
        fileName: fileName,
        description: description,
      );

      state = EvidenceUploadState(
        isLoading: false,
        fileUrl: fileUrl,
      );

      return fileUrl;
    } catch (e) {
      state = EvidenceUploadState(
        isLoading: false,
        error: e is ApiException ? e.message : e.toString(),
      );
      return null;
    }
  }

  /// Reset upload state
  void reset() {
    state = const EvidenceUploadState();
  }
}

/// Evidence upload provider
final evidenceUploadProvider = StateNotifierProvider<EvidenceUploadNotifier, EvidenceUploadState>((ref) {
  return EvidenceUploadNotifier(ref.read(incidentServiceProvider));
});