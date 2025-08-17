/// Models for synchronization operations and results

/// Sync priority levels
enum SyncPriority {
  low(1),
  normal(2),
  high(3),
  critical(4);

  const SyncPriority(this.value);
  final int value;
  
  /// Compare priorities
  int compareTo(SyncPriority other) => value.compareTo(other.value);
  
  /// Check if this priority is greater than or equal to another
  bool operator >=(SyncPriority other) => value >= other.value;
  
  /// Check if this priority is greater than another
  bool operator >(SyncPriority other) => value > other.value;
  
  /// Check if this priority is less than or equal to another
  bool operator <=(SyncPriority other) => value <= other.value;
  
  /// Check if this priority is less than another
  bool operator <(SyncPriority other) => value < other.value;
}

/// Sync operation model
class SyncOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final SyncPriority priority;
  final int maxRetries;
  int retryCount;
  final DateTime createdAt;

  SyncOperation({
    required this.id,
    required this.type,
    required this.data,
    this.priority = SyncPriority.normal,
    this.maxRetries = 3,
    this.retryCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Sync result model
class SyncResult {
  final SyncOperation operation;
  final bool success;
  final String? error;
  final DateTime? syncedAt;

  const SyncResult({
    required this.operation,
    required this.success,
    this.error,
    this.syncedAt,
  });
}