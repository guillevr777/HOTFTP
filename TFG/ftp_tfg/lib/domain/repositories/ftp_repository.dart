import '../entities/ftp_profile.dart';
import '../entities/remote_file.dart';

abstract class FtpRepository {
  Future<bool> connect(FtpProfile profile);
  Future<List<RemoteFile>> getRemoteFiles(String path);

  // Para sincronización
  Future<List<String>> getLocalFiles(String localPath);
  Future<void> uploadFile(String localFile, String remotePath);
  Future<void> downloadFile(RemoteFile remoteFile, String localPath);
  Future<void> syncBidirectional(String localPath, String remotePath);
}
