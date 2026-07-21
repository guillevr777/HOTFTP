import '../entities/sync_record.dart';
import '../repositories/ftp_repository.dart';
import '../interfaces/i_get_sync_history_use_case.dart';

class GetSyncHistory implements IGetSyncHistoryUseCase {
  final FtpRepository repository;

  GetSyncHistory(this.repository);

  @override
  Future<List<SyncRecord>> execute(String ownerId) =>
      repository.getSyncHistory(ownerId);
}




