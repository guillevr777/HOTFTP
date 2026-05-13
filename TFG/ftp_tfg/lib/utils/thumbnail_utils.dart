import 'dart:io';

import 'package:image/image.dart' as img;

class ThumbnailUtils {
  ThumbnailUtils._();

  static Future<String> buildThumbnailFromFile({
    required String sourcePath,
    required String thumbnailPath,
    int maxDimension = 160,
    int quality = 78,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source image not found', sourcePath);
    }

    final sourceBytes = await sourceFile.readAsBytes();
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      throw FormatException('Unsupported image format: $sourcePath');
    }

    final resized = decoded.width > decoded.height
        ? img.copyResize(decoded, width: maxDimension)
        : img.copyResize(decoded, height: maxDimension);

    final outFile = File(thumbnailPath);
    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(img.encodeJpg(resized, quality: quality));
    return outFile.path;
  }
}
