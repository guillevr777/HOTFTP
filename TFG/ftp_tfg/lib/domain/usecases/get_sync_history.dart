import '../entities/sync_record.dart';
import '../repositories/ftp_repository.dart';

class GetSyncHistory {
  final FtpRepository repository;

  GetSyncHistory(this.repository);

  Future<List<SyncRecord>> execute(String ownerId) =>
      repository.getSyncHistory(ownerId);
}
