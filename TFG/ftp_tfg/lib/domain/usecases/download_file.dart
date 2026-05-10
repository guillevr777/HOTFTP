import "../entities/ftp_profile.dart";
import "../entities/remote_file.dart";
import "../repositories/ftp_repository.dart";
import '../interfaces/i_download_file_use_case.dart';

class DownloadFile implements IDownloadFileUseCase {
  final FtpRepository repository;
  DownloadFile(this.repository);
  @override
  Future<void> execute(RemoteFile file, String localPath, FtpProfile profile) =>
      repository.downloadFile(file, localPath, profile);
}




