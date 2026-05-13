import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ftp_tfg/utils/thumbnail_cache.dart';
import 'package:ftp_tfg/utils/thumbnail_utils.dart';

void main() {
  test('falls back to copying the original file when decoding fails', () async {
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
    expect(await target.readAsBytes(), bytes);
  });

  test('builds a placeholder thumbnail for videos', () async {
    final tempDir = await Directory.systemTemp.createTemp('video-thumb-test-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final target = File('${tempDir.path}/thumbs/video.png');
    final result = await ThumbnailUtils.buildVideoPlaceholderThumbnail(
      thumbnailPath: target.path,
    );

    expect(result, target.path);
    expect(await target.exists(), isTrue);
    expect(await target.length(), greaterThan(0));
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
