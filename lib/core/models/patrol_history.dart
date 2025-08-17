import '../models/checkpoint.dart';

/// Patrol history entry model
class PatrolHistoryEntry {
  final int id;
  final int patrolId;
  final String patrolTitle;
  final String status;
  final int userId;
  final String? userName;
  final int? siteId;
  final String? siteName;
  final String? priority;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final Duration? duration;
  final int totalCheckpoints;
  final int checkpointsVisited;
  final double completionPercentage;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const PatrolHistoryEntry({
    required this.id,
    required this.patrolId,
    required this.patrolTitle,
    required this.status,
    required this.userId,
    this.userName,
    this.siteId,
    this.siteName,
    this.priority,
    required this.startDateTime,
    this.endDateTime,
    this.duration,
    required this.totalCheckpoints,
    required this.checkpointsVisited,
    required this.completionPercentage,
    this.notes,
    this.metadata,
  });

  /// Create from JSON
  factory PatrolHistoryEntry.fromJson(Map<String, dynamic> json) {
    final startTime = DateTime.parse(json['start_time'] as String);
    final endTime = json['end_time'] != null 
        ? DateTime.parse(json['end_time'] as String)
        : null;
    
    return PatrolHistoryEntry(
      id: json['id'] as int,
      patrolId: json['patrol_id'] as int,
      patrolTitle: json['patrol_title'] as String,
      status: json['status'] as String,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String?,
      siteId: json['site_id'] as int?,
      siteName: json['site_name'] as String?,
      priority: json['priority'] as String?,
      startDateTime: startTime,
      endDateTime: endTime,
      duration: endTime != null ? endTime.difference(startTime) : null,
      totalCheckpoints: json['total_checkpoints'] as int,
      checkpointsVisited: json['checkpoints_visited'] as int,
      completionPercentage: (json['completion_percentage'] as num).toDouble(),
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patrol_id': patrolId,
      'patrol_title': patrolTitle,
      'status': status,
      'user_id': userId,
      'user_name': userName,
      'site_id': siteId,
      'site_name': siteName,
      'priority': priority,
      'start_time': startDateTime.toIso8601String(),
      'end_time': endDateTime?.toIso8601String(),
      'total_checkpoints': totalCheckpoints,
      'checkpoints_visited': checkpointsVisited,
      'completion_percentage': completionPercentage,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Check if patrol is completed
  bool get isCompleted => status == 'completed';

  /// Check if patrol is in progress
  bool get isInProgress => status == 'in_progress';

  /// Check if patrol is cancelled
  bool get isCancelled => status == 'cancelled';

  /// Get formatted duration string
  String get formattedDuration {
    if (duration == null) {
      return 'N/A';
    }
    
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case 'completed':
        return 'green';
      case 'in_progress':
        return 'blue';
      case 'cancelled':
        return 'red';
      case 'pending':
        return 'orange';
      default:
        return 'grey';
    }
  }

  /// Copy with new values
  PatrolHistoryEntry copyWith({
    int? id,
    int? patrolId,
    String? patrolTitle,
    String? status,
    int? userId,
    String? userName,
    int? siteId,
    String? siteName,
    String? priority,
    DateTime? startDateTime,
    DateTime? endDateTime,
    Duration? duration,
    int? totalCheckpoints,
    int? checkpointsVisited,
    double? completionPercentage,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return PatrolHistoryEntry(
      id: id ?? this.id,
      patrolId: patrolId ?? this.patrolId,
      patrolTitle: patrolTitle ?? this.patrolTitle,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      priority: priority ?? this.priority,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      duration: duration ?? this.duration,
      totalCheckpoints: totalCheckpoints ?? this.totalCheckpoints,
      checkpointsVisited: checkpointsVisited ?? this.checkpointsVisited,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PatrolHistoryEntry &&
        other.id == id &&
        other.patrolId == patrolId &&
        other.status == status &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ 
           patrolId.hashCode ^ 
           status.hashCode ^ 
           userId.hashCode;
  }
}