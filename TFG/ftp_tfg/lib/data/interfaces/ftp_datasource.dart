abstract class FtpDatasource {
  Future<List<Map<String, dynamic>>> listFiles(String path);
}
