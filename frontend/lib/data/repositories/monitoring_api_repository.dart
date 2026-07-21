import '../../domain/entities/file_version.dart';
import '../../domain/entities/system_alert.dart';
import '../../domain/entities/system_event.dart';
import '../../domain/entities/system_health_summary.dart';
import '../../domain/entities/sync_record.dart';
import '../../domain/repositories/monitoring_repository.dart';
import '../local/database_helper.dart';
import '../datasources/hotftp_api_client.dart';

class ApiMonitoringRepository implements MonitoringRepository {
  final HotftpApiClient client;
  final DatabaseHelper _localDb = DatabaseHelper.instance;

  ApiMonitoringRepository(this.client);

  @override
  Future<void> recordEvent(SystemEvent event) async {
    await _localDb.insertSystemEvent(event);
    try {
      await client.recordEvent(event.toMap());
    } catch (_) {
      // Si la API no responde, conservamos la actividad en la base local.
    }
  }

  @override
  Future<int> createAlert(SystemAlert alert) async {
    final localId = await _localDb.insertSystemAlert(alert);
    try {
      final saved = await client.createAlert(alert.toMap());
      return saved['id'] as int? ?? localId;
    } catch (_) {
      return localId;
    }
  }

  @override
  Future<int> recordFileVersion(FileVersion version) async {
    final localId = await _localDb.insertFileVersion(version);
    try {
      final saved = await client.recordFileVersion(version.toMap());
      return saved['id'] as int? ?? localId;
    } catch (_) {
      return localId;
    }
  }

  @override
  Future<List<SystemEvent>> getRecentEvents(String ownerId, {int limit = 20}) async {
    try {
      final remoteEvents = await client.getRecentEvents(ownerId, limit: limit);
      final mapped = remoteEvents.map(SystemEvent.fromMap).toList();
      for (final event in mapped) {
        await _localDb.insertSystemEvent(event);
      }
      return mapped;
    } catch (_) {
      return _localDb.getRecentEvents(ownerId, limit: limit);
    }
  }

  @override
  Future<List<SystemAlert>> getActiveAlerts(String ownerId, {int limit = 10}) async {
    try {
      final remoteAlerts = await client.getActiveAlerts(ownerId, limit: limit);
      final mapped = remoteAlerts.map(SystemAlert.fromMap).toList();
      for (final alert in mapped) {
        await _localDb.insertSystemAlert(alert);
      }
      return mapped;
    } catch (_) {
      return _localDb.getActiveAlerts(ownerId, limit: limit);
    }
  }

  @override
  Future<void> recordSync(SyncRecord record) async {
    await _localDb.insertSyncRecord(record);
    try {
      await client.saveSyncRecord(record.toMap());
    } catch (_) {
      // Conservamos el historial local aunque falle la sincronización remota.
    }
  }

  @override
  Future<SystemHealthSummary> getHealthSummary(String ownerId) async {
    try {
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
    } catch (_) {
      final profiles = await _localDb.getProfiles(ownerId);
      final syncs = await _localDb.getSyncHistory(ownerId);
      final events = await _localDb.getRecentEvents(ownerId, limit: 500);
      final alerts = await _localDb.getActiveAlerts(ownerId, limit: 500);
      return SystemHealthSummary(
        totalProfiles: profiles.length,
        totalSyncs: syncs.length,
        totalAlerts: alerts.length,
        unresolvedAlerts: alerts.where((alert) => alert.resolvedAt == null).length,
        errorSyncs: syncs.where((record) => record.errorMessage != null).length,
        lastSyncAt: syncs.isEmpty ? null : syncs.first.date,
        lastEventAt: events.isEmpty ? null : events.first.createdAt,
      );
    }
  }

  @override
  Future<List<SyncRecord>> getSyncHistory(String ownerId) async {
    try {
      final remoteSyncs = await client.getSyncHistory(ownerId);
      final mapped = remoteSyncs.map(SyncRecord.fromMap).toList();
      for (final record in mapped) {
        await _localDb.insertSyncRecord(record);
      }
      return mapped;
    } catch (_) {
      return _localDb.getSyncHistory(ownerId);
    }
  }

  @override
  Future<List<SyncRecord>> getRecentSyncs(String ownerId, {int limit = 20}) async {
    final items = await getSyncHistory(ownerId);
    return items.take(limit).toList();
  }

  @override
  Future<List<FileVersion>> getRecentFileVersions(
    String ownerId, {
    int limit = 12,
  }) async {
    try {
      final remoteVersions = await client.getRecentFileVersions(ownerId, limit: limit);
      final mapped = remoteVersions.map(FileVersion.fromMap).toList();
      for (final version in mapped) {
        await _localDb.insertFileVersion(version);
      }
      return mapped;
    } catch (_) {
      return _localDb.getRecentFileVersions(ownerId, limit: limit);
    }
  }

  @override
  Future<FileVersion?> getLatestFileVersion(
    String ownerId,
    int profileId,
    String filePath,
  ) async {
    try {
      final remoteVersion = await client.getLatestFileVersion(
        ownerId: ownerId,
        profileId: profileId,
        filePath: filePath,
      );
      final mapped = remoteVersion == null ? null : FileVersion.fromMap(remoteVersion);
      if (mapped != null) {
        await _localDb.insertFileVersion(mapped);
      }
      return mapped;
    } catch (_) {
      return _localDb.getLatestFileVersion(ownerId, profileId, filePath);
    }
  }

  @override
  Future<List<FileVersion>> getFileVersionHistory(
    String ownerId,
    int profileId,
    String filePath, {
    int limit = 20,
  }) async {
    try {
      final remoteVersions = await client.getFileVersionHistory(
        ownerId: ownerId,
        profileId: profileId,
        filePath: filePath,
        limit: limit,
      );
      final mapped = remoteVersions.map(FileVersion.fromMap).toList();
      for (final version in mapped) {
        await _localDb.insertFileVersion(version);
      }
      return mapped;
    } catch (_) {
      return _localDb.getFileVersionHistory(
        ownerId,
        profileId,
        filePath,
        limit: limit,
      );
    }
  }

  @override
  Future<void> acknowledgeAlert(int alertId, String ownerId) =>
      _acknowledgeAlert(alertId, ownerId);

  Future<void> _acknowledgeAlert(int alertId, String ownerId) async {
    await _localDb.acknowledgeAlert(alertId, ownerId);
    try {
      await client.acknowledgeAlert(ownerId: ownerId, alertId: alertId);
    } catch (_) {
      // Si el backend no responde, al menos queda resuelto en local.
    }
  }
}
