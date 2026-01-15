import '../repositories/ftp_repository.dart';
import '../entities/sync_conflict.dart';

class DetectConflicts {
  final FtpRepository repository;

  DetectConflicts(this.repository);

  Future<List<SyncConflict>> execute(String localPath, String remotePath) {
    return repository.detectConflicts(localPath, remotePath);
  }
}
