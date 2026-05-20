import '../entities/ftp_profile.dart';
import '../entities/remote_file.dart';
import '../interfaces/i_delete_remote_file_use_case.dart';
import '../repositories/ftp_repository.dart';

class DeleteRemoteFile implements IDeleteRemoteFileUseCase {
  final FtpRepository repository;

  DeleteRemoteFile(this.repository);

  @override
  Future<void> execute(RemoteFile file, FtpProfile profile) =>
      repository.deleteRemoteFile(file, profile);
}
