import "../entities/ftp_profile.dart";
import "../entities/sync_conflict.dart";
import "../repositories/ftp_repository.dart";
import '../interfaces/i_detect_conflicts_use_case.dart';

class DetectConflicts implements IDetectConflictsUseCase {
  final FtpRepository repository;
  DetectConflicts(this.repository);
  @override
  Future<List<SyncConflict>> execute(
    String localPath,
    String remotePath,
    FtpProfile profile,
  ) {
    return repository.detectConflicts(localPath, remotePath, profile);
  }
}




