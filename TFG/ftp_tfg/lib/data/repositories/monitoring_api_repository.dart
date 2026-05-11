import '../../domain/entities/file_version.dart';
import '../../domain/entities/system_alert.dart';
import '../../domain/entities/system_event.dart';
import '../../domain/entities/system_health_summary.dart';
import '../../domain/entities/sync_record.dart';
import '../../domain/repositories/monitoring_repository.dart';
import '../datasources/hotftp_api_client.dart';

class ApiMonitoringRepository implements MonitoringRepository {
  final HotftpApiClient client;

  ApiMonitoringRepository(this.client);

  @override
  Future<void> recordEvent(SystemEvent event) =>
      client.recordEvent(event.toMap());

  @override
  Future<int> createAlert(SystemAlert alert) async {
    final saved = await client.createAlert(alert.toMap());
    return saved['id'] as int? ?? alert.id ?? 0;
  }

  @override
  Future<int> recordFileVersion(FileVersion version) async {
    final saved = await client.recordFileVersion(version.toMap());
    return saved['id'] as int? ?? version.id ?? 0;
  }

  @override
  Future<List<SystemEvent>> getRecentEvents(String ownerId, {int limit = 20}) =>
      client
          .getRecentEvents(ownerId, limit: limit)
          .then((items) => items.map(SystemEvent.fromMap).toList());

  @override
  Future<List<SystemAlert>> getActiveAlerts(String ownerId, {int limit = 10}) =>
      client
          .getActiveAlerts(ownerId, limit: limit)
          .then((items) => items.map(SystemAlert.fromMap).toList());

  @override
  Future<void> recordSync(SyncRecord record) =>
      client.saveSyncRecord(record.toMap());

  @override
  Future<SystemHealthSummary> getHealthSummary(String ownerId) async {
    final summary = await client.getHealthSummary(ownerId);
    return SystemHealthSummary(
      totalProfiles: summary['totalProfiles'] as int? ?? 0,
      totalSyncs: summary['totalSyncs'] as int? ?? 0,
      totalAlerts: summary['totalAlerts'] as int? ?? 0,
      unresolvedAlerts: summary['unresolvedAlerts'] as int? ?? 0,
      errorSyncs: summary['errorSyncs'] as int? ?? 0,
      lastSyncAt: summary['lastSyncAt'] == null
          ? null
          : DateTime.tryParse(summary['lastSyncAt'] as String),
      lastEventAt: summary['lastEventAt'] == null
          ? null
          : DateTime.tryParse(summary['lastEventAt'] as String),
    );
  }

  @override
  Future<List<SyncRecord>> getSyncHistory(String ownerId) => client
      .getSyncHistory(ownerId)
      .then((items) => items.map(SyncRecord.fromMap).toList());

  @override
  Future<List<SyncRecord>> getRecentSyncs(String ownerId, {int limit = 20}) =>
      getSyncHistory(ownerId).then((items) => items.take(limit).toList());

  @override
  Future<List<FileVersion>> getRecentFileVersions(
    String ownerId, {
    int limit = 12,
  }) =>
      client
          .getRecentFileVersions(ownerId, limit: limit)
          .then((items) => items.map(FileVersion.fromMap).toList());

  @override
  Future<FileVersion?> getLatestFileVersion(
    String ownerId,
    int profileId,
    String filePath,
  ) async {
    final version = await client.getLatestFileVersion(
      ownerId: ownerId,
      profileId: profileId,
      filePath: filePath,
    );
    return version == null ? null : FileVersion.fromMap(version);
  }

  @override
  Future<List<FileVersion>> getFileVersionHistory(
    String ownerId,
    int profileId,
    String filePath, {
    int limit = 20,
  }) =>
      client
          .getFileVersionHistory(
            ownerId: ownerId,
            profileId: profileId,
            filePath: filePath,
            limit: limit,
          )
          .then((items) => items.map(FileVersion.fromMap).toList());

  @override
  Future<void> acknowledgeAlert(int alertId, String ownerId) =>
      client.acknowledgeAlert(ownerId: ownerId, alertId: alertId);
}
