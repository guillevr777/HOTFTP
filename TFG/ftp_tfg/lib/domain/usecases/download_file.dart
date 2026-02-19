import "../entities/ftp_profile.dart";
import "../repositories/ftp_repository.dart";
import "../entities/remote_file.dart";

class DownloadFile {
  final FtpRepository repository;
  DownloadFile(this.repository);
  Future<void> execute(RemoteFile file, String localPath, FtpProfile profile) =>
      repository.downloadFile(file, localPath, profile);
}
