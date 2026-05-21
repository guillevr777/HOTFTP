import '../entities/file_version.dart';
import '../repositories/monitoring_repository.dart';
import '../interfaces/i_get_file_version_history_use_case.dart';

class GetFileVersionHistory implements IGetFileVersionHistoryUseCase {
  final MonitoringRepository repository;

  GetFileVersionHistory(this.repository);

  @override
  Future<List<FileVersion>> execute(
    String ownerId,
    int profileId,
    String filePath, {
    int limit = 20,
  }) {
    return repository.getFileVersionHistory(
      ownerId,
      profileId,
      filePath,
      limit: limit,
    );
  }
}




