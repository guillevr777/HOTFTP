import '../entities/ftp_profile.dart';
import '../entities/sync_conflict.dart';
abstract class IDetectConflictsUseCase {
  Future<List<SyncConflict>> execute(
    String localPath,
    String remotePath,
    FtpProfile profile,
  );
}





