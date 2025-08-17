import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/intelligent_sync_scheduling_service.dart';

/// Provider for intelligent sync scheduling service
final intelligentSyncSchedulingServiceProvider = Provider<IntelligentSyncSchedulingService>((ref) {
  return IntelligentSyncSchedulingService.instance;
});

/// Provider for current sync statistics
final syncStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(intelligentSyncSchedulingServiceProvider);
  return service.getSyncStatistics();
});

/// Provider for sync statistics that auto-refreshes
final autoRefreshSyncStatisticsProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final service = ref.read(intelligentSyncSchedulingServiceProvider);
  
  // Emit initial statistics
  yield service.getSyncStatistics();
  
  // Then emit updates every 30 seconds
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    yield service.getSyncStatistics();
  }
});

/// Provider for triggering immediate sync
final immediateSyncProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final service = ref.read(intelligentSyncSchedulingServiceProvider);
  await service.triggerImmediateSync(
    criticalOnly: params['criticalOnly'] ?? false,
    reason: params['reason'],
  );
});

/// Provider for sync control actions
class SyncControlNotifier extends StateNotifier<AsyncValue<String?>> {
  final IntelligentSyncSchedulingService _service;

  SyncControlNotifier(this._service) : super(const AsyncValue.data(null));

  /// Pause background sync
  Future<void> pauseSync() async {
    state = const AsyncValue.loading();
    try {
      await _service.pauseBackgroundSync();
      state = const AsyncValue.data('Background sync paused');
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Resume background sync
  Future<void> resumeSync() async {
    state = const AsyncValue.loading();
    try {
      await _service.resumeBackgroundSync();
      state = const AsyncValue.data('Background sync resumed');
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Trigger immediate sync
  Future<void> triggerSync({bool criticalOnly = false, String? reason}) async {
    state = const AsyncValue.loading();
    try {
      await _service.triggerImmediateSync(
        criticalOnly: criticalOnly,
        reason: reason ?? 'manual_trigger',
      );
      state = AsyncValue.data(criticalOnly ? 'Critical sync triggered' : 'Full sync triggered');
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Clear status message
  void clearStatus() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for sync control actions
final syncControlProvider = StateNotifierProvider<SyncControlNotifier, AsyncValue<String?>>((ref) {
  final service = ref.read(intelligentSyncSchedulingServiceProvider);
  return SyncControlNotifier(service);
});