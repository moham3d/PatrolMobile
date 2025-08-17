import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/checkpoint.dart';
import '../models/patrol_simple.dart';
import '../constants/app_constants.dart';

/// Local SQLite database service for offline data storage
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._internal();
  
  DatabaseService._internal();

  Database? _database;
  
  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'patrol_shield.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Offline checkpoint visits table
    await db.execute('''
      CREATE TABLE offline_checkpoint_visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        checkpoint_id INTEGER NOT NULL,
        checkpoint_code TEXT NOT NULL,
        patrol_id INTEGER,
        user_id INTEGER NOT NULL,
        latitude REAL,
        longitude REAL,
        location_accuracy REAL,
        scan_method TEXT NOT NULL,
        notes TEXT,
        device_timestamp TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        sync_attempts INTEGER DEFAULT 0,
        sync_last_attempt TEXT,
        sync_error TEXT,
        created_at TEXT NOT NULL,
        UNIQUE(checkpoint_id, patrol_id, device_timestamp)
      )
    ''');

    // Offline patrol actions table
    await db.execute('''
      CREATE TABLE offline_patrol_actions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patrol_id INTEGER NOT NULL,
        action_type TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        latitude REAL,
        longitude REAL,
        location_accuracy REAL,
        notes TEXT,
        reason TEXT,
        device_timestamp TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        sync_attempts INTEGER DEFAULT 0,
        sync_last_attempt TEXT,
        sync_error TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Cached checkpoints table for offline validation
    await db.execute('''
      CREATE TABLE cached_checkpoints (
        id INTEGER PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        description TEXT,
        latitude REAL,
        longitude REAL,
        is_active INTEGER DEFAULT 1,
        site_id INTEGER,
        patrol_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        cache_timestamp TEXT NOT NULL
      )
    ''');

    // Cached patrols table for offline reference
    await db.execute('''
      CREATE TABLE cached_patrols (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        assigned_to INTEGER,
        status TEXT NOT NULL,
        priority TEXT NOT NULL,
        site_id INTEGER,
        estimated_duration INTEGER,
        completion_percentage REAL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        cache_timestamp TEXT NOT NULL
      )
    ''');

    // Sync log table
    await db.execute('''
      CREATE TABLE sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        sync_timestamp TEXT NOT NULL,
        error_message TEXT,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_checkpoint_visits_sync ON offline_checkpoint_visits(sync_status)');
    await db.execute('CREATE INDEX idx_patrol_actions_sync ON offline_patrol_actions(sync_status)');
    await db.execute('CREATE INDEX idx_checkpoint_code ON cached_checkpoints(code)');
    await db.execute('CREATE INDEX idx_patrol_assigned ON cached_patrols(assigned_to)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations
    if (oldVersion < newVersion) {
      // Add migration logic here when needed
    }
  }

  /// Store offline checkpoint visit
  Future<int> storeOfflineCheckpointVisit({
    required int checkpointId,
    required String checkpointCode,
    int? patrolId,
    required int userId,
    double? latitude,
    double? longitude,
    double? locationAccuracy,
    required String scanMethod,
    String? notes,
    required String deviceTimestamp,
  }) async {
    final db = await database;
    
    final visit = {
      'checkpoint_id': checkpointId,
      'checkpoint_code': checkpointCode,
      'patrol_id': patrolId,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'location_accuracy': locationAccuracy,
      'scan_method': scanMethod,
      'notes': notes,
      'device_timestamp': deviceTimestamp,
      'created_at': DateTime.now().toIso8601String(),
    };

    return await db.insert(
      'offline_checkpoint_visits',
      visit,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Store offline patrol action
  Future<int> storeOfflinePatrolAction({
    required int patrolId,
    required String actionType,
    required int userId,
    double? latitude,
    double? longitude,
    double? locationAccuracy,
    String? notes,
    String? reason,
    required String deviceTimestamp,
  }) async {
    final db = await database;
    
    final action = {
      'patrol_id': patrolId,
      'action_type': actionType,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'location_accuracy': locationAccuracy,
      'notes': notes,
      'reason': reason,
      'device_timestamp': deviceTimestamp,
      'created_at': DateTime.now().toIso8601String(),
    };

    return await db.insert('offline_patrol_actions', action);
  }

  /// Cache checkpoint for offline validation
  Future<int> cacheCheckpoint(Checkpoint checkpoint) async {
    final db = await database;
    
    final cachedCheckpoint = {
      'id': checkpoint.id,
      'code': checkpoint.code,
      'name': checkpoint.name,
      'description': checkpoint.description,
      'latitude': checkpoint.latitude,
      'longitude': checkpoint.longitude,
      'is_active': checkpoint.isActive ? 1 : 0,
      'site_id': checkpoint.siteId,
      'patrol_id': checkpoint.patrolId,
      'created_at': checkpoint.createdAt,
      'updated_at': checkpoint.updatedAt,
      'cache_timestamp': DateTime.now().toIso8601String(),
    };

    return await db.insert(
      'cached_checkpoints',
      cachedCheckpoint,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Cache patrol for offline reference
  Future<int> cachePatrol(Patrol patrol) async {
    final db = await database;
    
    final cachedPatrol = {
      'id': patrol.id,
      'title': patrol.title,
      'description': patrol.description,
      'assigned_to': patrol.assignedTo,
      'status': patrol.status,
      'priority': patrol.priority,
      'site_id': patrol.siteId,
      'estimated_duration': patrol.estimatedDuration,
      'completion_percentage': patrol.completionPercentage,
      'created_at': patrol.createdAt,
      'updated_at': patrol.updatedAt,
      'cache_timestamp': DateTime.now().toIso8601String(),
    };

    return await db.insert(
      'cached_patrols',
      cachedPatrol,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get cached checkpoint by code
  Future<Checkpoint?> getCachedCheckpointByCode(String code) async {
    final db = await database;
    
    final results = await db.query(
      'cached_checkpoints',
      where: 'code = ? AND is_active = 1',
      whereArgs: [code],
    );

    if (results.isEmpty) return null;
    
    final data = results.first;
    return Checkpoint(
      id: data['id'] as int,
      code: data['code'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      latitude: data['latitude'] as double?,
      longitude: data['longitude'] as double?,
      isActive: (data['is_active'] as int) == 1,
      siteId: data['site_id'] as int?,
      patrolId: data['patrol_id'] as int?,
      createdAt: data['created_at'] as String,
      updatedAt: data['updated_at'] as String,
    );
  }

  /// Get cached patrol by ID
  Future<Patrol?> getCachedPatrol(int patrolId) async {
    final db = await database;
    
    final results = await db.query(
      'cached_patrols',
      where: 'id = ?',
      whereArgs: [patrolId],
    );

    if (results.isEmpty) return null;
    
    final data = results.first;
    return Patrol(
      id: data['id'] as int,
      title: data['title'] as String,
      description: data['description'] as String?,
      assignedTo: data['assigned_to'] as int?,
      status: data['status'] as String,
      priority: data['priority'] as String,
      taskType: 'patrol',
      siteId: data['site_id'] as int?,
      estimatedDuration: data['estimated_duration'] as int?,
      completionPercentage: (data['completion_percentage'] as num).toDouble(),
      isRecurring: false,
      createdAt: data['created_at'] as String,
      updatedAt: data['updated_at'] as String,
    );
  }

  /// Get all pending sync items
  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    
    final visits = await db.query(
      'offline_checkpoint_visits',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );

    final actions = await db.query(
      'offline_patrol_actions',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );

    return [
      ...visits.map((v) => {'type': 'checkpoint_visit', 'data': v}),
      ...actions.map((a) => {'type': 'patrol_action', 'data': a}),
    ];
  }

  /// Mark item as synced
  Future<void> markItemSynced(String tableName, int id) async {
    final db = await database;
    
    await db.update(
      tableName,
      {
        'sync_status': 'synced',
        'sync_last_attempt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark item sync failed
  Future<void> markItemSyncFailed(String tableName, int id, String error) async {
    final db = await database;
    
    await db.update(
      tableName,
      {
        'sync_status': 'failed',
        'sync_attempts': 'sync_attempts + 1',
        'sync_last_attempt': DateTime.now().toIso8601String(),
        'sync_error': error,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get sync statistics
  Future<Map<String, int>> getSyncStatistics() async {
    final db = await database;
    
    final pendingVisits = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_checkpoint_visits WHERE sync_status = ?',
      ['pending'],
    );
    
    final pendingActions = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_patrol_actions WHERE sync_status = ?',
      ['pending'],
    );
    
    final failedVisits = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_checkpoint_visits WHERE sync_status = ?',
      ['failed'],
    );
    
    final failedActions = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_patrol_actions WHERE sync_status = ?',
      ['failed'],
    );

    return {
      'pending_visits': pendingVisits.first['count'] as int,
      'pending_actions': pendingActions.first['count'] as int,
      'failed_visits': failedVisits.first['count'] as int,
      'failed_actions': failedActions.first['count'] as int,
    };
  }

  /// Clean old cache data
  Future<void> cleanOldCache({Duration maxAge = const Duration(days: 7)}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(maxAge).toIso8601String();
    
    await db.delete(
      'cached_checkpoints',
      where: 'cache_timestamp < ?',
      whereArgs: [cutoffDate],
    );
    
    await db.delete(
      'cached_patrols',
      where: 'cache_timestamp < ?',
      whereArgs: [cutoffDate],
    );
  }

  /// Clear all synced items older than specified duration
  Future<void> clearSyncedItems({Duration maxAge = const Duration(days: 30)}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(maxAge).toIso8601String();
    
    await db.delete(
      'offline_checkpoint_visits',
      where: 'sync_status = ? AND sync_last_attempt < ?',
      whereArgs: ['synced', cutoffDate],
    );
    
    await db.delete(
      'offline_patrol_actions',
      where: 'sync_status = ? AND sync_last_attempt < ?',
      whereArgs: ['synced', cutoffDate],
    );
  }

  /// Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}