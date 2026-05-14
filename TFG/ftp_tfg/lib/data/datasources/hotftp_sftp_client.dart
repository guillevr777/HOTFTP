import 'package:dartssh2/dartssh2.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

class HotftpSftpClient {
  Future<bool> testConnection(Map<String, dynamic> config) async {
    final client = await _openClient(config);
    try {
      final sftp = await client.sftp();
      sftp.close();
      return true;
    } catch (_) {
      return false;
    } finally {
      client.close();
      await client.done.catchError((_) {});
    }
  }

  Future<List<Map<String, dynamic>>> listRemoteFiles(
    String path,
    Map<String, dynamic> config,
  ) async {
    final client = await _openClient(config);
    try {
      final sftp = await client.sftp();
      final entries = await sftp.listdir(path);
      sftp.close();
      return entries.map(_toMap).toList(growable: false);
    } finally {
      client.close();
      await client.done.catchError((_) {});
    }
  }

  Future<void> uploadFile(
    String localFilePath,
    String remotePath,
    Map<String, dynamic> config,
  ) async {
    final client = await _openClient(config);
    try {
      final sftp = await client.sftp();
      final fileName = p.basename(localFilePath);
      final targetPath = _joinRemotePath(remotePath, fileName);
      final remoteFile = await sftp.open(
        targetPath,
        mode: SftpFileOpenMode.create |
            SftpFileOpenMode.truncate |
            SftpFileOpenMode.write,
      );
      final bytes = await File(localFilePath).readAsBytes();
      await remoteFile.writeBytes(bytes);
      await remoteFile.close();
      sftp.close();
    } finally {
      client.close();
      await client.done.catchError((_) {});
    }
  }

  Future<void> downloadFileToPath(
    String remoteFileName,
    String remoteDirectory,
    String targetLocalPath,
    Map<String, dynamic> config,
  ) async {
    final client = await _openClient(config);
    try {
      final sftp = await client.sftp();
      final remotePath = _joinRemotePath(remoteDirectory, remoteFileName);
      final output = File(targetLocalPath).openWrite(mode: FileMode.writeOnly);
      await sftp.download(remotePath, output, closeDestination: true);
      sftp.close();
    } finally {
      client.close();
      await client.done.catchError((_) {});
    }
  }

  Future<void> deleteRemoteFile(
    String remoteFileName,
    String remoteDirectory,
    Map<String, dynamic> config,
  ) async {
    final client = await _openClient(config);
    try {
      final sftp = await client.sftp();
      final remotePath = _joinRemotePath(remoteDirectory, remoteFileName);
      await sftp.remove(remotePath);
      sftp.close();
    } finally {
      client.close();
      await client.done.catchError((_) {});
    }
  }

  Future<SSHClient> _openClient(Map<String, dynamic> config) async {
    final host = '${config['host'] ?? ''}'.trim();
    final port = int.tryParse('${config['port'] ?? 22}') ?? 22;
    final user = '${config['username'] ?? ''}';
    final password = '${config['password'] ?? ''}';

    final socket = await SSHSocket.connect(host, port);
    final client = SSHClient(
      socket,
      username: user,
      onPasswordRequest: () => password,
      disableHostkeyVerification: true,
    );
    await client.authenticated;
    return client;
  }

  Map<String, dynamic> _toMap(SftpName entry) {
    final attrs = entry.attr;
    return {
      'name': entry.filename,
      'size': attrs.size ?? 0,
      'isDir': attrs.type == SftpFileType.directory,
      'modifyTime': null,
    };
  }

  String _joinRemotePath(String directory, String name) {
    final normalizedDirectory = directory.trim().isEmpty ? '/' : directory.trim();
    if (normalizedDirectory == '/') return '/$name';
    return '${normalizedDirectory.replaceAll(RegExp(r'/+$'), '')}/$name';
  }
}
