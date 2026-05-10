import '../entities/ftp_profile.dart';
import '../entities/remote_file.dart';
abstract class IDeleteRemoteFileUseCase {
  Future<void> execute(RemoteFile file, FtpProfile profile);
}





