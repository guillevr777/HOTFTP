import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:ftp_tfg/utils/thumbnail_cache.dart';
import 'package:ftp_tfg/utils/thumbnail_utils.dart';

void main() {
  test('falls back to a placeholder thumbnail when decoding fails', () async {
    final tempDir = await Directory.systemTemp.createTemp('thumb-test-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final source = File('${tempDir.path}/broken.jpg');
    final target = File('${tempDir.path}/thumbs/output.jpg');
    final bytes = List<int>.generate(32, (index) => index);
    await source.writeAsBytes(bytes);

    final result = await ThumbnailUtils.buildThumbnailFromFile(
      sourcePath: source.path,
      thumbnailPath: target.path,
    );

    expect(result, target.path);
    expect(await target.exists(), isTrue);
    expect(await target.length(), greaterThan(0));
    final decoded = img.decodeImage(await target.readAsBytes());
    expect(decoded, isNotNull);
  });

  test('builds a placeholder thumbnail for videos', () async {
    final tempDir = await Directory.systemTemp.createTemp('video-thumb-test-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final source = File('${tempDir.path}/source.mp4');
    final target = File('${tempDir.path}/thumbs/video.png');
    await source.writeAsBytes([0, 1, 2, 3, 4]);

    final result = await ThumbnailUtils.buildVideoThumbnailFromFile(
      sourcePath: source.path,
      thumbnailPath: target.path,
    );

    expect(result, target.path);
    expect(await target.exists(), isTrue);
    expect(await target.length(), greaterThan(0));
  });

  test('falls back to a placeholder when the video source is missing', () async {
    final tempDir = await Directory.systemTemp.createTemp('video-thumb-missing-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final source = File('${tempDir.path}/missing.mp4');
    final target = File('${tempDir.path}/thumbs/missing.png');

    final result = await ThumbnailUtils.buildVideoThumbnailFromFile(
      sourcePath: source.path,
      thumbnailPath: target.path,
    );

    expect(result, target.path);
    expect(await target.exists(), isTrue);
    expect(await target.length(), greaterThan(0));
  });

  test('builds a resized thumbnail for images', () async {
    final tempDir = await Directory.systemTemp.createTemp('image-thumb-test-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final source = File('${tempDir.path}/source.jpg');
    final target = File('${tempDir.path}/thumbs/output.png');
    final sourceImage = img.Image(width: 400, height: 200);
    for (var y = 0; y < sourceImage.height; y++) {
      for (var x = 0; x < sourceImage.width; x++) {
        sourceImage.setPixelRgba(x, y, 0, 128, 255, 255);
      }
    }
    await source.writeAsBytes(img.encodeJpg(sourceImage));

    final result = await ThumbnailUtils.buildThumbnailFromFile(
      sourcePath: source.path,
      thumbnailPath: target.path,
      maxDimension: 160,
    );

    expect(result, target.path);
    final decoded = img.decodeImage(await target.readAsBytes());
    expect(decoded, isNotNull);
    expect(decoded!.width, lessThanOrEqualTo(160));
    expect(decoded.height, greaterThan(0));
  });

  test('detects readable image thumbnails', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'thumb-validity-test-',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final validPng = File('${tempDir.path}/valid.png');
    final invalidPng = File('${tempDir.path}/invalid.png');
    final generated = img.Image(width: 1, height: 1);
    generated.setPixelRgba(0, 0, 255, 0, 0, 255);
    await validPng.writeAsBytes(img.encodePng(generated));
    await invalidPng.writeAsBytes([0, 1, 2, 3, 4]);

    expect(await ThumbnailUtils.isReadableImageFile(validPng.path), isTrue);
    expect(await ThumbnailUtils.isReadableImageFile(invalidPng.path), isFalse);
  });

  test('thumbnail cache key changes when file metadata changes', () {
    final base = ThumbnailCache.buildKey(
      filePath: '/photos/image.jpg',
      fileName: 'image.jpg',
      fileSize: 1024,
      modifiedAt: DateTime.parse('2026-05-13T12:00:00Z'),
      profileId: 7,
      isVideo: false,
    );
    final changedSize = ThumbnailCache.buildKey(
      filePath: '/photos/image.jpg',
      fileName: 'image.jpg',
      fileSize: 2048,
      modifiedAt: DateTime.parse('2026-05-13T12:00:00Z'),
      profileId: 7,
      isVideo: false,
    );

    expect(base, isNot(equals(changedSize)));
  });
}





