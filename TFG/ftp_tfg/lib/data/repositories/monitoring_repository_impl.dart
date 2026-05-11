import '../../domain/entities/file_version.dart';
import '../../domain/entities/system_alert.dart';
import '../../domain/entities/system_event.dart';
import '../../domain/entities/system_health_summary.dart';
import '../../domain/entities/sync_record.dart';
import '../../domain/repositories/monitoring_repository.dart';
import '../local/database_helper.dart';

class MonitoringRepositoryImpl implements MonitoringRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  MonitoringRepositoryImpl();

  @override
  Future<void> recordSync(SyncRecord record) => _db.insertSyncRecord(record);

  @override
  Future<void> recordEvent(SystemEvent event) => _db.insertSystemEvent(event);

  @override
  Future<int> createAlert(SystemAlert alert) => _db.insertSystemAlert(alert);

  @override
  Future<int> recordFileVersion(FileVersion version) =>
      _db.insertFileVersion(version);

  @override
  Future<List<SystemEvent>> getRecentEvents(String ownerId, {int limit = 20}) =>
      _db.getRecentEvents(ownerId, limit: limit);

  @override
  Future<List<SystemAlert>> getActiveAlerts(String ownerId, {int limit = 10}) =>
      _db.getActiveAlerts(ownerId, limit: limit);

  @override
  Future<List<SyncRecord>> getRecentSyncs(String ownerId, {int limit = 20}) =>
      _db.getRecentSyncs(ownerId, limit: limit);

  @override
  Future<List<SyncRecord>> getSyncHistory(String ownerId) =>
      _db.getSyncHistory(ownerId);

  @override
  Future<List<FileVersion>> getRecentFileVersions(
    String ownerId, {
    int limit = 12,
  }) => _db.getRecentFileVersions(ownerId, limit: limit);

  @override
  Future<FileVersion?> getLatestFileVersion(
    String ownerId,
    int profileId,
    String filePath,
  ) => _db.getLatestFileVersion(ownerId, profileId, filePath);

  @override
  Future<List<FileVersion>> getFileVersionHistory(
    String ownerId,
    int profileId,
    String filePath, {
    int limit = 20,
  }) =>
      _db.getFileVersionHistory(ownerId, profileId, filePath, limit: limit);

  @override
  Future<void> acknowledgeAlert(int alertId, String ownerId) =>
      _db.acknowledgeAlert(alertId, ownerId);

  @override
  Future<SystemHealthSummary> getHealthSummary(String ownerId) =>
      _db.getHealthSummary(ownerId);
}



