import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ftp_tfg/data/interfaces/ftp_datasource.dart';
import 'package:ftp_tfg/data/repositories/ftp_repository.dart';
import 'package:ftp_tfg/domain/entities/ftp_profile.dart';

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

  test(
    'detectConflicts ignores files that are identical in both sides',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'hotftp_conflict_test_',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final localFile = File('${tempDir.path}/shared.txt');
      await localFile.writeAsString('same content');
      final modifiedAt = DateTime(2026, 1, 1, 12);
      localFile.setLastModifiedSync(modifiedAt);

      final repository = FtpRepositoryImpl(
        _NoopDatasource(
          remoteFiles: [
            {
              'name': 'shared.txt',
              'size': 12,
              'isDir': false,
              'modifyTime': modifiedAt.toIso8601String(),
            },
          ],
        ),
      );

      final conflicts = await repository.detectConflicts(
        tempDir.path,
        '/',
        _profile(),
      );

      expect(conflicts, isEmpty);
    },
  );
}

class _NoopDatasource implements FtpDatasource {
  _NoopDatasource({List<Map<String, dynamic>>? remoteFiles})
    : remoteFiles = remoteFiles ?? [];

  final List<Map<String, dynamic>> remoteFiles;

  @override
  Future<List<Map<String, dynamic>>> listRemoteFiles(
    String path,
    Map<String, dynamic> config,
  ) async => remoteFiles;

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

FtpProfile _profile() {
  return FtpProfile(
    id: 1,
    ownerId: 'owner-1',
    name: 'Perfil',
    host: 'localhost',
    port: 21,
    username: 'user',
    password: 'pass',
  );
}
