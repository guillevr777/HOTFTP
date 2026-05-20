import 'dart:ui' as ui;
import 'package:universal_io/io.dart';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailUtils {
  ThumbnailUtils._();

  static Future<bool> isReadableImageFile(String path) async {
    final file = File(path);
    if (!await file.exists() || await file.length() == 0) {
      return false;
    }

    try {
      final bytes = await file.readAsBytes();
      final codec = await _safeCodec(bytes, 32);
      if (codec == null) return false;
      await codec.getNextFrame();
      codec.dispose();
      return true;
    } catch (_) {
      return false;
    }
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
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final oriented = img.bakeOrientation(decoded);
        final resized = oriented.width >= oriented.height
            ? img.copyResize(oriented, width: maxDimension)
            : img.copyResize(oriented, height: maxDimension);
        await outFile.writeAsBytes(img.encodePng(resized), flush: true);
        return outFile.path;
      }
    } catch (_) {
      // Some camera JPEGs are partially invalid; try Flutter's decoder next.
    }

    final codec = await _safeCodec(bytes, maxDimension);
    if (codec != null) {
      try {
        final frame = await codec.getNextFrame();
        final byteData = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData != null) {
          await outFile.writeAsBytes(
            byteData.buffer.asUint8List(),
            flush: true,
          );
          codec.dispose();
          return outFile.path;
        }
      } catch (_) {
        // Fall through to a clean placeholder.
      } finally {
        codec.dispose();
      }
    }

    await _buildImagePlaceholderThumbnail(
      thumbnailPath: thumbnailPath,
      size: maxDimension,
    );
    return outFile.path;
  }

  static Future<String> buildVideoThumbnailFromFile({
    required String sourcePath,
    required String thumbnailPath,
    int maxDimension = 160,
    int timeMs = 1,
  }) async {
    final sourceFile = File(sourcePath);
    final exists = await sourceFile.exists();
    if (!exists) {
      return buildVideoPlaceholderThumbnail(thumbnailPath: thumbnailPath);
    }

    try {
      if (await sourceFile.length() == 0) {
        return buildVideoPlaceholderThumbnail(thumbnailPath: thumbnailPath);
      }
    } catch (_) {
      return buildVideoPlaceholderThumbnail(thumbnailPath: thumbnailPath);
    }

    final outFile = File(thumbnailPath);
    await outFile.parent.create(recursive: true);

    if (_canGenerateNativeVideoThumbnail()) {
      try {
        final bytes = await VideoThumbnail.thumbnailData(
          video: sourcePath,
          imageFormat: ImageFormat.PNG,
          maxWidth: maxDimension,
          timeMs: timeMs,
          quality: 85,
        );
        if (bytes != null && bytes.isNotEmpty) {
          await outFile.writeAsBytes(bytes, flush: true);
          return outFile.path;
        }
      } catch (_) {
        // Fall back to a stable placeholder when native decoding fails.
      }
    }

    return buildVideoPlaceholderThumbnail(thumbnailPath: thumbnailPath);
  }

  static bool _canGenerateNativeVideoThumbnail() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
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

  static Future<void> _buildImagePlaceholderThumbnail({
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
        ui.Color(0xFF14213D),
        ui.Color(0xFF1F3A5F),
      ]);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(18)),
      background,
    );

    final iconPaint = ui.Paint()..color = const ui.Color(0xFFF8FAFC);
    final shadowPaint = ui.Paint()..color = const ui.Color(0xAA0F172A);
    final center = ui.Offset(size / 2, size / 2);
    canvas.drawCircle(center, size * 0.23, shadowPaint);
    canvas.drawPath(
      ui.Path()
        ..moveTo(center.dx - size * 0.12, center.dy + size * 0.08)
        ..lineTo(center.dx - size * 0.02, center.dy - size * 0.03)
        ..lineTo(center.dx + size * 0.07, center.dy + size * 0.06)
        ..lineTo(center.dx + size * 0.16, center.dy - size * 0.06)
        ..lineTo(center.dx + size * 0.16, center.dy + size * 0.16)
        ..lineTo(center.dx - size * 0.12, center.dy + size * 0.16)
        ..close(),
      iconPaint,
    );
    canvas.drawCircle(
      ui.Offset(center.dx - size * 0.04, center.dy - size * 0.03),
      size * 0.03,
      iconPaint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw StateError('Could not build image placeholder thumbnail');
    }

    await outFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  }
}





