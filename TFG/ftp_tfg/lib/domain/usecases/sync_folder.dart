import '../entities/sync_action.dart';
import '../interfaces/i_sync_folder.dart';
import '../repositories/ftp_repository.dart';

class SyncFolder implements ISyncFolder {
  final FtpRepository repository;

  SyncFolder(this.repository);

  @override
  Future<void> execute(SyncAction action) async {
    switch (action.type) {
      case SyncType.upload:
        final files = await repository.getLocalFiles(action.localPath);
        for (var f in files) {
          await repository.uploadFile(f, action.remotePath);
        }
        break;

      case SyncType.download:
        final remoteFiles = await repository.getRemoteFiles(action.remotePath);
        for (var f in remoteFiles) {
          await repository.downloadFile(f, action.localPath);
        }
        break;

      case SyncType.bidirectional:
        await repository.syncBidirectional(action.localPath, action.remotePath);
        break;
    }
  }
}
