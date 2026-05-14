import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ftp_tfg/data/interfaces/ftp_datasource.dart';
import 'package:ftp_tfg/data/repositories/ftp_repository.dart';
import 'package:ftp_tfg/domain/entities/dump_schedule.dart';
import 'package:ftp_tfg/domain/entities/ftp_profile.dart';

class _SlowDatasource implements FtpDatasource {
  @override
  Future<bool> testConnection(Map<String, dynamic> profile) async {
    await Future.delayed(const Duration(seconds: 5));
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> listRemoteFiles(
    String path,
    Map<String, dynamic> config,
  ) =>
      throw UnimplementedError();

  @override
  Future<List<String>> listLocalFiles(String path) =>
      throw UnimplementedError();

  @override
  Future<void> uploadFile(
    String localFilePath,
    String remotePath,
    Map<String, dynamic> config,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> downloadFile(
    String remoteFileName,
    String localPath,
    Map<String, dynamic> config,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> deleteRemoteFile(
    String remoteFileName,
    String remoteDirectory,
    Map<String, dynamic> config,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> downloadFileToPath(
    String remoteFileName,
    String remoteDirectory,
    String targetLocalPath,
    Map<String, dynamic> config,
  ) =>
      throw UnimplementedError();
}

void main() {
  test('testConnection times out after three seconds', () async {
    final repository = FtpRepositoryImpl(_SlowDatasource());
    final profile = FtpProfile(
      name: 'Slow',
      host: '192.168.1.20',
      username: 'user',
      password: 'pass',
    );

    final stopwatch = Stopwatch()..start();
    final ok = await repository.testConnection(profile);
    stopwatch.stop();

    expect(ok, isFalse);
    expect(stopwatch.elapsed.inSeconds, lessThan(4));
  });
}
