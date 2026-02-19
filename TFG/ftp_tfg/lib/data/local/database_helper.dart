import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/sync_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;
  
  // Memoria para Web
  final List<Map<String, dynamic>> _webProfiles = [];
  final List<Map<String, dynamic>> _webHistory = [];
  int _webIdCounter = 1;

  DatabaseHelper._internal();

  Future<Database?> get database async {
    if (kIsWeb) return null; // No usamos sqflite en Web
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDb();
    return _db;
  }

  Future<Database> _initDb() async {
    // Solo se llama en móvil/escritorio
    String path;
    try {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'hotftp.db');
    } catch (e) {
      path = inMemoryDatabasePath;
    }

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ftp_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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

  // ---- Profiles ----
  Future<List<FtpProfile>> getProfiles() async {
    if (kIsWeb) {
      return _webProfiles.map(FtpProfile.fromMap).toList();
    }
    final db = await database;
    try {
      final maps = await db!.query('ftp_profiles', orderBy: 'name ASC');
      return maps.map(FtpProfile.fromMap).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> insertProfile(FtpProfile profile) async {
    final map = profile.toMap();
    if (kIsWeb) {
      map['id'] = _webIdCounter++;
      _webProfiles.add(map);
      return map['id'];
    }
    final db = await database;
    return db!.insert('ftp_profiles', map..remove('id'));
  }

  Future<int> updateProfile(FtpProfile profile) async {
    if (kIsWeb) {
      final index = _webProfiles.indexWhere((p) => p['id'] == profile.id);
      if (index != -1) {
        _webProfiles[index] = profile.toMap();
      }
      return profile.id!;
    }
    final db = await database;
    return db!.update(
      'ftp_profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<void> deleteProfile(int id) async {
    if (kIsWeb) {
      _webProfiles.removeWhere((p) => p['id'] == id);
      return;
    }
    final db = await database;
    await db!.delete('ftp_profiles', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Sync Records ----
  Future<List<SyncRecord>> getSyncHistory() async {
    if (kIsWeb) {
      return _webHistory.map(SyncRecord.fromMap).toList();
    }
    final db = await database;
    try {
      final maps = await db!.query('sync_records', orderBy: 'date DESC', limit: 100);
      return maps.map(SyncRecord.fromMap).toList();
    } catch (_) {
      return [];
    }
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
