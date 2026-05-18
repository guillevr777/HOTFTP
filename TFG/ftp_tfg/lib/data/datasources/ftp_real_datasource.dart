import 'package:universal_io/io.dart';

import '../interfaces/ftp_datasource.dart';
import 'hotftp_sftp_client.dart';
import 'hotftp_ftp_client.dart';

class FtpRealDatasource implements FtpDatasource {
  final HotftpFtpClient _client;
  final HotftpSftpClient _sftpClient;

  FtpRealDatasource({HotftpFtpClient? client, HotftpSftpClient? sftpClient})
      : _client = client ?? HotftpFtpClient(),
        _sftpClient = sftpClient ?? HotftpSftpClient();

  bool _usesSftp(Map<String, dynamic> config) {
    final raw = config['protocol'];
    if (raw is Enum) {
      return raw.name.toLowerCase() == 'sftp';
    }
    final normalized = '${raw ?? ''}'.trim().toLowerCase();
    return normalized == 'sftp' ||
        normalized.endsWith('.sftp');
  }

  @override
  Future<bool> testConnection(Map<String, dynamic> profile) =>
      _usesSftp(profile)
          ? _sftpClient.testConnection(profile)
          : _client.testConnection(profile);

  @override
  Future<List<Map<String, dynamic>>> listRemoteFiles(
    String path,
    Map<String, dynamic> config,
  ) =>
      _usesSftp(config)
          ? _sftpClient.listRemoteFiles(path, config)
          : _client.listRemoteFiles(path, config);

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
      _usesSftp(config)
          ? _sftpClient.uploadFile(localFilePath, remotePath, config)
          : _client.uploadFile(localFilePath, remotePath, config);

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
      _usesSftp(config)
          ? _sftpClient.downloadFileToPath(
              remoteFileName,
              remoteDirectory,
              targetLocalPath,
              config,
            )
          : _client.downloadFileToPath(
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
      _usesSftp(config)
          ? _sftpClient.deleteRemoteFile(
              remoteFileName,
              remoteDirectory,
              config,
            )
          : _client.deleteRemoteFile(remoteFileName, remoteDirectory, config);
}
