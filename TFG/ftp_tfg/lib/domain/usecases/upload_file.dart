import "../entities/ftp_profile.dart";
import "../repositories/ftp_repository.dart";

class UploadFile {
  final FtpRepository repository;
  UploadFile(this.repository);
  Future<void> execute(String localPath, String remotePath, FtpProfile profile) =>
      repository.uploadFile(localPath, remotePath, profile);
}
