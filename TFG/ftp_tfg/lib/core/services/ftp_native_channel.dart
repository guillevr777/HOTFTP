import 'package:flutter/services.dart';

class FtpNativeChannel {
  static const MethodChannel _channel =
      MethodChannel('ftp_channel');

  Future<bool> connect(Map<String, dynamic> config) async {
    final result = await _channel.invokeMethod<bool>(
      'connect',
      config,
    );
    return result ?? false;
  }

  Future<List<Map<String, dynamic>>> listFiles(String path) async {
    final List<dynamic> result =
        await _channel.invokeMethod('listFiles', {
      'path': path,
    });

    return result.cast<Map<String, dynamic>>();
  }
}
