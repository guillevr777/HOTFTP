import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/sync_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  final List<Map<String, dynamic>> _webProfiles = [];
  final List<Map<String, dynamic>> _webHistory = [];
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
      version: 3,
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
    if (kIsWeb) {
      return _webHistory
          .where((record) => record['ownerId'] == ownerId)
          .map(SyncRecord.fromMap)
          .toList();
    }
    final db = await database;
    final maps = await db!.query(
      'sync_records',
      where: 'ownerId = ?',
      whereArgs: [ownerId],
      orderBy: 'date DESC',
      limit: 100,
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
}
