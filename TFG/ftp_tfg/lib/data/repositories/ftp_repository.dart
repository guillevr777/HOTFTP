import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

import '../../domain/entities/dump_schedule.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/local_file.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/entities/sync_conflict.dart';
import '../../domain/entities/sync_record.dart';
import '../../domain/repositories/ftp_repository.dart';
import '../interfaces/ftp_datasource.dart';
import '../local/database_helper.dart';
import '../mappers/remote_file_mapper.dart';
import '../../utils/thumbnail_utils.dart';

class FtpRepositoryImpl implements FtpRepository {
  final FtpDatasource datasource;
  final DatabaseHelper _db = DatabaseHelper.instance;

  FtpRepositoryImpl(this.datasource);

  Map<String, dynamic> _getConfig(FtpProfile profile) {
    return {
      'host': profile.host,
      'port': profile.port,
      'username': profile.username,
      'password': profile.password,
      'useFTPS': profile.useFTPS,
      'passiveMode': profile.passiveMode,
    };
  }

  @override
  Future<List<RemoteFile>> getRemoteFiles(
    String path,
    FtpProfile profile,
  ) async {
    final normalizedPath = _normalizeRemotePath(path);
    final data = await datasource.listRemoteFiles(normalizedPath, _getConfig(profile));
    return data
        .map((map) => RemoteFileMapper.fromMap(map, normalizedPath))
        .where((file) => !_isPseudoEntry(file, normalizedPath))
        .toList();
  }

  @override
  Future<List<String>> getLocalFiles(String path) {
    return datasource.listLocalFiles(path);
  }

  String _normalizeRemotePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == "/") return "/";
    final normalized = p.posix.normalize(trimmed.startsWith('/') ? trimmed : '/$trimmed');
    return normalized == "." || normalized.isEmpty ? "/" : normalized;
  }

  bool _isPseudoEntry(RemoteFile file, String currentPath) {
    final name = file.name.trim();
    final normalizedCurrentPath = _normalizeRemotePath(currentPath);
    final normalizedFilePath = _normalizeRemotePath(file.path);
    final currentBase = normalizedCurrentPath == "/"
        ? "/"
        : p.posix.basename(normalizedCurrentPath);
    return name.isEmpty ||
        name == "/" ||
        name == "." ||
        name == ".." ||
        name == normalizedCurrentPath ||
        name == currentBase ||
        normalizedFilePath == normalizedCurrentPath;
  }

  @override
  Future<List<LocalFile>> getLocalFileDetails(String path) {
    if (kIsWeb) return Future.value([]);
    final dir = Directory(path);
    if (!dir.existsSync()) return Future.value([]);
    return Future.value(
      dir.listSync().whereType<File>().map((file) {
        final stat = file.statSync();
        final fileName = file.uri.pathSegments.last;
        return LocalFile(
          name: fileName,
          path: file.path,
          size: stat.size,
          isDirectory: false,
          lastModified: stat.modified,
          extension: p.extension(file.path).replaceFirst('.', '').toLowerCase(),
        );
      }).toList(),
    );
  }

  @override
  Future<void> uploadFile(
    String localPath,
    String remotePath,
    FtpProfile profile,
  ) {
    return datasource.uploadFile(localPath, remotePath, _getConfig(profile));
  }

  @override
  Future<void> downloadFile(
    RemoteFile file,
    String localPath,
    FtpProfile profile,
  ) {
    final remoteDirectory = p.dirname(file.path);
    final targetPath = '$localPath/${file.name}';
    return datasource.downloadFileToPath(
      file.name,
      remoteDirectory == '.' ? '/' : remoteDirectory,
      targetPath,
      _getConfig(profile),
    );
  }

  @override
  Future<void> deleteRemoteFile(RemoteFile file, FtpProfile profile) {
    final directory = file.path == '/' ? '/' : p.dirname(file.path);
    return datasource.deleteRemoteFile(
      file.name,
      directory == '.' ? '/' : directory,
      _getConfig(profile),
    );
  }

  @override
  Future<void> deleteLocalFile(String path) {
    if (kIsWeb) return Future.value();
    final file = File(path);
    if (file.existsSync()) {
      return file.delete();
    }
    return Future.value();
  }

  @override
  Future<String> downloadThumbnail(
    RemoteFile file,
    String remotePath,
    FtpProfile profile,
  ) async {
    if (kIsWeb) return '';
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/thumbnails');
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    final safeName = file.path.replaceAll('/', '_').replaceAll(':', '_');
    final thumbnailPath = '${cacheDir.path}/${profile.id}_$safeName.jpg';
    final thumbFile = File(thumbnailPath);

    if (thumbFile.existsSync()) {
      return thumbnailPath;
    }

    final sourcePath = '${cacheDir.path}/${profile.id}_$safeName.src';
    await datasource.downloadFileToPath(
      file.name,
      remotePath,
      sourcePath,
      _getConfig(profile),
    );
    try {
      return await ThumbnailUtils.buildThumbnailFromFile(
        sourcePath: sourcePath,
        thumbnailPath: thumbnailPath,
      );
    } finally {
      final srcFile = File(sourcePath);
      if (srcFile.existsSync()) {
        await srcFile.delete();
      }
    }
  }

  @override
  Future<List<SyncConflict>> detectConflicts(
    String localPath,
    String remotePath,
    FtpProfile profile,
  ) async {
    final local = await datasource.listLocalFiles(localPath);
    final remote = await datasource.listRemoteFiles(
      remotePath,
      _getConfig(profile),
    );
    final currentBase = _normalizeRemotePath(remotePath) == "/"
        ? "/"
        : p.posix.basename(_normalizeRemotePath(remotePath));
    final remoteNames = remote
        .map((e) => (e['name'] as String? ?? '').trim())
        .where((name) =>
            name.isNotEmpty &&
            name != '/' &&
            name != '.' &&
            name != '..' &&
            name != _normalizeRemotePath(remotePath) &&
            name != currentBase)
        .toSet();
    return local
        .where(remoteNames.contains)
        .map(
          (f) =>
              SyncConflict(fileName: f, localExists: true, remoteExists: true),
        )
        .toList();
  }

  @override
  Future<List<FtpProfile>> getProfiles(String ownerId) =>
      _db.getProfiles(ownerId);

  @override
  Future<int> saveProfile(FtpProfile profile, String ownerId) {
    final localProfile = profile.copyWith(
      transportType: FtpTransportType.local,
    );
    if (profile.id == null) {
      return _db.insertProfile(localProfile, ownerId);
    } else {
      return _db.updateProfile(localProfile, ownerId).then((_) => profile.id!);
    }
  }

  @override
  Future<void> deleteProfile(FtpProfile profile, String ownerId) =>
      _db.deleteProfile(profile.id ?? 0, ownerId);

  @override
  Future<bool> testConnection(FtpProfile profile) {
    return datasource.testConnection(_getConfig(profile));
  }

  @override
  Future<List<SyncRecord>> getSyncHistory(String ownerId) =>
      _db.getSyncHistory(ownerId);

  @override
  Future<void> saveSyncRecord(SyncRecord record, FtpProfile profile) =>
      _db.insertSyncRecord(record);

  @override
  Future<DumpSchedule?> getDumpScheduleForProfile(
    String ownerId,
    FtpProfile profile,
  ) =>
      _db.getDumpScheduleForProfile(ownerId, profile.id ?? 0);

  @override
  Future<int> saveDumpSchedule(
    DumpSchedule schedule,
    FtpProfile profile,
  ) =>
      _db.saveDumpSchedule(schedule);
}





