import 'package:ftp_tfg/data/interfaces/ftp_datasource.dart';

import '../../core/services/ftp_native_channel.dart';
import '../../domain/entities/ftp_profile.dart';

class FtpDatasourceImpl implements FtpDatasource {
  final FtpNativeChannel channel;

  FtpDatasourceImpl(this.channel);

  @override
  Future<bool> connect(FtpProfile profile) {
    return channel.connect(profile);
  }

  @override
  Future<List<Map<String, dynamic>>> listFiles(String path) {
    return channel.listFiles(path);
  }
}
