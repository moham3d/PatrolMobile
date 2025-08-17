import '../models/checkpoint.dart';

/// Patrol model representing patrol tasks and assignments
class Patrol {
  final int id;
  final String title;
  final String? description;
  final int? assignedTo;
  final String? assignedUserName;
  final int? createdBy;
  final String? createdByName;
  final String? dueDate;
  final String status; // 'pending', 'in_progress', 'completed', 'cancelled'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String taskType; // 'patrol'
  final int? siteId;
  final String? siteName;
  final int? estimatedDuration; // in minutes
  final String? startTime;
  final String? endTime;
  final double completionPercentage;
  final bool isRecurring;
  final String? recurrencePattern;
  final String? nextDueDate;
  final List<Checkpoint>? checkpoints;
  final String createdAt;
  final String updatedAt;

  const Patrol({
    required this.id,
    required this.title,
    this.description,
    this.assignedTo,
    this.assignedUserName,
    this.createdBy,
    this.createdByName,
    this.dueDate,
    required this.status,
    required this.priority,
    required this.taskType,
    this.siteId,
    this.siteName,
    this.estimatedDuration,
    this.startTime,
    this.endTime,
    required this.completionPercentage,
    required this.isRecurring,
    this.recurrencePattern,
    this.nextDueDate,
    this.checkpoints,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Patrol.fromJson(Map<String, dynamic> json) {
    return Patrol(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      assignedTo: json['assigned_to'] as int?,
      assignedUserName: json['assigned_user_name'] as String?,
      createdBy: json['created_by'] as int?,
      createdByName: json['created_by_name'] as String?,
      dueDate: json['due_date'] as String?,
      status: json['status'] as String,
      priority: json['priority'] as String,
      taskType: json['task_type'] as String? ?? 'patrol',
      siteId: json['site_id'] as int?,
      siteName: json['site_name'] as String?,
      estimatedDuration: json['estimated_duration'] as int?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrencePattern: json['recurrence_pattern'] as String?,
      nextDueDate: json['next_due_date'] as String?,
      checkpoints: (json['checkpoints'] as List<dynamic>?)
          ?.map((c) => Checkpoint.fromJson(c as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assigned_to': assignedTo,
      'assigned_user_name': assignedUserName,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'due_date': dueDate,
      'status': status,
      'priority': priority,
      'task_type': taskType,
      'site_id': siteId,
      'site_name': siteName,
      'estimated_duration': estimatedDuration,
      'start_time': startTime,
      'end_time': endTime,
      'completion_percentage': completionPercentage,
      'is_recurring': isRecurring,
      'recurrence_pattern': recurrencePattern,
      'next_due_date': nextDueDate,
      'checkpoints': checkpoints?.map((c) => c.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Check if patrol is assigned to current user
  bool isAssignedTo(int userId) => assignedTo == userId;

  /// Check if patrol is active (in progress)
  bool get isActive => status == 'in_progress';

  /// Check if patrol is completed
  bool get isCompleted => status == 'completed';

  /// Check if patrol is pending
  bool get isPending => status == 'pending';

  /// Get priority level as integer (higher = more urgent)
  int get priorityLevel {
    switch (priority) {
      case 'urgent': return 4;
      case 'high': return 3;
      case 'medium': return 2;
      case 'low': return 1;
      default: return 1;
    }
  }

  /// Get estimated duration as Duration object
  Duration? get estimatedDurationObject {
    if (estimatedDuration == null) return null;
    return Duration(minutes: estimatedDuration!);
  }

  /// Get start time as DateTime
  DateTime? get startDateTime {
    if (startTime == null) return null;
    return DateTime.tryParse(startTime!);
  }

  /// Get end time as DateTime
  DateTime? get endDateTime {
    if (endTime == null) return null;
    return DateTime.tryParse(endTime!);
  }

  /// Get due date as DateTime
  DateTime? get dueDateObject {
    if (dueDate == null) return null;
    return DateTime.tryParse(dueDate!);
  }

  /// Get number of checkpoints
  int get checkpointCount => checkpoints?.length ?? 0;

  /// Get number of visited checkpoints (would need visit data)
  int get visitedCheckpointCount {
    // This would typically come from a separate API call or be included in the response
    return (completionPercentage * checkpointCount / 100).round();
  }

  /// Check if patrol is overdue
  bool get isOverdue {
    final due = dueDateObject;
    if (due == null) return false;
    return DateTime.now().isAfter(due) && !isCompleted;
  }

  /// Check if patrol has location data (any checkpoint with coordinates)
  bool get hasLocationData {
    return checkpoints?.any((c) => c.hasLocation) ?? false;
  }

  @override
  String toString() {
    return 'Patrol(id: $id, title: $title, status: $status, completion: ${completionPercentage.toStringAsFixed(1)}%)';
  }
}

/// Patrol progress model for tracking checkpoint visits
class PatrolProgress {
  final int patrolId;
  final int totalCheckpoints;
  final int visitedCheckpoints;
  final double completionPercentage;
  final String? startTime;
  final Checkpoint? currentCheckpoint;
  final Checkpoint? nextCheckpoint;
  final List<CheckpointVisit>? recentVisits;
  final String? estimatedCompletionTime;

  const PatrolProgress({
    required this.patrolId,
    required this.totalCheckpoints,
    required this.visitedCheckpoints,
    required this.completionPercentage,
    this.startTime,
    this.currentCheckpoint,
    this.nextCheckpoint,
    this.recentVisits,
    this.estimatedCompletionTime,
  });

  factory PatrolProgress.fromJson(Map<String, dynamic> json) {
    return PatrolProgress(
      patrolId: json['patrol_id'] as int,
      totalCheckpoints: json['total_checkpoints'] as int? ?? 0,
      visitedCheckpoints: json['visited_checkpoints'] as int? ?? 0,
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      startTime: json['start_time'] as String?,
      currentCheckpoint: json['current_checkpoint'] != null
          ? Checkpoint.fromJson(json['current_checkpoint'] as Map<String, dynamic>)
          : null,
      nextCheckpoint: json['next_checkpoint'] != null
          ? Checkpoint.fromJson(json['next_checkpoint'] as Map<String, dynamic>)
          : null,
      recentVisits: (json['recent_visits'] as List<dynamic>?)
          ?.map((v) => CheckpointVisit.fromJson(v as Map<String, dynamic>))
          .toList(),
      estimatedCompletionTime: json['estimated_completion_time'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patrol_id': patrolId,
      'total_checkpoints': totalCheckpoints,
      'visited_checkpoints': visitedCheckpoints,
      'completion_percentage': completionPercentage,
      'start_time': startTime,
      'current_checkpoint': currentCheckpoint?.toJson(),
      'next_checkpoint': nextCheckpoint?.toJson(),
      'recent_visits': recentVisits?.map((v) => v.toJson()).toList(),
      'estimated_completion_time': estimatedCompletionTime,
    };
  }

  /// Check if patrol is started
  bool get isStarted => startTime != null;

  /// Check if patrol is completed
  bool get isCompleted => completionPercentage >= 100.0;

  /// Get remaining checkpoints count
  int get remainingCheckpoints => totalCheckpoints - visitedCheckpoints;

  /// Get start time as DateTime
  DateTime? get startDateTime {
    if (startTime == null) return null;
    return DateTime.tryParse(startTime!);
  }

  /// Get estimated completion time as DateTime
  DateTime? get estimatedCompletionDateTime {
    if (estimatedCompletionTime == null) return null;
    return DateTime.tryParse(estimatedCompletionTime!);
  }

  @override
  String toString() {
    return 'PatrolProgress(patrol: $patrolId, progress: $visitedCheckpoints/$totalCheckpoints, ${completionPercentage.toStringAsFixed(1)}%)';
  }
}

/// Patrol route model for displaying route information
class PatrolRoute {
  final int patrolId;
  final String name;
  final String? description;
  final List<Checkpoint> checkpoints;
  final double? totalDistance; // in meters
  final int? estimatedDuration; // in minutes
  final List<int>? optimizedSequence; // checkpoint IDs in optimal order

  const PatrolRoute({
    required this.patrolId,
    required this.name,
    this.description,
    required this.checkpoints,
    this.totalDistance,
    this.estimatedDuration,
    this.optimizedSequence,
  });

  factory PatrolRoute.fromJson(Map<String, dynamic> json) {
    return PatrolRoute(
      patrolId: json['patrol_id'] as int,
      name: json['name'] as String? ?? 'Patrol Route',
      description: json['description'] as String?,
      checkpoints: (json['checkpoints'] as List<dynamic>?)
          ?.map((c) => Checkpoint.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      totalDistance: (json['total_distance'] as num?)?.toDouble(),
      estimatedDuration: json['estimated_duration'] as int?,
      optimizedSequence: (json['optimized_sequence'] as List<dynamic>?)
          ?.map((id) => id as int)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patrol_id': patrolId,
      'name': name,
      'description': description,
      'checkpoints': checkpoints.map((c) => c.toJson()).toList(),
      'total_distance': totalDistance,
      'estimated_duration': estimatedDuration,
      'optimized_sequence': optimizedSequence,
    };
  }

  /// Get checkpoints in optimized order
  List<Checkpoint> get optimizedCheckpoints {
    if (optimizedSequence == null || optimizedSequence!.isEmpty) {
      return checkpoints;
    }

    final Map<int, Checkpoint> checkpointMap = {
      for (var checkpoint in checkpoints) checkpoint.id: checkpoint
    };

    return optimizedSequence!
        .map((id) => checkpointMap[id])
        .whereType<Checkpoint>()
        .toList();
  }

  /// Get total distance as formatted string
  String get formattedDistance {
    if (totalDistance == null) return 'Unknown';
    if (totalDistance! >= 1000) {
      return '${(totalDistance! / 1000).toStringAsFixed(1)} km';
    }
    return '${totalDistance!.toStringAsFixed(0)} m';
  }

  /// Get estimated duration as Duration object
  Duration? get estimatedDurationObject {
    if (estimatedDuration == null) return null;
    return Duration(minutes: estimatedDuration!);
  }

  /// Get formatted estimated duration
  String get formattedDuration {
    final duration = estimatedDurationObject;
    if (duration == null) return 'Unknown';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  String toString() {
    return 'PatrolRoute(patrol: $patrolId, name: $name, checkpoints: ${checkpoints.length})';
  }
}

/// Simple patrol action request for API calls
class PatrolActionRequest {
  final String action; // 'start', 'end', 'pause', 'resume'
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;
  final String? notes;
  final String deviceTimestamp;

  const PatrolActionRequest({
    required this.action,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.notes,
    required this.deviceTimestamp,
  });

  factory PatrolActionRequest.fromJson(Map<String, dynamic> json) {
    return PatrolActionRequest(
      action: json['action'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAccuracy: (json['location_accuracy'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      deviceTimestamp: json['device_timestamp'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'latitude': latitude,
      'longitude': longitude,
      'location_accuracy': locationAccuracy,
      'notes': notes,
      'device_timestamp': deviceTimestamp,
    };
  }

  /// Create start patrol request
  factory PatrolActionRequest.start({
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) {
    return PatrolActionRequest(
      action: 'start',
      latitude: latitude,
      longitude: longitude,
      locationAccuracy: accuracy,
      notes: notes,
      deviceTimestamp: DateTime.now().toIso8601String(),
    );
  }

  /// Create end patrol request
  factory PatrolActionRequest.end({
    double? latitude,
    double? longitude,
    double? accuracy,
    String? notes,
  }) {
    return PatrolActionRequest(
      action: 'end',
      latitude: latitude,
      longitude: longitude,
      locationAccuracy: accuracy,
      notes: notes,
      deviceTimestamp: DateTime.now().toIso8601String(),
    );
  }
}

/// Patrol action response
class PatrolActionResponse {
  final bool success;
  final String message;
  final int? patrolId;
  final String? status;
  final String? actionTime;

  const PatrolActionResponse({
    required this.success,
    required this.message,
    this.patrolId,
    this.status,
    this.actionTime,
  });

  factory PatrolActionResponse.fromJson(Map<String, dynamic> json) {
    return PatrolActionResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      patrolId: json['patrol_id'] as int?,
      status: json['status'] as String?,
      actionTime: json['action_time'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'patrol_id': patrolId,
      'status': status,
      'action_time': actionTime,
    };
  }

  @override
  String toString() {
    return 'PatrolActionResponse(success: $success, patrolId: $patrolId, status: $status)';
  }
}

/// Patrol history entry
class PatrolHistoryEntry {
  final int id;
  final int patrolId;
  final String patrolTitle;
  final int completedBy;
  final String? completedByName;
  final String startTime;
  final String? endTime;
  final int? totalDuration; // in minutes
  final int checkpointsVisited;
  final int totalCheckpoints;
  final double completionPercentage;
  final String status;
  final String? notes;
  final String createdAt;

  const PatrolHistoryEntry({
    required this.id,
    required this.patrolId,
    required this.patrolTitle,
    required this.completedBy,
    this.completedByName,
    required this.startTime,
    this.endTime,
    this.totalDuration,
    required this.checkpointsVisited,
    required this.totalCheckpoints,
    required this.completionPercentage,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory PatrolHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PatrolHistoryEntry(
      id: json['id'] as int,
      patrolId: json['patrol_id'] as int,
      patrolTitle: json['patrol_title'] as String? ?? 'Patrol',
      completedBy: json['completed_by'] as int,
      completedByName: json['completed_by_name'] as String?,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String?,
      totalDuration: json['total_duration'] as int?,
      checkpointsVisited: json['checkpoints_visited'] as int? ?? 0,
      totalCheckpoints: json['total_checkpoints'] as int? ?? 0,
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patrol_id': patrolId,
      'patrol_title': patrolTitle,
      'completed_by': completedBy,
      'completed_by_name': completedByName,
      'start_time': startTime,
      'end_time': endTime,
      'total_duration': totalDuration,
      'checkpoints_visited': checkpointsVisited,
      'total_checkpoints': totalCheckpoints,
      'completion_percentage': completionPercentage,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  /// Get start time as DateTime
  DateTime get startDateTime => DateTime.parse(startTime);

  /// Get end time as DateTime
  DateTime? get endDateTime {
    if (endTime == null) return null;
    return DateTime.tryParse(endTime!);
  }

  /// Get total duration as Duration object
  Duration? get totalDurationObject {
    if (totalDuration == null) return null;
    return Duration(minutes: totalDuration!);
  }

  /// Get formatted duration
  String get formattedDuration {
    final duration = totalDurationObject;
    if (duration == null) return 'In progress';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Check if patrol is completed
  bool get isCompleted => status == 'completed' && endTime != null;

  /// Check if patrol is in progress
  bool get isInProgress => status == 'in_progress' && endTime == null;

  @override
  String toString() {
    return 'PatrolHistoryEntry(id: $id, title: $patrolTitle, status: $status, completion: ${completionPercentage.toStringAsFixed(1)}%)';
  }
}