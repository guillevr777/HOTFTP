import '../entities/ftp_profile.dart';
import '../entities/remote_file.dart';
abstract class IDownloadFileUseCase {
  Future<void> execute(RemoteFile file, String localPath, FtpProfile profile);
}





