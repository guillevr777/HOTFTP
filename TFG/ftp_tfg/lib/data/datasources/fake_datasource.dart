import 'package:ftp_tfg/data/interfaces/ftp_datasource.dart';
import '../../domain/entities/ftp_profile.dart';

class FakeFtpDatasource implements FtpDatasource {
  bool _connected = false;

  @override
  Future<bool> connect(FtpProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _connected = true;
    return true; // siempre conecta (fake)
  }

  @override
  Future<List<Map<String, dynamic>>> listFiles(String path) async {
    if (!_connected) {
      return [];
    }

    await Future.delayed(const Duration(seconds: 1));

    return [
      {
        'name': 'Documents',
        'path': '$path/Documents',
        'isDirectory': true,
        'size': 0,
      },
      {
        'name': 'Images',
        'path': '$path/Images',
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
