import '../entities/remote_file.dart';
import '../interfaces/i_get_remote_files.dart';
import '../repositories/ftp_repository.dart';

class GetRemoteFiles implements IGetRemoteFiles {
  final FtpRepository repository;

  GetRemoteFiles(this.repository);

  @override
  Future<List<RemoteFile>> execute(String path) {
    return repository.getRemoteFiles(path);
  }
}
