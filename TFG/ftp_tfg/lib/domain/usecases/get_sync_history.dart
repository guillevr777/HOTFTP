import '../repositories/ftp_repository.dart';
import '../entities/sync_record.dart';

class GetSyncHistory {
  final FtpRepository repository;
  GetSyncHistory(this.repository);
  Future<List<SyncRecord>> execute() => repository.getSyncHistory();
}
