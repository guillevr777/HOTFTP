import '../interfaces/ftp_datasource.dart';

class FtpDatasourceImpl implements FtpDatasource {
  @override
  Future<List<Map<String, dynamic>>> listFiles(String path) async {
    // AQUÍ irá el canal nativo FTP
    // Por ahora devolvemos vacío
    return [];
  }
}
