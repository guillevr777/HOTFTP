import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

class ThumbnailCache {
  ThumbnailCache._();

  static const int cacheVersion = 5;

  static Future<Directory> resolveDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final cacheDir = Directory(
      p.join(supportDir.path, 'thumbnails_v$cacheVersion'),
    );
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    return cacheDir;
  }

  static String buildKey({
    required String filePath,
    required String fileName,
    required int fileSize,
    required DateTime? modifiedAt,
    required int profileId,
    required bool isVideo,
  }) {
    final payload = [
      'v$cacheVersion',
      'profile:$profileId',
      'path:$filePath',
      'name:$fileName',
      'size:$fileSize',
      'modified:${modifiedAt?.toUtc().toIso8601String() ?? 'na'}',
      'kind:${isVideo ? 'video' : 'image'}',
    ].join('|');
    return sha1.convert(utf8.encode(payload)).toString();
  }
}
