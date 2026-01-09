import '../../core/services/ftp_native_channel.dart';
import '../../domain/entities/ftp_profile.dart';

class FtpDatasourceImpl {
  final FtpNativeChannel channel;

  FtpDatasourceImpl(this.channel);

  Future<bool> connect(FtpProfile profile) {
    return channel.connect({
      'host': profile.host,
      'port': profile.port,
      'username': profile.username,
      'password': profile.password,
    });
  }

  Future<List<Map<String, dynamic>>> listFiles(String path) {
    return channel.listFiles(path);
  }
}
