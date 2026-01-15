import 'dart:io';
import 'package:ftp_tfg/data/interfaces/ftp_datasource.dart';
import 'package:ftpconnect/ftpconnect.dart';

class FtpRealDatasource implements FtpDatasource {
  final FTPConnect _ftp;

  FtpRealDatasource({
    required String host,
    required String user,
    required String pass,
    int port = 21,
  }) : _ftp = FTPConnect(
          host,
          user: user,
          pass: pass,
          port: port,
        );

  @override
  Future<List<Map<String, dynamic>>> listRemoteFiles(String path) async {
    await _ftp.connect();
    await _ftp.changeDirectory(path);

    final entries = await _ftp.listDirectoryContent();

    await _ftp.disconnect();

    return entries.map((e) => {
      "name": e.name,
      "size": e.size ?? 0,
      "isDir": e.type == FTPEntryType.dir,
    }).toList();
  }

  @override
  Future<List<String>> listLocalFiles(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) return [];

    return dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList();
  }

  @override
  Future<void> uploadFile(String localFilePath, String remotePath) async {
    final file = File(localFilePath);
    if (!file.existsSync()) throw Exception("Archivo local no encontrado");

    await _ftp.connect();
    await _ftp.changeDirectory(remotePath);
    await _ftp.uploadFile(file);
    await _ftp.disconnect();
  }

  @override
  Future<void> downloadFile(String remoteFileName, String localPath) async {
    final file = File('$localPath/$remoteFileName');

    await _ftp.connect();
    await _ftp.downloadFile(remoteFileName, file);
    await _ftp.disconnect();
  }
}
