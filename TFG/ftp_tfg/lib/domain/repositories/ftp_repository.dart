import 'package:ftp_tfg/domain/entities/ftp_profile.dart';
import 'package:ftp_tfg/domain/entities/remote_file.dart';

abstract class FtpRepository {
  Future<bool> connect(FtpProfile profile);
  Future<List<RemoteFile>> getRemoteFiles(String path);
  Future<void> uploadFile(String localPath, String remotePath);
  Future<void> downloadFile(String remotePath, String localPath);
}
