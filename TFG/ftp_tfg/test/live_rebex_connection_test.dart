import 'package:flutter_test/flutter_test.dart';
import 'package:ftp_tfg/data/datasources/hotftp_raw_ftp_client.dart';
import 'package:ftp_tfg/data/datasources/hotftp_sftp_client.dart';

void main() {
  const baseConfig = {
    'host': 'test.rebex.net',
    'username': 'demo',
    'password': 'password',
    'passiveMode': true,
  };

  test(
    'connects to Rebex over FTPS and lists files',
    () async {
    final client = HotftpRawFtpClient();
    final config = {
      ...baseConfig,
      'port': 990,
      'protocol': 'ftps',
      'useFTPS': true,
    };

    expect(await client.testConnection(config), isTrue);
    final files = await client.listRemoteFiles('/', config);
    expect(files, isNotEmpty);
  },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test('connects to Rebex over SFTP and lists files', () async {
    final client = HotftpSftpClient();
    final config = {
      ...baseConfig,
      'port': 22,
      'protocol': 'sftp',
    };

    expect(await client.testConnection(config), isTrue);
    final files = await client.listRemoteFiles('/', config);
    expect(files, isNotEmpty);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
