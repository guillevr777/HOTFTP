import '../entities/sync_record.dart';
import '../repositories/ftp_repository.dart';
import '../interfaces/i_save_sync_record_use_case.dart';

class SaveSyncRecord implements ISaveSyncRecordUseCase {
  final FtpRepository repository;

  SaveSyncRecord(this.repository);

  @override
  Future<void> execute(SyncRecord record) => repository.saveSyncRecord(record);
}




