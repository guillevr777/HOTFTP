import '../interfaces/ftp_datasource.dart';

class FakeFtpDatasource implements FtpDatasource {
  @override
  Future<List<Map<String, dynamic>>> listFiles(String path) async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      {
        'name': 'Documents',
        'path': '$path/Documents',
        'isDirectory': true,
        'size': 0,
      },
      {
        'name': 'file.txt',
        'path': '$path/file.txt',
        'isDirectory': false,
        'size': 1200,
      },
    ];
  }
}
