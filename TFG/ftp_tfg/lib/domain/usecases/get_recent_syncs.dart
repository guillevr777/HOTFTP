import '../entities/sync_record.dart';
import '../repositories/monitoring_repository.dart';
import '../interfaces/i_get_recent_syncs_use_case.dart';

class GetRecentSyncs implements IGetRecentSyncsUseCase {
  final MonitoringRepository repository;

  GetRecentSyncs(this.repository);

  @override
  Future<List<SyncRecord>> execute(String ownerId, {int limit = 20}) =>
      repository.getRecentSyncs(ownerId, limit: limit);
}




