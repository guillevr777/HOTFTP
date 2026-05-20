import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

import '../domain/entities/ftp_profile.dart';
import '../domain/entities/remote_file.dart';

class LocalDownloadManifest {
  final String localPath;
  final RemoteFile remoteFile;
  final FtpProfile profile;
  final DateTime savedAt;

  LocalDownloadManifest({
    required this.localPath,
    required this.remoteFile,
    required this.profile,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'localPath': localPath,
        'remoteFile': {
          'name': remoteFile.name,
          'path': remoteFile.path,
          'size': remoteFile.size,
          'isDirectory': remoteFile.isDirectory,
          'modifiedAt': remoteFile.modifiedAt?.toIso8601String(),
        },
        'profile': profile.toMap(),
        'savedAt': savedAt.toIso8601String(),
      };

  factory LocalDownloadManifest.fromJson(Map<String, dynamic> json) {
    final remoteFileJson = json['remoteFile'];
    final profileJson = json['profile'];
    if (remoteFileJson is! Map || profileJson is! Map) {
      throw FormatException('Invalid local download manifest');
    }

    return LocalDownloadManifest(
      localPath: '${json['localPath'] ?? ''}',
      remoteFile: RemoteFile(
        name: '${remoteFileJson['name'] ?? ''}',
        path: '${remoteFileJson['path'] ?? ''}',
        size: int.tryParse('${remoteFileJson['size'] ?? 0}') ?? 0,
        isDirectory: _asBool(remoteFileJson['isDirectory']),
        modifiedAt: _parseDate(remoteFileJson['modifiedAt']),
      ),
      profile: FtpProfile.fromMap(Map<String, dynamic>.from(profileJson)),
      savedAt: _parseDate(json['savedAt']) ?? DateTime.now(),
    );
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return '${value ?? ''}'.toLowerCase() == 'true';
  }

  static DateTime? _parseDate(Object? value) {
    final raw = '${value ?? ''}'.trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class LocalDownloadManifestStore {
  static const _folderName = 'hotftp_download_manifests';

  static Future<Directory?> _root() async {
    if (kIsWeb) return null;
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, _folderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _keyFor(String localPath) {
    return sha1.convert(utf8.encode(p.normalize(localPath))).toString();
  }

  static Future<File?> _manifestFile(String localPath) async {
    final root = await _root();
    if (root == null) return null;
    return File(p.join(root.path, '${_keyFor(localPath)}.json'));
  }

  static Future<void> save(LocalDownloadManifest manifest) async {
    final file = await _manifestFile(manifest.localPath);
    if (file == null) return;
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(manifest.toJson()));
  }

  static Future<LocalDownloadManifest?> read(String localPath) async {
    final file = await _manifestFile(localPath);
    if (file == null || !await file.exists()) return null;
    try {
      final raw = await file.readAsString();
      return LocalDownloadManifest.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> delete(String localPath) async {
    final file = await _manifestFile(localPath);
    if (file == null || !await file.exists()) return;
    try {
      await file.delete();
    } catch (_) {}
  }
}
