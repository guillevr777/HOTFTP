import '../entities/ftp_profile.dart';
import '../entities/remote_file.dart';
import '../entities/sync_conflict.dart';
import '../entities/sync_record.dart';

abstract class FtpRepository {
  Future<List<RemoteFile>> getRemoteFiles(String path, FtpProfile profile);
  Future<List<String>> getLocalFiles(String path);
  Future<void> uploadFile(
    String localPath,
    String remotePath,
    FtpProfile profile,
  );
  Future<void> downloadFile(
    RemoteFile file,
    String localPath,
    FtpProfile profile,
  );
  Future<String> downloadThumbnail(
    RemoteFile file,
    String remotePath,
    FtpProfile profile,
  );
  Future<List<SyncConflict>> detectConflicts(
    String localPath,
    String remotePath,
    FtpProfile profile,
  );
  Future<List<FtpProfile>> getProfiles(String ownerId);
  Future<int> saveProfile(FtpProfile profile, String ownerId);
  Future<void> deleteProfile(int id, String ownerId);
  Future<bool> testConnection(FtpProfile profile);
  Future<List<SyncRecord>> getSyncHistory(String ownerId);
  Future<void> saveSyncRecord(SyncRecord record);
}
