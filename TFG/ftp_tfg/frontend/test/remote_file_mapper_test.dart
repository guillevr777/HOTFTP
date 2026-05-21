import 'package:flutter_test/flutter_test.dart';

import 'package:ftp_tfg/data/mappers/remote_file_mapper.dart';

void main() {
  test('maps directory flags from both legacy and API payloads', () {
    final legacy = RemoteFileMapper.fromMap(
      {
        'name': 'pub',
        'size': 0,
        'isDir': true,
        'modifyTime': '2026-01-01T00:00:00.000Z',
      },
      '/home',
    );

    final api = RemoteFileMapper.fromMap(
      {
        'name': 'pub',
        'size': 0,
        'isDirectory': true,
        'modifyTime': '2026-01-01T00:00:00.000Z',
      },
      '/home',
    );

    expect(legacy.isDirectory, isTrue);
    expect(api.isDirectory, isTrue);
    expect(legacy.path, '/home/pub');
    expect(api.path, '/home/pub');
  });
}
