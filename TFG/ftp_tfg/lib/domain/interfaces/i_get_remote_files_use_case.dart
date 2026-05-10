import '../entities/ftp_profile.dart';
import '../entities/remote_file.dart';
abstract class IGetRemoteFilesUseCase {
  Future<List<RemoteFile>> execute(String path, FtpProfile profile);
}





