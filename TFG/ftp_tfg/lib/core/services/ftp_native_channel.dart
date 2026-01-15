import 'package:flutter/services.dart';
import '../../domain/entities/ftp_profile.dart';

class FtpNativeChannel {
  static const _channel = MethodChannel('ftp_channel');

  Future<bool> connect(FtpProfile profile) async {
    return await _channel.invokeMethod('connect', {
      'host': profile.host,
      'port': profile.port,
      'username': profile.username,
      'password': profile.password,
    });
  }

  Future<List<Map<String, dynamic>>> listFiles(String path) async {
    final List<dynamic> result =
        await _channel.invokeMethod('listFiles', {'path': path});
    return result.cast<Map<String, dynamic>>();
  }
}
