import 'package:ftp_tfg/data/interfaces/ftp_datasource.dart';

import '../../domain/entities/remote_file.dart';
import '../../domain/entities/sync_conflict.dart';
import '../../domain/repositories/ftp_repository.dart';
import '../mappers/remote_file_mapper.dart';

class FtpRepositoryImpl implements FtpRepository {
  final FtpDatasource datasource;

  FtpRepositoryImpl(this.datasource);

  @override
  Future<List<RemoteFile>> getRemoteFiles(String path) async {
    final data = await datasource.listRemoteFiles(path);
    return data.map(RemoteFileMapper.fromMap).toList();
  }

  @override
  Future<List<String>> getLocalFiles(String path) {
    return datasource.listLocalFiles(path);
  }

  @override
  Future<void> uploadFile(String localPath, String remotePath) {
    return datasource.uploadFile(localPath, remotePath);
  }

  @override
  Future<void> downloadFile(RemoteFile file, String localPath) {
    return datasource.downloadFile(file.name, localPath);
  }

  @override
  Future<List<SyncConflict>> detectConflicts(String localPath, String remotePath) async {
    final local = await datasource.listLocalFiles(localPath);
    final remote = await datasource.listRemoteFiles(remotePath);
    final remoteNames = remote.map((e) => e['name']).toSet();

    return local.where(remoteNames.contains).map(
      (f) => SyncConflict(fileName: f, localExists: true, remoteExists: true),
    ).toList();
  }
}
