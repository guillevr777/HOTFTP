import 'package:ftp_tfg/data/datasources/fake_datasource.dart';

class FtpViewModel {
  final FakeFtpDatasource datasource;

  List<Map<String, dynamic>> remoteFiles = [];

  FtpViewModel(this.datasource);

  Future<void> loadFiles(String path) async {
    remoteFiles = await datasource.listFiles(path);
  }
}
