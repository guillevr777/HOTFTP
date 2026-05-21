import 'package:flutter_test/flutter_test.dart';
import 'package:ftp_tfg/data/datasources/ftp_real_datasource.dart';
import 'package:ftp_tfg/data/datasources/hotftp_ftp_client.dart';
import 'package:ftp_tfg/data/datasources/hotftp_sftp_client.dart';

class _FakeFtpClient extends HotftpFtpClient {
  int listCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> listRemoteFiles(
    String path,
    Map<String, dynamic> config,
  ) async {
    listCalls++;
    return [
      {'name': 'ftp.txt', 'size': 1, 'isDir': false},
    ];
  }
}

class _FakeSftpClient extends HotftpSftpClient {
  int listCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> listRemoteFiles(
    String path,
    Map<String, dynamic> config,
  ) async {
    listCalls++;
    return [
      {'name': 'sftp.txt', 'size': 2, 'isDir': false},
    ];
  }
}

void main() {
  test('routes FTP requests to the FTP client', () async {
    final ftp = _FakeFtpClient();
    final sftp = _FakeSftpClient();
    final datasource = FtpRealDatasource(client: ftp, sftpClient: sftp);

    final result = await datasource.listRemoteFiles(
      '/',
      {'protocol': 'ftp'},
    );

    expect(result.first['name'], 'ftp.txt');
    expect(ftp.listCalls, 1);
    expect(sftp.listCalls, 0);
  });

  test('routes SFTP requests to the SFTP client', () async {
    final ftp = _FakeFtpClient();
    final sftp = _FakeSftpClient();
    final datasource = FtpRealDatasource(client: ftp, sftpClient: sftp);

    final result = await datasource.listRemoteFiles(
      '/',
      {'protocol': 'sftp'},
    );

    expect(result.first['name'], 'sftp.txt');
    expect(ftp.listCalls, 0);
    expect(sftp.listCalls, 1);
  });

  test('routes SFTP requests even when protocol is serialized differently', () async {
    final ftp = _FakeFtpClient();
    final sftp = _FakeSftpClient();
    final datasource = FtpRealDatasource(client: ftp, sftpClient: sftp);

    await datasource.listRemoteFiles(
      '/',
      {'protocol': 'FtpProtocolType.sftp'},
    );

    expect(ftp.listCalls, 0);
    expect(sftp.listCalls, 1);
  });
}
