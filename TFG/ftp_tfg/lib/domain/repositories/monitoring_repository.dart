import '../entities/system_alert.dart';
import '../entities/file_version.dart';
import '../entities/system_event.dart';
import '../entities/system_health_summary.dart';
import '../entities/sync_record.dart';

abstract class MonitoringRepository {
  Future<void> recordEvent(SystemEvent event);
  Future<int> createAlert(SystemAlert alert);
  Future<int> recordFileVersion(FileVersion version);
  Future<List<SystemEvent>> getRecentEvents(String ownerId, {int limit = 20});
  Future<List<SystemAlert>> getActiveAlerts(String ownerId, {int limit = 10});
  Future<List<SyncRecord>> getRecentSyncs(String ownerId, {int limit = 20});
  Future<List<FileVersion>> getRecentFileVersions(
    String ownerId, {
    int limit = 12,
  });
  Future<FileVersion?> getLatestFileVersion(
    String ownerId,
    int profileId,
    String filePath,
  );
  Future<List<FileVersion>> getFileVersionHistory(
    String ownerId,
    int profileId,
    String filePath, {
    int limit = 20,
  });
  Future<void> acknowledgeAlert(int alertId, String ownerId);
  Future<SystemHealthSummary> getHealthSummary(String ownerId);
}



