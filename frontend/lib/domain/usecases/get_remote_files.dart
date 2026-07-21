import "../entities/ftp_profile.dart";
import "../entities/remote_file.dart";
import "../repositories/ftp_repository.dart";
import '../interfaces/i_get_remote_files_use_case.dart';

class GetRemoteFiles implements IGetRemoteFilesUseCase {
  final FtpRepository repository;
  GetRemoteFiles(this.repository);
  @override
  Future<List<RemoteFile>> execute(String path, FtpProfile profile) {
    return repository.getRemoteFiles(path, profile);
  }
}




