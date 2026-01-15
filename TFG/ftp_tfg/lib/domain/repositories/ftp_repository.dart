import '../entities/ftp_profile.dart';
import '../entities/remote_file.dart';

abstract class FtpRepository {
  Future<bool> connect(FtpProfile profile);
  Future<List<RemoteFile>> getRemoteFiles(String path);
}
