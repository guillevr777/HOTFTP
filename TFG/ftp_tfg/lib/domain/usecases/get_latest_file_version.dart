import '../entities/file_version.dart';
import '../repositories/monitoring_repository.dart';
import '../interfaces/i_get_latest_file_version_use_case.dart';

class GetLatestFileVersion implements IGetLatestFileVersionUseCase {
  final MonitoringRepository repository;

  GetLatestFileVersion(this.repository);

  @override
  Future<FileVersion?> execute(
    String ownerId,
    int profileId,
    String filePath,
  ) {
    return repository.getLatestFileVersion(ownerId, profileId, filePath);
  }
}




