import 'package:json_annotation/json_annotation.dart';

part 'checkpoint.g.dart';

/// Checkpoint model representing physical checkpoint locations
@JsonSerializable()
class Checkpoint {
  final int id;
  final String name;
  final String code;
  final String? description;
  @JsonKey(name: 'qr_code')
  final String? qrCode;
  @JsonKey(name: 'nfc_tag')
  final String? nfcTag;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'location_name')
  final String? locationName;
  @JsonKey(name: 'site_id')
  final int? siteId;
  @JsonKey(name: 'site_name')
  final String? siteName;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  @JsonKey(name: 'last_visit_at')
  final String? lastVisitAt;

  const Checkpoint({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.qrCode,
    this.nfcTag,
    this.latitude,
    this.longitude,
    this.locationName,
    this.siteId,
    this.siteName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastVisitAt,
  });

  factory Checkpoint.fromJson(Map<String, dynamic> json) => 
      _$CheckpointFromJson(json);
  Map<String, dynamic> toJson() => _$CheckpointToJson(this);

  /// Check if checkpoint has QR code
  bool get hasQRCode => qrCode != null && qrCode!.isNotEmpty;

  /// Check if checkpoint has NFC tag
  bool get hasNFCTag => nfcTag != null && nfcTag!.isNotEmpty;

  /// Check if checkpoint has location data
  bool get hasLocation => latitude != null && longitude != null;

  @override
  String toString() {
    return 'Checkpoint(id: $id, name: $name, code: $code, isActive: $isActive)';
  }
}

/// Checkpoint visit model for recording checkpoint scans
@JsonSerializable()
class CheckpointVisit {
  final int id;
  @JsonKey(name: 'checkpoint_id')
  final int checkpointId;
  @JsonKey(name: 'checkpoint_name')
  final String? checkpointName;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'user_name')
  final String? userName;
  @JsonKey(name: 'scan_method')
  final String scanMethod; // 'qr', 'nfc', 'manual'
  @JsonKey(name: 'scanned_code')
  final String? scannedCode;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'location_accuracy')
  final double? locationAccuracy;
  final String? notes;
  @JsonKey(name: 'visited_at')
  final String visitedAt;
  @JsonKey(name: 'sync_status')
  final String? syncStatus; // 'synced', 'pending', 'failed'

  const CheckpointVisit({
    required this.id,
    required this.checkpointId,
    this.checkpointName,
    required this.userId,
    this.userName,
    required this.scanMethod,
    this.scannedCode,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.notes,
    required this.visitedAt,
    this.syncStatus,
  });

  factory CheckpointVisit.fromJson(Map<String, dynamic> json) => 
      _$CheckpointVisitFromJson(json);
  Map<String, dynamic> toJson() => _$CheckpointVisitToJson(this);

  /// Check if visit is synced with server
  bool get isSynced => syncStatus == 'synced';

  /// Check if visit is pending sync
  bool get isPending => syncStatus == 'pending';

  /// Check if visit has location data
  bool get hasLocation => latitude != null && longitude != null;

  @override
  String toString() {
    return 'CheckpointVisit(id: $id, checkpointId: $checkpointId, method: $scanMethod, synced: $isSynced)';
  }
}

/// Checkpoint visit request for creating new visits
@JsonSerializable()
class CheckpointVisitRequest {
  @JsonKey(name: 'checkpoint_id')
  final int? checkpointId;
  @JsonKey(name: 'checkpoint_code')
  final String? checkpointCode;
  @JsonKey(name: 'scan_method')
  final String scanMethod;
  @JsonKey(name: 'scanned_code')
  final String scannedCode;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'location_accuracy')
  final double? locationAccuracy;
  final String? notes;
  @JsonKey(name: 'device_timestamp')
  final String deviceTimestamp;

  const CheckpointVisitRequest({
    this.checkpointId,
    this.checkpointCode,
    required this.scanMethod,
    required this.scannedCode,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.notes,
    required this.deviceTimestamp,
  });

  factory CheckpointVisitRequest.fromJson(Map<String, dynamic> json) => 
      _$CheckpointVisitRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CheckpointVisitRequestToJson(this);

  /// Create QR scan request
  factory CheckpointVisitRequest.qrScan({
    int? checkpointId,
    String? checkpointCode,
    required String qrCode,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) {
    return CheckpointVisitRequest(
      checkpointId: checkpointId,
      checkpointCode: checkpointCode,
      scanMethod: 'qr',
      scannedCode: qrCode,
      latitude: latitude,
      longitude: longitude,
      locationAccuracy: accuracy,
      notes: notes,
      deviceTimestamp: DateTime.now().toIso8601String(),
    );
  }

  /// Create NFC scan request
  factory CheckpointVisitRequest.nfcScan({
    int? checkpointId,
    String? checkpointCode,
    required String nfcTag,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) {
    return CheckpointVisitRequest(
      checkpointId: checkpointId,
      checkpointCode: checkpointCode,
      scanMethod: 'nfc',
      scannedCode: nfcTag,
      latitude: latitude,
      longitude: longitude,
      locationAccuracy: accuracy,
      notes: notes,
      deviceTimestamp: DateTime.now().toIso8601String(),
    );
  }

  /// Create manual entry request
  factory CheckpointVisitRequest.manual({
    int? checkpointId,
    required String checkpointCode,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) {
    return CheckpointVisitRequest(
      checkpointId: checkpointId,
      checkpointCode: checkpointCode,
      scanMethod: 'manual',
      scannedCode: checkpointCode,
      latitude: latitude,
      longitude: longitude,
      locationAccuracy: accuracy,
      notes: notes,
      deviceTimestamp: DateTime.now().toIso8601String(),
    );
  }
}

/// Checkpoint visit response
@JsonSerializable()
class CheckpointVisitResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'visit_id')
  final int? visitId;
  final CheckpointVisit? visit;
  final Checkpoint? checkpoint;

  const CheckpointVisitResponse({
    required this.success,
    required this.message,
    this.visitId,
    this.visit,
    this.checkpoint,
  });

  factory CheckpointVisitResponse.fromJson(Map<String, dynamic> json) => 
      _$CheckpointVisitResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CheckpointVisitResponseToJson(this);

  @override
  String toString() {
    return 'CheckpointVisitResponse(success: $success, visitId: $visitId, message: $message)';
  }
}

/// Checkpoint statistics
@JsonSerializable()
class CheckpointStats {
  @JsonKey(name: 'total_checkpoints')
  final int totalCheckpoints;
  @JsonKey(name: 'visited_today')
  final int visitedToday;
  @JsonKey(name: 'pending_visits')
  final int pendingVisits;
  @JsonKey(name: 'completion_rate')
  final double completionRate;
  @JsonKey(name: 'last_visit_time')
  final String? lastVisitTime;

  const CheckpointStats({
    required this.totalCheckpoints,
    required this.visitedToday,
    required this.pendingVisits,
    required this.completionRate,
    this.lastVisitTime,
  });

  factory CheckpointStats.fromJson(Map<String, dynamic> json) => 
      _$CheckpointStatsFromJson(json);
  Map<String, dynamic> toJson() => _$CheckpointStatsToJson(this);

  @override
  String toString() {
    return 'CheckpointStats(total: $totalCheckpoints, visited: $visitedToday, completion: ${(completionRate * 100).toStringAsFixed(1)}%)';
  }
}