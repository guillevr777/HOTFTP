import '../interfaces/i_delete_local_file_use_case.dart';
import '../repositories/ftp_repository.dart';

class DeleteLocalFile implements IDeleteLocalFileUseCase {
  final FtpRepository repository;

  DeleteLocalFile(this.repository);

  @override
  Future<void> execute(String path) => repository.deleteLocalFile(path);
}
