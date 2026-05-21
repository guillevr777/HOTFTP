import '../entities/file_version.dart';
import '../repositories/monitoring_repository.dart';
import '../interfaces/i_get_recent_file_versions_use_case.dart';

class GetRecentFileVersions implements IGetRecentFileVersionsUseCase {
  final MonitoringRepository repository;

  GetRecentFileVersions(this.repository);

  @override
  Future<List<FileVersion>> execute(String ownerId, {int limit = 12}) =>
      repository.getRecentFileVersions(ownerId, limit: limit);
}




