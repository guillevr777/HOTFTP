import '../entities/remote_file.dart';
import '../entities/sync_conflict.dart';

abstract class FtpRepository {
  Future<List<RemoteFile>> getRemoteFiles(String path);
  Future<List<String>> getLocalFiles(String path);
  Future<void> uploadFile(String localPath, String remotePath);
  Future<void> downloadFile(RemoteFile file, String localPath);
  Future<List<SyncConflict>> detectConflicts(String localPath, String remotePath);
}
