import "../entities/ftp_profile.dart";
import "../repositories/ftp_repository.dart";
import "../entities/sync_conflict.dart";

class DetectConflicts {
  final FtpRepository repository;
  DetectConflicts(this.repository);
  Future<List<SyncConflict>> execute(String localPath, String remotePath, FtpProfile profile) {
    return repository.detectConflicts(localPath, remotePath, profile);
  }
}
