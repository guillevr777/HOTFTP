import '../entities/sync_action.dart';

abstract class ISyncFolder {
  Future<void> execute(SyncAction action);
}
