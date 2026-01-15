import 'package:flutter/services.dart';

class FtpNativeChannel {
  static const _channel = MethodChannel('ftp_channel');

  Future<List<Map<String, dynamic>>> listFiles(String path) async {
    final List<dynamic> result =
        await _channel.invokeMethod('listFiles', {'path': path});

    return result.cast<Map<String, dynamic>>();
  }
}
