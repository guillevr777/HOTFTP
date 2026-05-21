import '../entities/ftp_profile.dart';
import '../entities/remote_file.dart';
import '../repositories/ftp_repository.dart';
import '../interfaces/i_download_thumbnail_use_case.dart';

class DownloadThumbnail implements IDownloadThumbnailUseCase {
  final FtpRepository repository;

  DownloadThumbnail(this.repository);

  @override
  Future<String> execute(
    RemoteFile file,
    String remotePath,
    FtpProfile profile,
  ) {
    return repository.downloadThumbnail(file, remotePath, profile);
  }
}




