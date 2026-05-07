import '../entities/ftp_profile.dart';
import '../entities/dump_schedule.dart';
import '../entities/local_file.dart';
import '../entities/remote_file.dart';
import '../entities/sync_conflict.dart';
import '../entities/sync_record.dart';

abstract class FtpRepository {
  Future<List<RemoteFile>> getRemoteFiles(String path, FtpProfile profile);
  Future<List<String>> getLocalFiles(String path);
  Future<List<LocalFile>> getLocalFileDetails(String path);
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
  Future<void> deleteRemoteFile(RemoteFile file, FtpProfile profile);
  Future<void> deleteLocalFile(String path);
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
  Future<List<DumpSchedule>> getDumpSchedules(String ownerId);
  Future<DumpSchedule?> getDumpScheduleForProfile(
    String ownerId,
    int profileId,
  );
  Future<int> saveDumpSchedule(DumpSchedule schedule);
  Future<void> deleteDumpSchedule(int id, String ownerId);
}
