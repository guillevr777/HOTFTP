import '../entities/sync_conflict.dart';

abstract class IDetectConflicts {
  Future<List<SyncConflict>> execute(
    String localPath,
    String remotePath,
  );
}
