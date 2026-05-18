import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

import '../../domain/entities/dump_schedule.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/local_file.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/entities/sync_conflict.dart';
import '../../domain/entities/sync_record.dart';
import '../../domain/repositories/ftp_repository.dart';
import '../../utils/file_utils.dart';
import '../../utils/thumbnail_cache.dart';
import '../mappers/remote_file_mapper.dart';
import '../datasources/hotftp_api_client.dart';
import '../../utils/thumbnail_utils.dart';

class ApiFtpRepositoryImpl implements FtpRepository {
  final HotftpApiClient client;

  ApiFtpRepositoryImpl(this.client);

  Map<String, dynamic> _profilePayload(FtpProfile profile, String ownerId) {
    final payload = <String, dynamic>{
      'ownerId': ownerId,
      'transportType': profile.transportType.name,
      'protocol': profile.protocol.name,
      'name': profile.name,
      'host': profile.host,
      'port': profile.port,
      'username': profile.username,
      'password': profile.password,
      'useFTPS': profile.useFTPS,
      'passiveMode': profile.passiveMode,
    };
    if (profile.id != null) {
      payload['id'] = profile.id;
    }
    return payload;
  }

  String _ownerIdFor(FtpProfile profile) {
    final ownerId = profile.ownerId;
    if (ownerId == null || ownerId.isEmpty) return 'demo-owner';
    return ownerId;
  }

  @override
  Future<List<RemoteFile>> getRemoteFiles(
    String path,
    FtpProfile profile,
  ) async {
    final normalizedPath = _normalizeRemotePath(path);
    final data = await client.listRemoteFiles(
      ownerId: _ownerIdFor(profile),
      profileId: profile.id ?? 0,
      path: normalizedPath,
    );
    return data
        .map((map) => RemoteFileMapper.fromMap(map, normalizedPath))
        .where((file) => !_isPseudoEntry(file, normalizedPath))
        .toList();
  }

