import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/checkpoint.dart';
import '../services/checkpoint_service.dart';
import '../services/auth_service.dart';

/// Checkpoint service provider
final checkpointServiceProvider = Provider<CheckpointService>((ref) {
  return CheckpointService.instance;
});

/// Checkpoints state
abstract class CheckpointsState {}

class CheckpointsInitial extends CheckpointsState {}
class CheckpointsLoading extends CheckpointsState {}
class CheckpointsLoaded extends CheckpointsState {
  final List<Checkpoint> checkpoints;
  CheckpointsLoaded(this.checkpoints);
}
class CheckpointsError extends CheckpointsState {
  final String message;
  CheckpointsError(this.message);
}

/// Checkpoint scanning state
abstract class ScanState {}

class ScanInitial extends ScanState {}
class ScanScanning extends ScanState {}
class ScanVerifying extends ScanState {}
class ScanSuccess extends ScanState {
  final CheckpointVisitResponse visitResponse;
  final Checkpoint checkpoint;
  ScanSuccess(this.visitResponse, this.checkpoint);
}
class ScanError extends ScanState {
  final String message;
  final String? errorCode;
  ScanError(this.message, {this.errorCode});
}

/// Checkpoints notifier
class CheckpointsNotifier extends StateNotifier<CheckpointsState> {
  final CheckpointService _checkpointService;
  final AuthService _authService;

  CheckpointsNotifier(this._checkpointService, this._authService) 
    : super(CheckpointsInitial());

  /// Load checkpoints
  Future<void> loadCheckpoints({int? siteId, bool? isActive}) async {
    state = CheckpointsLoading();
    
    try {
      final checkpoints = await _checkpointService.getCheckpoints(
        siteId: siteId,
        isActive: isActive,
      );
      state = CheckpointsLoaded(checkpoints);
    } catch (e) {
      state = CheckpointsError(e.toString());
    }
  }

  /// Refresh checkpoints
  Future<void> refreshCheckpoints() async {
    if (state is CheckpointsLoaded) {
      await loadCheckpoints();
    }
  }
}

/// Checkpoint scanning notifier
class ScanNotifier extends StateNotifier<ScanState> {
  final CheckpointService _checkpointService;
  final AuthService _authService;

  ScanNotifier(this._checkpointService, this._authService) 
    : super(ScanInitial());

  /// Scan QR code
  Future<void> scanQRCode({
    required String qrCode,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) async {
    await _performScan(
      code: qrCode,
      scanMethod: 'qr',
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      notes: notes,
    );
  }

  /// Scan NFC tag
  Future<void> scanNFCTag({
    required String nfcTag,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) async {
    await _performScan(
      code: nfcTag,
      scanMethod: 'nfc',
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      notes: notes,
    );
  }

  /// Manual checkpoint entry
  Future<void> manualEntry({
    required String checkpointCode,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) async {
    await _performScan(
      code: checkpointCode,
      scanMethod: 'manual',
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      notes: notes,
    );
  }

  /// Perform scan operation
  Future<void> _performScan({
    required String code,
    required String scanMethod,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) async {
    state = ScanScanning();

    try {
      // First verify the code
      state = ScanVerifying();
      
      final verification = await _checkpointService.verifyCode(
        code: code,
        scanMethod: scanMethod,
        latitude: latitude,
        longitude: longitude,
      );

      if (!verification.isValid) {
        state = ScanError(
          verification.message.isNotEmpty 
            ? verification.message 
            : 'Invalid checkpoint code',
          errorCode: verification.errorCode,
        );
        return;
      }

      // Create visit request
      final CheckpointVisitRequest visitRequest;
      
      switch (scanMethod) {
        case 'qr':
          visitRequest = CheckpointVisitRequest.qrScan(
            qrCode: code,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            notes: notes,
          );
          break;
        case 'nfc':
          visitRequest = CheckpointVisitRequest.nfcScan(
            nfcTag: code,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            notes: notes,
          );
          break;
        case 'manual':
          visitRequest = CheckpointVisitRequest.manual(
            checkpointCode: code,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            notes: notes,
          );
          break;
        default:
          throw Exception('Unknown scan method: $scanMethod');
      }

      // Record the visit
      final visitResponse = await _checkpointService.recordVisit(visitRequest);

      if (visitResponse.success) {
        state = ScanSuccess(
          visitResponse,
          verification.checkpoint ?? 
          visitResponse.checkpoint ?? 
          Checkpoint(
            id: visitResponse.visitId ?? 0,
            name: 'Unknown Checkpoint',
            code: code,
            isActive: true,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          ),
        );
      } else {
        state = ScanError(visitResponse.message);
      }
      
    } catch (e) {
      state = ScanError(e.toString());
    }
  }

  /// Reset scan state
  void resetScan() {
    state = ScanInitial();
  }

  /// Set scanning state (for UI feedback during actual scanning)
  void setScanning() {
    state = ScanScanning();
  }
}

/// Checkpoints provider
final checkpointsProvider = StateNotifierProvider<CheckpointsNotifier, CheckpointsState>((ref) {
  final checkpointService = ref.read(checkpointServiceProvider);
  final authService = AuthService.instance;
  return CheckpointsNotifier(checkpointService, authService);
});

/// Scan provider
final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  final checkpointService = ref.read(checkpointServiceProvider);
  final authService = AuthService.instance;
  return ScanNotifier(checkpointService, authService);
});

/// Checkpoint stats provider
final checkpointStatsProvider = FutureProvider<CheckpointStats>((ref) async {
  final checkpointService = ref.read(checkpointServiceProvider);
  return await checkpointService.getCheckpointStats();
});

/// Recent visits provider
final recentVisitsProvider = FutureProvider<List<CheckpointVisit>>((ref) async {
  final checkpointService = ref.read(checkpointServiceProvider);
  return await checkpointService.getVisitHistory(limit: 10);
});

/// Computed providers
final isLoadingCheckpointsProvider = Provider<bool>((ref) {
  final state = ref.watch(checkpointsProvider);
  return state is CheckpointsLoading;
});

final isScanningProvider = Provider<bool>((ref) {
  final state = ref.watch(scanProvider);
  return state is ScanScanning || state is ScanVerifying;
});

final hasScanErrorProvider = Provider<bool>((ref) {
  final state = ref.watch(scanProvider);
  return state is ScanError;
});

final scanErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(scanProvider);
  if (state is ScanError) {
    return state.message;
  }
  return null;
});

final hasScanSuccessProvider = Provider<bool>((ref) {
  final state = ref.watch(scanProvider);
  return state is ScanSuccess;
});

final scanSuccessDataProvider = Provider<ScanSuccess?>((ref) {
  final state = ref.watch(scanProvider);
  if (state is ScanSuccess) {
    return state;
  }
  return null;
});