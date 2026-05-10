abstract class FtpDatasource {
  Future<List<Map<String, dynamic>>> listRemoteFiles(
    String path,
    Map<String, dynamic> config,
  );
  Future<List<String>> listLocalFiles(String path);
  Future<void> uploadFile(
    String localFilePath,
    String remotePath,
    Map<String, dynamic> config,
  );
  Future<void> downloadFile(
    String remoteFileName,
    String localPath,
    Map<String, dynamic> config,
  );
  Future<void> deleteRemoteFile(
    String remoteFileName,
    String remoteDirectory,
    Map<String, dynamic> config,
  );
  Future<void> downloadFileToPath(
    String remoteFileName,
    String remoteDirectory,
    String targetLocalPath,
    Map<String, dynamic> config,
  );
  Future<bool> testConnection(Map<String, dynamic> profile);
}

