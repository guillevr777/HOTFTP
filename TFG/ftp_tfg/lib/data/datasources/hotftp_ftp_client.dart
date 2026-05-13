import 'hotftp_raw_ftp_client.dart';

class HotftpFtpClient {
  final HotftpRawFtpClient _rawClient = HotftpRawFtpClient();

  Future<bool> testConnection(Map<String, dynamic> profile) async {
    return _rawClient.testConnection(profile);
  }

  Future<List<Map<String, dynamic>>> listRemoteFiles(
    String path,
    Map<String, dynamic> config,
  ) async {
    return _rawClient.listRemoteFiles(path, config);
  }

  Future<void> uploadFile(
    String localFilePath,
    String remotePath,
    Map<String, dynamic> config,
  ) async {
    return _rawClient.uploadFile(localFilePath, remotePath, config);
  }

  Future<void> downloadFileToPath(
    String remoteFileName,
    String remoteDirectory,
    String targetLocalPath,
    Map<String, dynamic> config,
  ) async {
    return _rawClient.downloadFileToPath(
      remoteFileName,
      remoteDirectory,
      targetLocalPath,
      config,
    );
  }

  Future<void> deleteRemoteFile(
    String remoteFileName,
    String remoteDirectory,
    Map<String, dynamic> config,
  ) async {
    return _rawClient.deleteRemoteFile(remoteFileName, remoteDirectory, config);
  }
}
