import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/entities/sync_conflict.dart';
import '../../domain/entities/sync_record.dart';
import '../../domain/repositories/ftp_repository.dart';
import '../interfaces/ftp_datasource.dart';
import '../local/database_helper.dart';
import '../mappers/remote_file_mapper.dart';

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
    final data = await datasource.listRemoteFiles(path, _getConfig(profile));
    return data.map(RemoteFileMapper.fromMap).toList();
  }

  @override
  Future<List<String>> getLocalFiles(String path) {
    return datasource.listLocalFiles(path);
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
    return datasource.downloadFile(file.name, localPath, _getConfig(profile));
  }

  @override
  Future<String> downloadThumbnail(
    RemoteFile file,
    String remotePath,
    FtpProfile profile,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/thumbnails');
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    final localPath = '${cacheDir.path}/${profile.id}_${file.name}';
    final localFile = File(localPath);

    if (localFile.existsSync()) {
      return localPath;
    }

    await datasource.downloadFileToPath(
      file.name,
      remotePath,
      localPath,
      _getConfig(profile),
    );
    return localPath;
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
    final remoteNames = remote.map((e) => e['name']).toSet();
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
    if (profile.id == null) {
      return _db.insertProfile(profile, ownerId);
    } else {
      return _db.updateProfile(profile, ownerId).then((_) => profile.id!);
    }
  }

  @override
  Future<void> deleteProfile(int id, String ownerId) =>
      _db.deleteProfile(id, ownerId);

  @override
  Future<bool> testConnection(FtpProfile profile) {
    return datasource.testConnection(_getConfig(profile));
  }

  @override
  Future<List<SyncRecord>> getSyncHistory(String ownerId) =>
      _db.getSyncHistory(ownerId);

  @override
  Future<void> saveSyncRecord(SyncRecord record) =>
      _db.insertSyncRecord(record);
}
