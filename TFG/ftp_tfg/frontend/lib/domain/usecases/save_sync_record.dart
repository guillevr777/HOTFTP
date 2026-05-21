import '../entities/ftp_profile.dart';
import '../entities/sync_record.dart';
import '../interfaces/i_save_sync_record_use_case.dart';
import '../repositories/ftp_repository.dart';

class SaveSyncRecord implements ISaveSyncRecordUseCase {
  final FtpRepository repository;

  SaveSyncRecord(this.repository);

  @override
  Future<void> execute(SyncRecord record, FtpProfile profile) =>
      repository.saveSyncRecord(record, profile);
}
