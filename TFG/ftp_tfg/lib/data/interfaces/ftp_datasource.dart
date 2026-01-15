abstract class FtpDatasource {
  Future<List<Map<String, dynamic>>> listRemoteFiles(String path);
  Future<List<String>> listLocalFiles(String path);
  Future<void> uploadFile(String localFilePath, String remotePath);
  Future<void> downloadFile(String remoteFileName, String localPath);
}