  @override
  Future<List<String>> getLocalFiles(String path) async {
    if (kIsWeb) return [];
    final dir = Directory(path);
    if (!dir.existsSync()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList();
  }

  String _normalizeRemotePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '/') return '/';
    final normalized = p.posix.normalize(
      trimmed.startsWith('/') ? trimmed : '/$trimmed',
    );
    return normalized == '.' || normalized.isEmpty ? '/' : normalized;
  }

  bool _isPseudoEntry(RemoteFile file, String currentPath) {
    final name = file.name.trim();
    final normalizedCurrentPath = _normalizeRemotePath(currentPath);
    final normalizedFilePath = _normalizeRemotePath(file.path);
    final currentBase = normalizedCurrentPath == '/'
        ? '/'
        : p.posix.basename(normalizedCurrentPath);
    return name.isEmpty ||
        name == '/' ||
        name == '.' ||
        name == '..' ||
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
    return client.uploadFile(
      ownerId: _ownerIdFor(profile),
      profileId: profile.id ?? 0,
      remotePath: _normalizeRemotePath(remotePath),
      localFilePath: localPath,
    );
  }

  @override
  Future<void> downloadFile(
    RemoteFile file,
    String localPath,
    FtpProfile profile,
  ) {
    final remoteDirectory = p.dirname(file.path);
    final targetPath = '$localPath/${file.name}';
    return client.downloadFileToPath(
      ownerId: _ownerIdFor(profile),
      profileId: profile.id ?? 0,
      remotePath: remoteDirectory == '.' ? '/' : remoteDirectory,
      fileName: file.name,
      targetLocalPath: targetPath,
    );
  }

  @override
  Future<void> deleteRemoteFile(RemoteFile file, FtpProfile profile) {
    final directory = file.path == '/' ? '/' : p.dirname(file.path);
    return client.deleteRemoteFile(
      ownerId: _ownerIdFor(profile),
      profileId: profile.id ?? 0,
      remotePath: directory == '.' ? '/' : directory,
      fileName: file.name,
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
    final cacheDir = await ThumbnailCache.resolveDirectory();
    final cacheKey = ThumbnailCache.buildKey(
      filePath: file.path,
      fileName: file.name,
      fileSize: file.size,
      modifiedAt: file.modifiedAt,
      profileId: profile.id ?? 0,
      isVideo: FileUtils.isVideo(file.name),
    );
    final thumbnailPath = '${cacheDir.path}/$cacheKey.png';
    final thumbFile = File(thumbnailPath);

    if (thumbFile.existsSync() &&
        await ThumbnailUtils.isReadableImageFile(thumbnailPath)) {
      return thumbnailPath;
    }

    if (thumbFile.existsSync()) {
      await thumbFile.delete();
    }

    final sourcePath = '${cacheDir.path}/$cacheKey.src';
    final remoteDirectory = p.dirname(file.path);

    await client.downloadFileToPath(
      ownerId: _ownerIdFor(profile),
      profileId: profile.id ?? 0,
      remotePath: remoteDirectory == '.' ? '/' : remoteDirectory,
      fileName: file.name,
      targetLocalPath: sourcePath,
    );
    try {
      if (FileUtils.isVideo(file.name)) {
        return ThumbnailUtils.buildVideoPlaceholderThumbnail(
          thumbnailPath: thumbnailPath,
        );
      }

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
    final remote = await client.listRemoteFiles(
      ownerId: _ownerIdFor(profile),
      profileId: profile.id ?? 0,
      path: remotePath,
    );
    final currentBase = _normalizeRemotePath(remotePath) == '/'
        ? '/'
        : p.posix.basename(_normalizeRemotePath(remotePath));
    final remoteNames = remote
        .map((e) => (e['name'] as String? ?? '').trim())
        .where(
          (name) =>
              name.isNotEmpty &&
              name != '/' &&
              name != '.' &&
              name != '..' &&
              name != _normalizeRemotePath(remotePath) &&
              name != currentBase,
        )
        .toSet();
    return (await getLocalFiles(localPath))
        .where(remoteNames.contains)
        .map(
          (f) =>
              SyncConflict(fileName: f, localExists: true, remoteExists: true),
        )
        .toList();
  }

  @override
  Future<List<FtpProfile>> getProfiles(String ownerId) async {
    final profiles = await client.getProfiles(ownerId);
    return profiles.map(FtpProfile.fromMap).toList();
  }

  @override
  Future<int> saveProfile(FtpProfile profile, String ownerId) async {
    final payload = _profilePayload(profile, ownerId);
    final saved = await client.saveProfile(payload);
    final savedProfile = FtpProfile.fromMap(saved);
    return savedProfile.id ?? profile.id ?? 0;
  }

  @override
  Future<void> deleteProfile(FtpProfile profile, String ownerId) async {
    await client.deleteProfile(ownerId: ownerId, profileId: profile.id ?? 0);
  }

  @override
  Future<bool> testConnection(FtpProfile profile) {
    return client
        .testConnection(_profilePayload(profile, _ownerIdFor(profile)))
        .timeout(const Duration(seconds: 3), onTimeout: () => false)
        .catchError((_) => false);
  }

  @override
  Future<List<SyncRecord>> getSyncHistory(String ownerId) => client
      .getSyncHistory(ownerId)
      .then((items) => items.map(SyncRecord.fromMap).toList());

  @override
  Future<void> saveSyncRecord(SyncRecord record, FtpProfile profile) async {
    await client.saveSyncRecord(record.toMap());
  }

  @override
  Future<DumpSchedule?> getDumpScheduleForProfile(
    String ownerId,
    FtpProfile profile,
  ) async {
    final schedule = await client.getDumpScheduleForProfile(
      ownerId: ownerId,
      profileId: profile.id ?? 0,
    );
    return schedule == null ? null : DumpSchedule.fromMap(schedule);
  }

  @override
  Future<int> saveDumpSchedule(
    DumpSchedule schedule,
    FtpProfile profile,
  ) async {
    final saved = await client.saveDumpSchedule(schedule.toMap());
    final savedSchedule = DumpSchedule.fromMap(saved);
    return savedSchedule.id ?? schedule.id ?? 0;
  }
}
