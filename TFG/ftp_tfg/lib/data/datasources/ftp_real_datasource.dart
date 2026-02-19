import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ftpconnect/ftpconnect.dart';
import '../interfaces/ftp_datasource.dart';

class FtpRealDatasource implements FtpDatasource {
  FtpRealDatasource();

  FTPConnect _createClient(Map<String, dynamic> config) {
    String host = config['host'] ?? '';
    final port = config['port'] ?? 21;
    final user = config['username'] ?? '';
    final useFTPS = config['useFTPS'] == true;
    final passive = config['passiveMode'] ?? true;

    // Fix connection from Android Emulator to Host Localhost
    if (Platform.isAndroid && (host == '127.0.0.1' || host == 'localhost')) {
      debugPrint("HOTFTP: Remapping $host to 10.0.2.2 for Android Emulator");
      host = '10.0.2.2';
    }

    debugPrint(
      "HOTFTP: _createClient - Host: $host, Port: $port, User: $user, FTPS: $useFTPS, Passive: $passive",
    );
    final ftp = FTPConnect(
      host,
      user: user,
      pass: config['password'] ?? '',
      port: port,
      securityType: useFTPS ? SecurityType.ftps : SecurityType.ftp,
    );
    ftp.transferMode = passive ? TransferMode.passive : TransferMode.active;
    return ftp;
  }

  @override
  Future<bool> testConnection(Map<String, dynamic> profile) async {
    final ftp = _createClient(profile);
    try {
      debugPrint("HOTFTP: testConnection - Attempting connect()");
      await ftp.connect();
      debugPrint("HOTFTP: testConnection - Connected, now disconnecting");
      await ftp.disconnect();
      return true;
    } catch (e) {
      debugPrint("HOTFTP: Connection test failed (Type: ${e.runtimeType}): $e");
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listRemoteFiles(
    String path,
    Map<String, dynamic> config,
  ) async {
    final ftp = _createClient(config);
    try {
      debugPrint(
        "HOTFTP: listRemoteFiles - Attempting connect() to path: $path",
      );
      await ftp.connect();
      debugPrint(
        "HOTFTP: listRemoteFiles - Connected. Changing directory to: $path",
      );
      await ftp.changeDirectory(path);
      debugPrint("HOTFTP: listRemoteFiles - Listing directory content");
      List<FTPEntry> entries;
      try {
        debugPrint(
          "HOTFTP: listRemoteFiles - Requesting server features (FEAT)",
        );
        final featResponse = await ftp.sendCustomCommand("FEAT");
        debugPrint(
          "HOTFTP: listRemoteFiles - Server features: ${featResponse.message}",
        );

        try {
          entries = await ftp.listDirectoryContent();
        } catch (e) {
          if (e.toString().contains('500')) {
            debugPrint(
              "HOTFTP: listDirectoryContent failed with 500. Attempting fallback with LIST command...",
            );
            ftp.listCommand = ListCommand.list;
            entries = await ftp.listDirectoryContent();
          } else {
            rethrow;
          }
        }
      } catch (e) {
        debugPrint("HOTFTP: Error listing files: $e");
        rethrow;
      }
      debugPrint(
        "HOTFTP: listRemoteFiles - Found ${entries.length} entries. Disconnecting.",
      );
      await ftp.disconnect();
      return entries
          .map(
            (e) => {
              "name": e.name,
              "size": e.size ?? 0,
              "isDir": e.type == FTPEntryType.dir,
            },
          )
          .toList();
    } catch (e) {
      debugPrint("HOTFTP: Error listing files (Type: ${e.runtimeType}): $e");
      try {
        await ftp.disconnect();
      } catch (_) {}
      rethrow;
    }
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
  Future<void> uploadFile(
    String localFilePath,
    String remotePath,
    Map<String, dynamic> config,
  ) async {
    final ftp = _createClient(config);
    try {
      await ftp.connect();
      await ftp.changeDirectory(remotePath);
      await ftp.uploadFile(File(localFilePath));
      await ftp.disconnect();
    } catch (e) {
      debugPrint("HOTFTP: Error uploading file: $e");
      await ftp.disconnect();
      rethrow;
    }
  }

  @override
  Future<void> downloadFile(
    String remoteFileName,
    String localPath,
    Map<String, dynamic> config,
  ) async {
    // Note: This logic assumes path is '/' for backward compatibility or is managed elsewhere.
    // For general use, downloadFileToPath should be used.
    return downloadFileToPath(
      remoteFileName,
      "/",
      "$localPath/$remoteFileName",
      config,
    );
  }

  @override
  Future<void> downloadFileToPath(
    String remoteFileName,
    String remoteDirectory,
    String targetLocalPath,
    Map<String, dynamic> config,
  ) async {
    final ftp = _createClient(config);
    try {
      await ftp.connect();
      debugPrint(
        "HOTFTP: downloadFileToPath - Requested dir: $remoteDirectory",
      );
      final changed = await ftp.changeDirectory(remoteDirectory);
      final current = await ftp.currentDirectory();
      debugPrint(
        "HOTFTP: downloadFileToPath - Changed: $changed, Current dir is now: $current",
      );

      await ftp.downloadFile(remoteFileName, File(targetLocalPath));
      await ftp.disconnect();
    } catch (e) {
      debugPrint(
        "HOTFTP: Error downloading file $remoteFileName from $remoteDirectory to $targetLocalPath: $e",
      );
      await ftp.disconnect();
      rethrow;
    }
  }
}
