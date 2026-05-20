import '../entities/local_file.dart';
import '../interfaces/i_get_local_file_details_use_case.dart';
import '../interfaces/i_get_local_files_use_case.dart';
import '../repositories/ftp_repository.dart';

class GetLocalFiles implements IGetLocalFilesUseCase {
  final FtpRepository repository;

  GetLocalFiles(this.repository);

  @override
  Future<List<String>> execute(String path) => repository.getLocalFiles(path);
}

class GetLocalFileDetails implements IGetLocalFileDetailsUseCase {
  final FtpRepository repository;

  GetLocalFileDetails(this.repository);

  @override
  Future<List<LocalFile>> execute(String path) =>
      repository.getLocalFileDetails(path);
}
