import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patrol_simple.dart';
import '../models/patrol_history.dart';
import '../models/checkpoint.dart';
import '../services/patrol_service.dart';
import '../services/auth_service.dart';
import 'auth_provider.dart';

/// Provider for patrol service
final patrolServiceProvider = Provider<PatrolService>((ref) {
  return PatrolService.instance;
});

/// Provider for auth service (used in patrol providers)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

/// Patrol list state
sealed class PatrolListState {
  const PatrolListState();
}

class PatrolListInitial extends PatrolListState {
  const PatrolListInitial();
}

class PatrolListLoading extends PatrolListState {
  const PatrolListLoading();
}

class PatrolListLoaded extends PatrolListState {
  final List<Patrol> patrols;
  const PatrolListLoaded(this.patrols);
}

class PatrolListError extends PatrolListState {
  final String message;
  const PatrolListError(this.message);
}

/// Patrol list notifier
class PatrolListNotifier extends StateNotifier<PatrolListState> {
  final PatrolService _patrolService;
  final AuthService _authService;

  PatrolListNotifier(this._patrolService, this._authService) 
    : super(const PatrolListInitial());

  /// Load assigned patrols for current user
  Future<void> loadAssignedPatrols({
    String? status,
    int? siteId,
    bool refresh = false,
  }) async {
    if (!refresh && state is PatrolListLoaded) return;
    
    state = const PatrolListLoading();

    try {
      final patrols = await _patrolService.getAssignedPatrols(
        status: status,
        siteId: siteId,
      );
      state = PatrolListLoaded(patrols);
    } catch (e) {
      state = PatrolListError(e.toString());
    }
  }

  /// Load active patrols (for supervisors/managers)
  Future<void> loadActivePatrols({
    int? siteId,
    int? assignedTo,
    bool refresh = false,
  }) async {
    if (!refresh && state is PatrolListLoaded) return;
    
    state = const PatrolListLoading();

    try {
      final patrols = await _patrolService.getActivePatrols(
        siteId: siteId,
        assignedTo: assignedTo,
      );
      state = PatrolListLoaded(patrols);
    } catch (e) {
      state = PatrolListError(e.toString());
    }
  }

  /// Search patrols
  Future<void> searchPatrols({
    String? query,
    String? status,
    int? siteId,
    int? assignedTo,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const PatrolListLoading();

    try {
      final patrols = await _patrolService.searchPatrols(
        query: query,
        status: status,
        siteId: siteId,
        assignedTo: assignedTo,
        startDate: startDate,
        endDate: endDate,
      );
      state = PatrolListLoaded(patrols);
    } catch (e) {
      state = PatrolListError(e.toString());
    }
  }

  /// Refresh patrols
  Future<void> refresh() async {
    await loadAssignedPatrols(refresh: true);
  }
}

/// Patrol list provider
final patrolListProvider = StateNotifierProvider<PatrolListNotifier, PatrolListState>((ref) {
  return PatrolListNotifier(
    ref.read(patrolServiceProvider),
    ref.read(authServiceProvider),
  );
});

/// Current patrol state
sealed class CurrentPatrolState {
  const CurrentPatrolState();
}

class CurrentPatrolInitial extends CurrentPatrolState {
  const CurrentPatrolInitial();
}

class CurrentPatrolLoading extends CurrentPatrolState {
  const CurrentPatrolLoading();
}

class CurrentPatrolLoaded extends CurrentPatrolState {
  final Patrol patrol;
  final PatrolRoute route;
  final PatrolProgress progress;
  
  const CurrentPatrolLoaded({
    required this.patrol,
    required this.route,
    required this.progress,
  });
}

class CurrentPatrolError extends CurrentPatrolState {
  final String message;
  const CurrentPatrolError(this.message);
}

/// Current patrol notifier
class CurrentPatrolNotifier extends StateNotifier<CurrentPatrolState> {
  final PatrolService _patrolService;

  CurrentPatrolNotifier(this._patrolService) : super(const CurrentPatrolInitial());

  /// Load patrol details
  Future<void> loadPatrol(int patrolId) async {
    state = const CurrentPatrolLoading();

    try {
      final futures = await Future.wait([
        _patrolService.getPatrol(patrolId),
        _patrolService.getPatrolRoute(patrolId),
        _patrolService.getPatrolProgress(patrolId),
      ]);

      state = CurrentPatrolLoaded(
        patrol: futures[0] as Patrol,
        route: futures[1] as PatrolRoute,
        progress: futures[2] as PatrolProgress,
      );
    } catch (e) {
      state = CurrentPatrolError(e.toString());
    }
  }

