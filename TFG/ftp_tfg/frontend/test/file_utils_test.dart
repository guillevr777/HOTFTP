import 'package:flutter_test/flutter_test.dart';
import 'package:ftp_tfg/utils/file_utils.dart';

void main() {
  test('detects file categories correctly', () {
    expect(FileUtils.isImage('photo.JPG'), isTrue);
    expect(FileUtils.isVideo('movie.mp4'), isTrue);
    expect(FileUtils.isDocument('notes.pdf'), isTrue);
    expect(FileUtils.isArchive('backup.zip'), isTrue);
    expect(FileUtils.fileCategory('folder', isDirectory: true), 'Carpeta');
  });

  test('extracts file extensions robustly', () {
    expect(FileUtils.extensionOf('archive.tar.gz'), 'gz');
    expect(FileUtils.extensionOf('no_extension'), '');
  });
}
