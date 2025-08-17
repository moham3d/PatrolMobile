import 'package:json_annotation/json_annotation.dart';

part 'incident.g.dart';

/// Incident model for reporting and tracking incidents
@JsonSerializable()
class Incident {
  final int id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  @JsonKey(name: 'created_by')
  final int createdBy;
  @JsonKey(name: 'assigned_to')
  final int? assignedTo;
  @JsonKey(name: 'site_id')
  final int? siteId;
  @JsonKey(name: 'location_id')
  final int? locationId;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'location_accuracy')
  final double? locationAccuracy;
  final String? notes;
  @JsonKey(name: 'evidence_files')
  final List<String>? evidenceFiles;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'resolved_at')
  final DateTime? resolvedAt;

  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdBy,
    this.assignedTo,
    this.siteId,
    this.locationId,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.notes,
    this.evidenceFiles,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  factory Incident.fromJson(Map<String, dynamic> json) => _$IncidentFromJson(json);
  Map<String, dynamic> toJson() => _$IncidentToJson(this);

  /// Get priority level as integer for sorting
  int get priorityLevel {
    switch (priority.toLowerCase()) {
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  /// Check if incident is resolved
  bool get isResolved => status.toLowerCase() == 'resolved' || resolvedAt != null;

  /// Check if incident is in progress
  bool get isInProgress => status.toLowerCase() == 'in_progress' || status.toLowerCase() == 'assigned';

  /// Check if incident is open
  bool get isOpen => status.toLowerCase() == 'open' || status.toLowerCase() == 'reported';

  /// Get status color for UI
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'resolved':
        return 'green';
      case 'in_progress':
      case 'assigned':
        return 'blue';
      case 'open':
      case 'reported':
        return 'orange';
      default:
        return 'grey';
    }
  }

  /// Get priority color for UI
  String get priorityColor {
    switch (priority.toLowerCase()) {
      case 'critical':
        return 'red';
      case 'high':
        return 'orange';
      case 'medium':
        return 'yellow';
      case 'low':
        return 'green';
      default:
        return 'grey';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Incident &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Incident(id: $id, title: $title, status: $status, priority: $priority)';
}

/// Incident request model for creating new incidents
@JsonSerializable()
class IncidentRequest {
  final String title;
  final String description;
  final String category;
  final String priority;
  @JsonKey(name: 'site_id')
  final int? siteId;
  @JsonKey(name: 'location_id')
  final int? locationId;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'location_accuracy')
  final double? locationAccuracy;
  final String? notes;
  @JsonKey(name: 'evidence_files')
  final List<String>? evidenceFiles;

  const IncidentRequest({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    this.siteId,
    this.locationId,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.notes,
    this.evidenceFiles,
  });

  factory IncidentRequest.fromJson(Map<String, dynamic> json) => _$IncidentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$IncidentRequestToJson(this);

  @override
  String toString() => 'IncidentRequest(title: $title, category: $category, priority: $priority)';
}

/// Incident response model from API
@JsonSerializable()
class IncidentResponse {
  final bool success;
  final String message;
  final Incident? incident;
  @JsonKey(name: 'incident_id')
  final int? incidentId;

  const IncidentResponse({
    required this.success,
    required this.message,
    this.incident,
    this.incidentId,
  });

  factory IncidentResponse.fromJson(Map<String, dynamic> json) => _$IncidentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$IncidentResponseToJson(this);

  @override
  String toString() => 'IncidentResponse(success: $success, message: $message)';
}

/// Incident statistics model
@JsonSerializable()
class IncidentStats {
  @JsonKey(name: 'total_incidents')
  final int totalIncidents;
  @JsonKey(name: 'open_incidents')
  final int openIncidents;
  @JsonKey(name: 'in_progress_incidents')
  final int inProgressIncidents;
  @JsonKey(name: 'resolved_incidents')
  final int resolvedIncidents;
  @JsonKey(name: 'critical_incidents')
  final int criticalIncidents;
  @JsonKey(name: 'average_resolution_time')
  final double? averageResolutionTime;

  const IncidentStats({
    required this.totalIncidents,
    required this.openIncidents,
    required this.inProgressIncidents,
    required this.resolvedIncidents,
    required this.criticalIncidents,
    this.averageResolutionTime,
  });

  factory IncidentStats.fromJson(Map<String, dynamic> json) => _$IncidentStatsFromJson(json);
  Map<String, dynamic> toJson() => _$IncidentStatsToJson(this);

  /// Get resolution rate as percentage
  double get resolutionRate {
    if (totalIncidents == 0) return 0.0;
    return (resolvedIncidents / totalIncidents) * 100;
  }

  @override
  String toString() => 'IncidentStats(total: $totalIncidents, open: $openIncidents, resolved: $resolvedIncidents)';
}

/// Incident update model for status changes
@JsonSerializable()
class IncidentUpdate {
  final String? status;
  final String? notes;
  @JsonKey(name: 'assigned_to')
  final int? assignedTo;
  @JsonKey(name: 'resolution_notes')
  final String? resolutionNotes;

  const IncidentUpdate({
    this.status,
    this.notes,
    this.assignedTo,
    this.resolutionNotes,
  });

  factory IncidentUpdate.fromJson(Map<String, dynamic> json) => _$IncidentUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$IncidentUpdateToJson(this);

  @override
  String toString() => 'IncidentUpdate(status: $status, assignedTo: $assignedTo)';
}