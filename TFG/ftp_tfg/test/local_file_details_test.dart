import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ftp_tfg/data/interfaces/ftp_datasource.dart';
import 'package:ftp_tfg/data/repositories/ftp_repository.dart';

void main() {
  test('getLocalFileDetails includes folders and files', () async {
    final tempDir = await Directory.systemTemp.createTemp('hotftp_local_test_');
    await Directory('${tempDir.path}/nested').create();
    await File('${tempDir.path}/note.txt').writeAsString('hello');

    final repository = FtpRepositoryImpl(_NoopDatasource());
    final entries = await repository.getLocalFileDetails(tempDir.path);

    expect(entries, hasLength(2));
    expect(
      entries.any((entry) => entry.name == 'nested' && entry.isDirectory),
      isTrue,
    );
    expect(
      entries.any((entry) => entry.name == 'note.txt' && !entry.isDirectory),
      isTrue,
    );
  });
}

class _NoopDatasource implements FtpDatasource {
  @override
  Future<List<Map<String, dynamic>>> listRemoteFiles(
    String path,
    Map<String, dynamic> config,
  ) async => [];

  @override
  Future<List<String>> listLocalFiles(String path) async => [];

  @override
  Future<void> createRemoteDirectory(
    String remotePath,
    Map<String, dynamic> config,
  ) async {}

  @override
  Future<void> deleteRemoteFile(
    String remoteFileName,
    String remoteDirectory,
    Map<String, dynamic> config,
  ) async {}

  @override
  Future<void> downloadFile(
    String remoteFileName,
    String localPath,
    Map<String, dynamic> config, {
    void Function(double progress)? onProgress,
    int? expectedSize,
  }) async {}

  @override
  Future<void> downloadFileToPath(
    String remoteFileName,
    String remoteDirectory,
    String targetLocalPath,
    Map<String, dynamic> config, {
    void Function(double progress)? onProgress,
    int? expectedSize,
  }) async {}

  @override
  Future<bool> testConnection(Map<String, dynamic> profile) async => true;

  @override
  Future<void> uploadFile(
    String localFilePath,
    String remotePath,
    Map<String, dynamic> config,
  ) async {}
}
