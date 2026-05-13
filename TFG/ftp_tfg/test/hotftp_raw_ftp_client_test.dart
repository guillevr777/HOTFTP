import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ftp_tfg/data/datasources/hotftp_raw_ftp_client.dart';

void main() {
  test('parses EPSV passive port', () {
    expect(
      HotftpRawFtpClient.parsePassivePort('229 Entering Extended Passive Mode (|||49152|)'),
      49152,
    );
  });

  test('parses PASV passive port', () {
    expect(
      HotftpRawFtpClient.parsePassivePort(
        '227 Entering Passive Mode (192,168,1,10,195,44)',
      ),
      49964,
    );
  });

  test('decodes latin1 bytes when utf8 fails', () {
    final bytes = latin1.encode('canción');
    expect(HotftpRawFtpClient.decodeBytes(bytes), 'canción');
  });

  test('parses MLSD directory listing', () {
    final parsed = HotftpRawFtpClient.parseDirectoryListing(
      'type=file;size=123;modify=20240512103045; report.jpg\r\n',
      true,
    );

    expect(parsed, hasLength(1));
    expect(parsed.first['name'], 'report.jpg');
    expect(parsed.first['size'], 123);
    expect(parsed.first['isDir'], isFalse);
    expect(parsed.first['modifyTime'], isNotNull);
  });

  test('parses LIST directory listing', () {
    final parsed = HotftpRawFtpClient.parseDirectoryListing(
      '-rw-r--r-- 1 owner group 213 Aug 26 16:31 FileName.txt\n',
      false,
    );

    expect(parsed, hasLength(1));
    expect(parsed.first['name'], 'FileName.txt');
    expect(parsed.first['size'], 213);
    expect(parsed.first['isDir'], isFalse);
  });
}
