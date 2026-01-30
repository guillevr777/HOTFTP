import 'dart:io';
import 'package:ftpconnect/ftpconnect.dart';
import '../interfaces/ftp_datasource.dart';

class FtpRealDatasource implements FtpDatasource {
  late FTPConnect _ftp;

  FtpRealDatasource.connect({
    required String host,
    required String user,
    required String pass,
    required int port,
    required bool passiveMode,
    required bool useFTPS,
  }) {
    _ftp = FTPConnect(
      host,
      user: user,
      pass: pass,
      port: port,
      securityType: useFTPS ? SecurityType.FTPS : SecurityType.FTP,
    );

    // ⚡ activar/desactivar modo pasivo
    _ftp.setPassiveMode(passiveMode);
  }

  @override
  Future<List<Map<String, dynamic>>> listRemoteFiles(String path) async {
    await _ftp.connect();
    await _ftp.changeDirectory(path);
    final entries = await _ftp.listDirectoryContent();
    await _ftp.disconnect();

    return entries.map((e) => {
      "name": e.name,
      "size": e.size ?? 0,
      "isDir": e.type == FTPEntryType.DIR,
    }).toList();
  }

  @override
  Future<List<String>> listLocalFiles(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) return [];
    return dir.listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toList();
  }

  @override
  Future<void> uploadFile(String localFilePath, String remotePath) async {
    await _ftp.connect();
    await _ftp.changeDirectory(remotePath);
    await _ftp.uploadFile(File(localFilePath));
    await _ftp.disconnect();
  }

  @override
  Future<void> downloadFile(String remoteFileName, String localPath) async {
    await _ftp.connect();
    await _ftp.downloadFile(remoteFileName, File('$localPath/$remoteFileName'));
    await _ftp.disconnect();
  }
}
