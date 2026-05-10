import '../entities/ftp_profile.dart';
abstract class IUploadFileUseCase {
  Future<void> execute(String localPath, String remotePath, FtpProfile profile);
}





