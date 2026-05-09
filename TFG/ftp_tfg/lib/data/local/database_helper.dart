import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:universal_io/io.dart';

import '../../domain/entities/dump_schedule.dart';
import '../../domain/entities/file_version.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/local_file.dart';
import '../../domain/entities/system_alert.dart';
import '../../domain/entities/system_event.dart';
import '../../domain/entities/system_health_summary.dart';
import '../../domain/entities/sync_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  final List<Map<String, dynamic>> _webProfiles = [];
  final List<Map<String, dynamic>> _webHistory = [];
  final List<Map<String, dynamic>> _webSchedules = [];
  final List<Map<String, dynamic>> _webEvents = [];
  final List<Map<String, dynamic>> _webAlerts = [];
  final List<Map<String, dynamic>> _webVersions = [];
  int _webIdCounter = 1;

  DatabaseHelper._internal();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDb();
    return _db;
  }

  Future<Database> _initDb() async {
    String path;
    try {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'hotftp.db');
    } catch (_) {
      path = inMemoryDatabasePath;
    }

    return openDatabase(
      path,
      version: 6,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ftp_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ownerId TEXT NOT NULL,
        name TEXT NOT NULL,
        host TEXT NOT NULL,
        port INTEGER NOT NULL DEFAULT 21,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        useFTPS INTEGER NOT NULL DEFAULT 0,
        passiveMode INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ownerId TEXT NOT NULL,
        profileId INTEGER NOT NULL,
        date TEXT NOT NULL,
        localPath TEXT NOT NULL,
        remotePath TEXT NOT NULL,
        mode TEXT NOT NULL,
        filesTransferred INTEGER NOT NULL DEFAULT 0,
        filesSkipped INTEGER NOT NULL DEFAULT 0,
        errorMessage TEXT,
        FOREIGN KEY (profileId) REFERENCES ftp_profiles(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE dump_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ownerId TEXT NOT NULL,
        profileId INTEGER NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        localPath TEXT NOT NULL,
        remotePath TEXT NOT NULL,
        sourceSide TEXT NOT NULL,
        transferMode TEXT NOT NULL,
        deleteSourceAfterCopy INTEGER NOT NULL DEFAULT 0,
        intervalValue INTEGER NOT NULL DEFAULT 24,
        intervalUnit TEXT NOT NULL DEFAULT 'hours',
        lastRunAt TEXT,
        nextRunAt TEXT,
        FOREIGN KEY (profileId) REFERENCES ftp_profiles(id),
        UNIQUE(ownerId, profileId)
      )
    ''');
    await db.execute('''
      CREATE TABLE system_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ownerId TEXT NOT NULL,
        eventType TEXT NOT NULL,
        severity TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        relatedProfileId INTEGER,
        metadata TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE system_alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ownerId TEXT NOT NULL,
        source TEXT NOT NULL,
        severity TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        relatedProfileId INTEGER,
        isRead INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        resolvedAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE file_versions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ownerId TEXT NOT NULL,
        profileId INTEGER NOT NULL,
        filePath TEXT NOT NULL,
        fileName TEXT NOT NULL,
        versionNumber INTEGER NOT NULL,
        size INTEGER NOT NULL,
        modifiedAt TEXT,
        source TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        UNIQUE(ownerId, profileId, filePath, versionNumber)
      )
    ''');
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          displayName TEXT NOT NULL,
          passwordHash TEXT NOT NULL,
          salt TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      await _ensureColumn(db, 'ftp_profiles', 'ownerId', 'TEXT');
      await _ensureColumn(db, 'sync_records', 'ownerId', 'TEXT');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS dump_schedules (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ownerId TEXT NOT NULL,
          profileId INTEGER NOT NULL,
          enabled INTEGER NOT NULL DEFAULT 1,
          localPath TEXT NOT NULL,
          remotePath TEXT NOT NULL,
          sourceSide TEXT NOT NULL,
          transferMode TEXT NOT NULL,
          deleteSourceAfterCopy INTEGER NOT NULL DEFAULT 0,
          intervalValue INTEGER NOT NULL DEFAULT 24,
          intervalUnit TEXT NOT NULL DEFAULT 'hours',
          lastRunAt TEXT,
          nextRunAt TEXT,
          FOREIGN KEY (profileId) REFERENCES ftp_profiles(id),
          UNIQUE(ownerId, profileId)
        )
      ''');
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS system_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ownerId TEXT NOT NULL,
          eventType TEXT NOT NULL,
          severity TEXT NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          relatedProfileId INTEGER,
          metadata TEXT,
          createdAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS system_alerts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ownerId TEXT NOT NULL,
          source TEXT NOT NULL,
          severity TEXT NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          relatedProfileId INTEGER,
          isRead INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL,
          resolvedAt TEXT
        )
      ''');
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS file_versions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ownerId TEXT NOT NULL,
          profileId INTEGER NOT NULL,
          filePath TEXT NOT NULL,
          fileName TEXT NOT NULL,
          versionNumber INTEGER NOT NULL,
          size INTEGER NOT NULL,
          modifiedAt TEXT,
          source TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          UNIQUE(ownerId, profileId, filePath, versionNumber)
        )
      ''');
    }
  }

  Future<void> _ensureColumn(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((columnInfo) => columnInfo['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  // ---- Profiles ----
  Future<List<FtpProfile>> getProfiles(String ownerId) async {
    if (kIsWeb) {
      return _webProfiles
          .where((profile) => profile['ownerId'] == ownerId)
          .map(FtpProfile.fromMap)
          .toList();
    }
    final db = await database;
    final maps = await db!.query(
      'ftp_profiles',
      where: 'ownerId = ?',
      whereArgs: [ownerId],
      orderBy: 'name ASC',
    );
    return maps.map(FtpProfile.fromMap).toList();
  }

  Future<int> insertProfile(FtpProfile profile, String ownerId) async {
    final map = profile.toMap()..['ownerId'] = ownerId;
    if (kIsWeb) {
      map['id'] = _webIdCounter++;
      _webProfiles.add(map);
      return map['id'] as int;
    }
    final db = await database;
    return db!.insert('ftp_profiles', map..remove('id'));
  }

  Future<int> updateProfile(FtpProfile profile, String ownerId) async {
    final map = profile.toMap()..['ownerId'] = ownerId;
    if (kIsWeb) {
      final index = _webProfiles.indexWhere((p) => p['id'] == profile.id);
      if (index != -1) {
        _webProfiles[index] = map;
      }
      return profile.id ?? 0;
    }
    final db = await database;
    return db!.update(
      'ftp_profiles',
      map,
      where: 'id = ? AND ownerId = ?',
      whereArgs: [profile.id, ownerId],
    );
  }

  Future<void> deleteProfile(int id, String ownerId) async {
    if (kIsWeb) {
      _webProfiles.removeWhere(
        (profile) => profile['id'] == id && profile['ownerId'] == ownerId,
      );
      return;
    }
    final db = await database;
    await db!.delete(
      'ftp_profiles',
      where: 'id = ? AND ownerId = ?',
      whereArgs: [id, ownerId],
    );
  }

  // ---- Sync Records ----
  Future<List<SyncRecord>> getSyncHistory(String ownerId) async {
    return getRecentSyncs(ownerId, limit: 100);
  }

  Future<List<SyncRecord>> getRecentSyncs(
    String ownerId, {
    int limit = 20,
  }) async {
    if (kIsWeb) {
      return _webHistory
          .where((record) => record['ownerId'] == ownerId)
          .take(limit)
          .map(SyncRecord.fromMap)
          .toList();
    }
    final db = await database;
    final maps = await db!.query(
      'sync_records',
      where: 'ownerId = ?',
      whereArgs: [ownerId],
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map(SyncRecord.fromMap).toList();
  }

  Future<void> insertSyncRecord(SyncRecord record) async {
    final map = record.toMap();
    if (kIsWeb) {
      map['id'] = _webIdCounter++;
      _webHistory.insert(0, map);
      return;
    }
    final db = await database;
    await db!.insert('sync_records', map..remove('id'));
  }

  // ---- Monitoring ----
  Future<void> insertSystemEvent(SystemEvent event) async {
    final map = event.toMap();
    if (kIsWeb) {
      map['id'] = _webIdCounter++;
      _webEvents.insert(0, map);
      return;
    }
    final db = await database;
    await db!.insert('system_events', map..remove('id'));
  }

  Future<int> insertSystemAlert(SystemAlert alert) async {
    final map = alert.toMap();
    if (kIsWeb) {
      map['id'] = _webIdCounter++;
      _webAlerts.insert(0, map);
      return map['id'] as int;
    }
    final db = await database;
    return db!.insert('system_alerts', map..remove('id'));
  }

  Future<int> insertFileVersion(FileVersion version) async {
    final map = version.toMap();
    if (kIsWeb) {
      map['id'] = _webIdCounter++;
      _webVersions.insert(0, map);
      return map['id'] as int;
    }
    final db = await database;
    return db!.insert('file_versions', map..remove('id'));
  }

  Future<List<SystemEvent>> getRecentEvents(
    String ownerId, {
    int limit = 20,
  }) async {
    if (kIsWeb) {
      return _webEvents
          .where((event) => event['ownerId'] == ownerId)
          .take(limit)
          .map(SystemEvent.fromMap)
          .toList();
    }
    final db = await database;
    final maps = await db!.query(
      'system_events',
      where: 'ownerId = ?',
      whereArgs: [ownerId],
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return maps.map(SystemEvent.fromMap).toList();
  }

  Future<List<SystemAlert>> getActiveAlerts(
    String ownerId, {
    int limit = 10,
  }) async {
    if (kIsWeb) {
      return _webAlerts
          .where(
            (alert) =>
                alert['ownerId'] == ownerId && alert['resolvedAt'] == null,
          )
          .take(limit)
          .map(SystemAlert.fromMap)
          .toList();
    }
    final db = await database;
    final maps = await db!.query(
      'system_alerts',
      where: 'ownerId = ? AND resolvedAt IS NULL',
      whereArgs: [ownerId],
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return maps.map(SystemAlert.fromMap).toList();
  }

  Future<List<FileVersion>> getRecentFileVersions(
    String ownerId, {
    int limit = 12,
  }) async {
    if (kIsWeb) {
      return _webVersions
          .where((version) => version['ownerId'] == ownerId)
          .take(limit)
          .map(FileVersion.fromMap)
          .toList();
    }
    final db = await database;
    final maps = await db!.query(
      'file_versions',
      where: 'ownerId = ?',
      whereArgs: [ownerId],
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return maps.map(FileVersion.fromMap).toList();
  }

  Future<FileVersion?> getLatestFileVersion(
    String ownerId,
    int profileId,
    String filePath,
  ) async {
    if (kIsWeb) {
      for (final version in _webVersions) {
        if (version['ownerId'] == ownerId &&
            version['profileId'] == profileId &&
            version['filePath'] == filePath) {
          return FileVersion.fromMap(version);
        }
      }
      return null;
    }
    final db = await database;
    final maps = await db!.query(
      'file_versions',
      where: 'ownerId = ? AND profileId = ? AND filePath = ?',
      whereArgs: [ownerId, profileId, filePath],
      orderBy: 'versionNumber DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return FileVersion.fromMap(maps.first);
  }

  Future<List<FileVersion>> getFileVersionHistory(
    String ownerId,
    int profileId,
    String filePath, {
    int limit = 20,
  }) async {
    if (kIsWeb) {
      return _webVersions
          .where((version) =>
              version['ownerId'] == ownerId &&
              version['profileId'] == profileId &&
              version['filePath'] == filePath)
          .take(limit)
          .map(FileVersion.fromMap)
          .toList();
    }
    final db = await database;
    final maps = await db!.query(
      'file_versions',
      where: 'ownerId = ? AND profileId = ? AND filePath = ?',
      whereArgs: [ownerId, profileId, filePath],
      orderBy: 'versionNumber DESC',
      limit: limit,
    );
    return maps.map(FileVersion.fromMap).toList();
  }

  Future<void> acknowledgeAlert(int alertId, String ownerId) async {
    if (kIsWeb) {
      final index = _webAlerts.indexWhere(
        (alert) => alert['id'] == alertId && alert['ownerId'] == ownerId,
      );
      if (index != -1) {
        _webAlerts[index]['isRead'] = 1;
        _webAlerts[index]['resolvedAt'] = DateTime.now().toIso8601String();
      }
      return;
    }
    final db = await database;
    await db!.update(
      'system_alerts',
      {'isRead': 1, 'resolvedAt': DateTime.now().toIso8601String()},
      where: 'id = ? AND ownerId = ?',
      whereArgs: [alertId, ownerId],
    );
  }

  Future<FileVersion?> getLatestFileVersionForSnapshot(
    String ownerId,
    int profileId,
    String filePath,
  ) => getLatestFileVersion(ownerId, profileId, filePath);

  Future<SystemHealthSummary> getHealthSummary(String ownerId) async {
    if (kIsWeb) {
      final totalProfiles = _webProfiles
          .where((profile) => profile['ownerId'] == ownerId)
          .length;
      final totalSyncs = _webHistory
          .where((record) => record['ownerId'] == ownerId)
          .length;
      final totalAlerts = _webAlerts
          .where((alert) => alert['ownerId'] == ownerId)
          .length;
      final unresolvedAlerts = _webAlerts
          .where(
            (alert) =>
                alert['ownerId'] == ownerId && alert['resolvedAt'] == null,
          )
          .length;
      final errorSyncs = _webHistory
          .where(
            (record) =>
                record['ownerId'] == ownerId && record['errorMessage'] != null,
          )
          .length;
      DateTime? lastSyncAt;
      final syncs = _webHistory
          .where((record) => record['ownerId'] == ownerId)
          .toList();
      if (syncs.isNotEmpty) {
        lastSyncAt = DateTime.tryParse(syncs.first['date'] as String);
      }
      DateTime? lastEventAt;
      final events = _webEvents
          .where((event) => event['ownerId'] == ownerId)
          .toList();
      if (events.isNotEmpty) {
        lastEventAt = DateTime.tryParse(events.first['createdAt'] as String);
      }
      return SystemHealthSummary(
        totalProfiles: totalProfiles,
        totalSyncs: totalSyncs,
        totalAlerts: totalAlerts,
        unresolvedAlerts: unresolvedAlerts,
        errorSyncs: errorSyncs,
        lastSyncAt: lastSyncAt,
        lastEventAt: lastEventAt,
      );
    }
    final db = await database;
    final totalProfiles =
        Sqflite.firstIntValue(
          await db!.rawQuery(
            'SELECT COUNT(*) FROM ftp_profiles WHERE ownerId = ?',
            [ownerId],
          ),
        ) ??
        0;
    final totalSyncs =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM sync_records WHERE ownerId = ?',
            [ownerId],
          ),
        ) ??
        0;
    final totalAlerts =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM system_alerts WHERE ownerId = ?',
            [ownerId],
          ),
        ) ??
        0;
    final unresolvedAlerts =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM system_alerts WHERE ownerId = ? AND resolvedAt IS NULL',
            [ownerId],
          ),
        ) ??
        0;
    final errorSyncs =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM sync_records WHERE ownerId = ? AND errorMessage IS NOT NULL',
            [ownerId],
          ),
        ) ??
        0;

    DateTime? lastSyncAt;
    final lastSyncRows = await db.rawQuery(
      'SELECT date FROM sync_records WHERE ownerId = ? ORDER BY date DESC LIMIT 1',
      [ownerId],
    );
    if (lastSyncRows.isNotEmpty) {
      lastSyncAt = DateTime.tryParse(lastSyncRows.first['date'] as String);
    }

    DateTime? lastEventAt;
    final lastEventRows = await db.rawQuery(
      'SELECT createdAt FROM system_events WHERE ownerId = ? ORDER BY createdAt DESC LIMIT 1',
      [ownerId],
    );
    if (lastEventRows.isNotEmpty) {
      lastEventAt = DateTime.tryParse(
        lastEventRows.first['createdAt'] as String,
      );
    }

    return SystemHealthSummary(
      totalProfiles: totalProfiles,
      totalSyncs: totalSyncs,
      totalAlerts: totalAlerts,
      unresolvedAlerts: unresolvedAlerts,
      errorSyncs: errorSyncs,
      lastSyncAt: lastSyncAt,
      lastEventAt: lastEventAt,
    );
  }

  // ---- Local Files ----
  Future<List<LocalFile>> getLocalFileDetails(String path) async {
    if (kIsWeb) return [];
    final dir = Directory(path);
    if (!dir.existsSync()) return [];
    return dir.listSync().whereType<File>().map((file) {
      final stat = file.statSync();
      final fileName = file.uri.pathSegments.last;
      return LocalFile(
        name: fileName,
        path: file.path,
        size: stat.size,
        isDirectory: false,
        lastModified: stat.modified,
        extension: extension(file.path).replaceFirst('.', '').toLowerCase(),
      );
    }).toList();
  }

  // ---- Dump Schedules ----
  Future<List<DumpSchedule>> getDumpSchedules(String ownerId) async {
    if (kIsWeb) {
      return _webSchedules
          .where((schedule) => schedule['ownerId'] == ownerId)
          .map(DumpSchedule.fromMap)
          .toList();
    }
    final db = await database;
    final maps = await db!.query(
      'dump_schedules',
      where: 'ownerId = ?',
      whereArgs: [ownerId],
      orderBy: 'nextRunAt ASC',
    );
    return maps.map(DumpSchedule.fromMap).toList();
  }

  Future<DumpSchedule?> getDumpScheduleForProfile(
    String ownerId,
    int profileId,
  ) async {
    if (kIsWeb) {
      for (final schedule in _webSchedules) {
        if (schedule['ownerId'] == ownerId &&
            schedule['profileId'] == profileId) {
          return DumpSchedule.fromMap(schedule);
        }
      }
      return null;
    }
    final db = await database;
    final maps = await db!.query(
      'dump_schedules',
      where: 'ownerId = ? AND profileId = ?',
      whereArgs: [ownerId, profileId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DumpSchedule.fromMap(maps.first);
  }

  Future<int> saveDumpSchedule(DumpSchedule schedule) async {
    final map = schedule.toMap();
    if (kIsWeb) {
      final index = _webSchedules.indexWhere(
        (item) =>
            item['ownerId'] == schedule.ownerId &&
            item['profileId'] == schedule.profileId,
      );
      if (index != -1) {
        _webSchedules[index] = map;
        return schedule.id ?? 0;
      }
      map['id'] = _webIdCounter++;
      _webSchedules.add(map);
      return map['id'] as int;
    }
    final db = await database;
    if (schedule.id == null) {
      return db!.insert(
        'dump_schedules',
        map..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await db!.update(
      'dump_schedules',
      map,
      where: 'id = ? AND ownerId = ?',
      whereArgs: [schedule.id, schedule.ownerId],
    );
    return schedule.id!;
  }

  Future<void> deleteDumpSchedule(int id, String ownerId) async {
    if (kIsWeb) {
      _webSchedules.removeWhere(
        (schedule) => schedule['id'] == id && schedule['ownerId'] == ownerId,
      );
      return;
    }
    final db = await database;
    await db!.delete(
      'dump_schedules',
      where: 'id = ? AND ownerId = ?',
      whereArgs: [id, ownerId],
    );
  }
}
