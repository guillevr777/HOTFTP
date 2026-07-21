import '../entities/sync_record.dart';
abstract class IGetSyncHistoryUseCase {
  Future<List<SyncRecord>> execute(String ownerId);
}





