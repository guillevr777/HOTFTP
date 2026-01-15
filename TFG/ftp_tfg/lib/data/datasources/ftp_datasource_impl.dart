import 'package:ftp_tfg/core/services/ftp_native_channel.dart';
import 'package:ftp_tfg/data/interfaces/ftp_datasource.dart';

class FtpDatasourceImpl implements FtpDatasource {
  final FtpNativeChannel channel;

  FtpDatasourceImpl(this.channel);

  @override
  Future<List<Map<String, dynamic>>> listFiles(String path) {
    return channel.listFiles(path);
  }
}