  /// Start patrol
  Future<bool> startPatrol(int patrolId, {
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) async {
    try {
      final response = await _patrolService.startPatrol(
        patrolId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        notes: notes,
      );

      if (response.success) {
        // Reload patrol data after starting
        await loadPatrol(patrolId);
        return true;
      }
      return false;
    } catch (e) {
      state = CurrentPatrolError(e.toString());
      return false;
    }
  }

  /// End patrol
  Future<bool> endPatrol(int patrolId, {
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) async {
    try {
      final response = await _patrolService.endPatrol(
        patrolId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        notes: notes,
      );

      if (response.success) {
        // Reload patrol data after ending
        await loadPatrol(patrolId);
        return true;
      }
      return false;
    } catch (e) {
      state = CurrentPatrolError(e.toString());
      return false;
    }
  }

  /// Visit checkpoint during patrol
  Future<bool> visitCheckpoint(
    int patrolId,
    CheckpointVisitRequest visitRequest,
  ) async {
    try {
      final response = await _patrolService.visitCheckpointOptimized(
        patrolId,
        visitRequest,
      );

      if (response.success) {
        // Reload progress after checkpoint visit
        final currentState = state;
        if (currentState is CurrentPatrolLoaded) {
          final updatedProgress = await _patrolService.getPatrolProgress(patrolId);
          state = CurrentPatrolLoaded(
            patrol: currentState.patrol,
            route: currentState.route,
            progress: updatedProgress,
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      state = CurrentPatrolError(e.toString());
      return false;
    }
  }

  /// Refresh current patrol data
  Future<void> refresh() async {
    final currentState = state;
    if (currentState is CurrentPatrolLoaded) {
      await loadPatrol(currentState.patrol.id);
    }
  }

  /// Clear current patrol
  void clear() {
    state = const CurrentPatrolInitial();
  }
}

/// Current patrol provider
final currentPatrolProvider = StateNotifierProvider<CurrentPatrolNotifier, CurrentPatrolState>((ref) {
  return CurrentPatrolNotifier(ref.read(patrolServiceProvider));
});

/// Patrol history state
sealed class PatrolHistoryState {
  const PatrolHistoryState();
}

class PatrolHistoryInitial extends PatrolHistoryState {
  const PatrolHistoryInitial();
}

class PatrolHistoryLoading extends PatrolHistoryState {
  const PatrolHistoryLoading();
}

class PatrolHistoryLoaded extends PatrolHistoryState {
  final List<PatrolHistoryEntry> history;
  const PatrolHistoryLoaded(this.history);
}

class PatrolHistoryError extends PatrolHistoryState {
  final String message;
  const PatrolHistoryError(this.message);
}

/// Patrol history notifier
class PatrolHistoryNotifier extends StateNotifier<PatrolHistoryState> {
  final PatrolService _patrolService;
  final AuthService _authService;

  PatrolHistoryNotifier(this._patrolService, this._authService) 
    : super(const PatrolHistoryInitial());

  /// Load patrol history
  Future<void> loadHistory({
    int? userId,
    int? siteId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    bool refresh = false,
  }) async {
    if (!refresh && state is PatrolHistoryLoaded) return;
    
    state = const PatrolHistoryLoading();

    try {
      final history = await _patrolService.getPatrolHistory(
        userId: userId,
        siteId: siteId,
        status: status,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
      state = PatrolHistoryLoaded(history);
    } catch (e) {
      state = PatrolHistoryError(e.toString());
    }
  }

  /// Load user's own history
  Future<void> loadMyHistory({
    int? siteId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    bool refresh = false,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      state = const PatrolHistoryError('User not authenticated');
      return;
    }

    await loadHistory(
      userId: currentUser.id,
      siteId: siteId,
      status: status,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      refresh: refresh,
    );
  }

  /// Refresh history
  Future<void> refresh() async {
    if (state is PatrolHistoryLoaded) {
      await loadMyHistory(refresh: true);
    }
  }
}

/// Patrol history provider
final patrolHistoryProvider = StateNotifierProvider<PatrolHistoryNotifier, PatrolHistoryState>((ref) {
  return PatrolHistoryNotifier(
    ref.read(patrolServiceProvider),
    ref.read(authServiceProvider),
  );
});

/// Statistics state
sealed class PatrolStatsState {
  const PatrolStatsState();
}

class PatrolStatsInitial extends PatrolStatsState {
  const PatrolStatsInitial();
}

class PatrolStatsLoading extends PatrolStatsState {
  const PatrolStatsLoading();
}

class PatrolStatsLoaded extends PatrolStatsState {
  final Map<String, dynamic> statistics;
  const PatrolStatsLoaded(this.statistics);
}

class PatrolStatsError extends PatrolStatsState {
  final String message;
  const PatrolStatsError(this.message);
}

/// Patrol statistics notifier
class PatrolStatsNotifier extends StateNotifier<PatrolStatsState> {
  final PatrolService _patrolService;

  PatrolStatsNotifier(this._patrolService) : super(const PatrolStatsInitial());

  /// Load patrol statistics
  Future<void> loadStatistics({
    int? siteId,
    DateTime? startDate,
    DateTime? endDate,
    bool refresh = false,
  }) async {
    if (!refresh && state is PatrolStatsLoaded) return;
    
    state = const PatrolStatsLoading();

    try {
      final statistics = await _patrolService.getPatrolStatistics(
        siteId: siteId,
        startDate: startDate,
        endDate: endDate,
      );
      state = PatrolStatsLoaded(statistics);
    } catch (e) {
      state = PatrolStatsError(e.toString());
    }
  }

  /// Refresh statistics
  Future<void> refresh() async {
    await loadStatistics(refresh: true);
  }
}

/// Patrol statistics provider
final patrolStatsProvider = StateNotifierProvider<PatrolStatsNotifier, PatrolStatsState>((ref) {
  return PatrolStatsNotifier(ref.read(patrolServiceProvider));
});

/// Helper providers for specific data needs

/// Provider for user's assigned patrols only
final myPatrolsProvider = FutureProvider<List<Patrol>>((ref) async {
  final patrolService = ref.read(patrolServiceProvider);
  return await patrolService.getAssignedPatrols(status: 'pending');
});

/// Provider for active patrols (supervisor view)
final activePatrolsProvider = FutureProvider<List<Patrol>>((ref) async {
  final patrolService = ref.read(patrolServiceProvider);
  return await patrolService.getActivePatrols();
});

/// Provider for today's patrol statistics
final todayStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final patrolService = ref.read(patrolServiceProvider);
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  
  return await patrolService.getPatrolStatistics(
    startDate: startOfDay,
    endDate: endOfDay,
  );
});

/// Provider for live patrol status (monitoring)
final livePatrolStatusProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final patrolService = ref.read(patrolServiceProvider);
  return await patrolService.getLivePatrolStatus();
});

/// Patrol detail state
sealed class PatrolDetailState {
  const PatrolDetailState();
}

class PatrolDetailInitial extends PatrolDetailState {
  const PatrolDetailInitial();
}

class PatrolDetailLoading extends PatrolDetailState {
  const PatrolDetailLoading();
}

class PatrolDetailLoaded extends PatrolDetailState {
  final Patrol patrol;
  const PatrolDetailLoaded(this.patrol);
}

class PatrolDetailError extends PatrolDetailState {
  final String message;
  const PatrolDetailError(this.message);
}

/// Patrol detail notifier
class PatrolDetailNotifier extends StateNotifier<PatrolDetailState> {
  final int patrolId;
  final PatrolService _patrolService;
  final AuthService _authService;

  PatrolDetailNotifier(this.patrolId, this._patrolService, this._authService) 
    : super(const PatrolDetailInitial());

  /// Load patrol details
  Future<void> loadPatrol() async {
    state = const PatrolDetailLoading();

    try {
      final patrol = await _patrolService.getPatrol(patrolId);
      state = PatrolDetailLoaded(patrol);
    } catch (e) {
      state = PatrolDetailError(e.toString());
    }
  }

  /// Complete patrol
  Future<void> completePatrol(Map<String, dynamic> completionData) async {
    try {
      await _patrolService.completePatrol(
        patrolId,
        latitude: completionData['latitude'],
        longitude: completionData['longitude'],
        accuracy: completionData['accuracy'],
        notes: completionData['notes'],
      );
      // Reload patrol data after completion
      await loadPatrol();
    } catch (e) {
      rethrow;
    }
  }

  /// Start patrol
  Future<void> startPatrol({
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) async {
    try {
      await _patrolService.startPatrol(
        patrolId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        notes: notes,
      );
      // Reload patrol data after starting
      await loadPatrol();
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel patrol
  Future<void> cancelPatrol(String reason) async {
    try {
      await _patrolService.cancelPatrol(
        patrolId,
        reason: reason,
      );
      // Reload patrol data after cancellation
      await loadPatrol();
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh patrol data
  Future<void> refresh() async {
    await loadPatrol();
  }
}

/// Patrol detail provider factory
final patrolDetailProvider = StateNotifierProvider.family<PatrolDetailNotifier, PatrolDetailState, int>((ref, patrolId) {
  return PatrolDetailNotifier(
    patrolId,
    ref.read(patrolServiceProvider),
    ref.read(authServiceProvider),
  );
});