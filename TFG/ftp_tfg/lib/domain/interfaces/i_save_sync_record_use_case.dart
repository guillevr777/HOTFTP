import '../entities/sync_record.dart';
abstract class ISaveSyncRecordUseCase {
  Future<void> execute(SyncRecord record);
}





