import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';

class ThumbnailUtils {
  ThumbnailUtils._();

  static Future<String> buildThumbnailFromFile({
    required String sourcePath,
    required String thumbnailPath,
    int maxDimension = 160,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source image not found', sourcePath);
    }

    final outFile = File(thumbnailPath);
    await outFile.parent.create(recursive: true);

    final bytes = await sourceFile.readAsBytes();
    final codec = await _safeCodec(bytes, maxDimension);
    if (codec == null) {
      // If Flutter cannot decode the image, keep the original bytes so we
      // still cache something usable instead of failing the whole scan.
      await sourceFile.copy(outFile.path);
      return outFile.path;
    }

    final frame = await codec.getNextFrame();
    final thumbnail = frame.image;
    final byteData = await thumbnail.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      await sourceFile.copy(outFile.path);
      return outFile.path;
    }

    await outFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return outFile.path;
  }

  static Future<ui.Codec?> _safeCodec(List<int> bytes, int maxDimension) async {
    try {
      return await ui.instantiateImageCodec(
        Uint8List.fromList(bytes),
        targetWidth: maxDimension,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String> buildVideoPlaceholderThumbnail({
    required String thumbnailPath,
    int size = 160,
  }) async {
    final outFile = File(thumbnailPath);
    await outFile.parent.create(recursive: true);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final rect = ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    final background = ui.Paint()
      ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, const [
        ui.Color(0xFF172033),
        ui.Color(0xFF2A3A57),
      ]);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(18)),
      background,
    );

    final playPaint = ui.Paint()..color = const ui.Color(0xFFF8FAFC);
    final center = ui.Offset(size / 2, size / 2);
    final triangle = ui.Path()
      ..moveTo(center.dx - size * 0.10, center.dy - size * 0.16)
      ..lineTo(center.dx - size * 0.10, center.dy + size * 0.16)
      ..lineTo(center.dx + size * 0.18, center.dy)
      ..close();
    canvas.drawCircle(
      center,
      size * 0.22,
      ui.Paint()..color = const ui.Color(0xAA0F172A),
    );
    canvas.drawPath(triangle, playPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw StateError('Could not build video placeholder thumbnail');
    }

    await outFile.writeAsBytes(bytes.buffer.asUint8List());
    return outFile.path;
  }
}
