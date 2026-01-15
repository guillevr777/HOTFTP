
import 'package:ftp_tfg/data/interfaces/ftp_datasource.dart';

class FakeFtpDatasource implements FtpDatasource {
  @override
  Future<List<Map<String, dynamic>>> listRemoteFiles(String path) async {
    return [
      {"name": "file1.txt", "size": 1200, "isDir": false},
      {"name": "folder", "size": 0, "isDir": true},
    ];
  }

  @override
  Future<List<String>> listLocalFiles(String path) async {
    return ["file1.txt", "local_only.txt"];
  }

  @override
  Future<void> uploadFile(String localFilePath, String remotePath) async {}

  @override
  Future<void> downloadFile(String remoteFileName, String localPath) async {}
}
