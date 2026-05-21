import '../entities/ftp_profile.dart';
import '../entities/remote_file.dart';
abstract class IDownloadThumbnailUseCase {
  Future<String> execute(
    RemoteFile file,
    String remotePath,
    FtpProfile profile,
  );
}





