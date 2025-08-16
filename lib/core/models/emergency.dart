import 'package:json_annotation/json_annotation.dart';

part 'emergency.g.dart';

/// Emergency alert model
@JsonSerializable()
class EmergencyAlert {
  final int id;
  @JsonKey(name: 'alert_type')
  final String alertType;
  final String severity;
  final String status;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'user_name')
  final String? userName;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'location_name')
  final String? locationName;
  final String? description;
  @JsonKey(name: 'triggered_at')
  final String triggeredAt;
  @JsonKey(name: 'acknowledged_at')
  final String? acknowledgedAt;
  @JsonKey(name: 'resolved_at')
  final String? resolvedAt;
  @JsonKey(name: 'acknowledged_by')
  final int? acknowledgedBy;
  @JsonKey(name: 'resolved_by')
  final int? resolvedBy;

  const EmergencyAlert({
    required this.id,
    required this.alertType,
    required this.severity,
    required this.status,
    required this.userId,
    this.userName,
    this.latitude,
    this.longitude,
    this.locationName,
    this.description,
    required this.triggeredAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.acknowledgedBy,
    this.resolvedBy,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) => 
      _$EmergencyAlertFromJson(json);
  Map<String, dynamic> toJson() => _$EmergencyAlertToJson(this);

  /// Check if alert is active
  bool get isActive => status.toLowerCase() == 'active';

  /// Check if alert is acknowledged
  bool get isAcknowledged => acknowledgedAt != null;

  /// Check if alert is resolved
  bool get isResolved => resolvedAt != null;

  /// Get severity color
  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFD32F2F); // Red
      case 'high':
        return const Color(0xFFFF5722); // Deep Orange
      case 'medium':
        return const Color(0xFFF57C00); // Orange
      case 'low':
        return const Color(0xFF1976D2); // Blue
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  @override
  String toString() {
    return 'EmergencyAlert(id: $id, type: $alertType, severity: $severity, status: $status)';
  }
}

/// Emergency alert request model
@JsonSerializable()
class EmergencyAlertRequest {
  @JsonKey(name: 'alert_type')
  final String alertType;
  final String severity;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'location_name')
  final String? locationName;
  final String? description;

  const EmergencyAlertRequest({
    required this.alertType,
    required this.severity,
    this.latitude,
    this.longitude,
    this.locationName,
    this.description,
  });

  factory EmergencyAlertRequest.fromJson(Map<String, dynamic> json) => 
      _$EmergencyAlertRequestFromJson(json);
  Map<String, dynamic> toJson() => _$EmergencyAlertRequestToJson(this);

  /// Create SOS alert request
  factory EmergencyAlertRequest.sos({
    double? latitude,
    double? longitude,
    String? locationName,
    String? description,
  }) {
    return EmergencyAlertRequest(
      alertType: 'sos',
      severity: 'critical',
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      description: description,
    );
  }

  /// Create panic alert request
  factory EmergencyAlertRequest.panic({
    double? latitude,
    double? longitude,
    String? locationName,
    String? description,
  }) {
    return EmergencyAlertRequest(
      alertType: 'panic',
      severity: 'high',
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      description: description,
    );
  }
}

/// Emergency alert response model
@JsonSerializable()
class EmergencyAlertResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'alert_id')
  final int alertId;
  final EmergencyAlert alert;

  const EmergencyAlertResponse({
    required this.success,
    required this.message,
    required this.alertId,
    required this.alert,
  });

  factory EmergencyAlertResponse.fromJson(Map<String, dynamic> json) => 
      _$EmergencyAlertResponseFromJson(json);
  Map<String, dynamic> toJson() => _$EmergencyAlertResponseToJson(this);

  @override
  String toString() {
    return 'EmergencyAlertResponse(success: $success, alertId: $alertId, message: $message)';
  }
}

/// GPS location model for emergency tracking
@JsonSerializable()
class EmergencyLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final String timestamp;
  @JsonKey(name: 'location_name')
  final String? locationName;

  const EmergencyLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    required this.timestamp,
    this.locationName,
  });

  factory EmergencyLocation.fromJson(Map<String, dynamic> json) => 
      _$EmergencyLocationFromJson(json);
  Map<String, dynamic> toJson() => _$EmergencyLocationToJson(this);

  @override
  String toString() {
    return 'EmergencyLocation(lat: $latitude, lng: $longitude, accuracy: $accuracy)';
  }
}

import 'package:flutter/material.dart';