import '../../domain/entities/ftp_profile.dart';

abstract class FtpDatasource {
  Future<bool> connect(FtpProfile profile);
  Future<List<Map<String, dynamic>>> listFiles(String path);
}
