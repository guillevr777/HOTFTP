import "../entities/ftp_profile.dart";
import "../repositories/ftp_repository.dart";
import "../entities/remote_file.dart";

class GetRemoteFiles {
  final FtpRepository repository;
  GetRemoteFiles(this.repository);
  Future<List<RemoteFile>> execute(String path, FtpProfile profile) {
    return repository.getRemoteFiles(path, profile);
  }
}
