import 'package:universal_io/io.dart';

import '../interfaces/ftp_datasource.dart';
import 'hotftp_ftp_client.dart';

class FtpRealDatasource implements FtpDatasource {
  final HotftpFtpClient _client;

  FtpRealDatasource({HotftpFtpClient? client})
      : _client = client ?? HotftpFtpClient();

  @override
  Future<bool> testConnection(Map<String, dynamic> profile) =>
      _client.testConnection(profile);

  @override
  Future<List<Map<String, dynamic>>> listRemoteFiles(
    String path,
    Map<String, dynamic> config,
  ) =>
      _client.listRemoteFiles(path, config);

  @override
  Future<List<String>> listLocalFiles(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList();
  }

  @override
  Future<void> uploadFile(
    String localFilePath,
    String remotePath,
    Map<String, dynamic> config,
  ) =>
      _client.uploadFile(localFilePath, remotePath, config);

  @override
  Future<void> downloadFile(
    String remoteFileName,
    String localPath,
    Map<String, dynamic> config,
  ) {
    return downloadFileToPath(
      remoteFileName,
      "/",
      "$localPath/$remoteFileName",
      config,
    );
  }

  @override
  Future<void> downloadFileToPath(
    String remoteFileName,
    String remoteDirectory,
    String targetLocalPath,
    Map<String, dynamic> config,
  ) =>
      _client.downloadFileToPath(
        remoteFileName,
        remoteDirectory,
        targetLocalPath,
        config,
      );

  @override
  Future<void> deleteRemoteFile(
    String remoteFileName,
    String remoteDirectory,
    Map<String, dynamic> config,
  ) =>
      _client.deleteRemoteFile(remoteFileName, remoteDirectory, config);
}
