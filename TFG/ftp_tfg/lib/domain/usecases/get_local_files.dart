import '../repositories/ftp_repository.dart';
import '../interfaces/i_get_local_files_use_case.dart';

class GetLocalFiles implements IGetLocalFilesUseCase {
  final FtpRepository repository;

  GetLocalFiles(this.repository);

  @override
  Future<List<String>> execute(String path) => repository.getLocalFiles(path);
}




