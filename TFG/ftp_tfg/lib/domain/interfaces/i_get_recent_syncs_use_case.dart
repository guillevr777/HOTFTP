import '../entities/sync_record.dart';
abstract class IGetRecentSyncsUseCase {
  Future<List<SyncRecord>> execute(String ownerId, {int limit});
}





