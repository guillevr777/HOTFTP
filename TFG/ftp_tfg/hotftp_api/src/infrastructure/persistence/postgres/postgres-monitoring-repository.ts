import type { FileVersion } from '../../../domain/entities/file-version.js';
import type { HealthSummary } from '../../../domain/entities/health-summary.js';
import type { SyncRecord } from '../../../domain/entities/sync-record.js';
import type { SystemAlert } from '../../../domain/entities/system-alert.js';
import type { SystemEvent } from '../../../domain/entities/system-event.js';
import type { MonitoringRepository } from '../../../domain/repositories/monitoring-repository.js';
import type { PostgresDatabase } from './postgres-database.js';

type SystemEventRow = {
  id: number;
  owner_id: string;
  event_type: string;
  severity: string;
  title: string;
  message: string;
  related_profile_id: number | null;
  metadata: string | null;
  created_at: Date;
};

type SystemAlertRow = {
  id: number;
  owner_id: string;
  source: string;
  severity: string;
  title: string;
  message: string;
  related_profile_id: number | null;
  is_read: boolean;
  created_at: Date;
  resolved_at: Date | null;
};

type FileVersionRow = {
  id: number;
  owner_id: string;
  profile_id: number;
  file_path: string;
  file_name: string;
  version_number: number;
  size: number;
  modified_at: Date | null;
  source: string;
  created_at: Date;
};

type SyncRecordRow = {
  id: number;
  owner_id: string;
  profile_id: number;
  date: Date;
  local_path: string;
  remote_path: string;
  mode: string;
  files_transferred: number;
  files_skipped: number;
  error_message: string | null;
};

export class PostgresMonitoringRepository implements MonitoringRepository {
  constructor(private readonly database: PostgresDatabase) {}

  async recordEvent(event: SystemEvent): Promise<void> {
    await this.database.query(
      `
      INSERT INTO system_events (
        owner_id, event_type, severity, title, message,
        related_profile_id, metadata, created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      `,
      [
        event.ownerId,
        event.eventType,
        event.severity,
        event.title,
        event.message,
        event.relatedProfileId ?? null,
        event.metadata ?? null,
        event.createdAt,
      ],
    );
  }

  async createAlert(alert: SystemAlert): Promise<number> {
    const result = await this.database.query<{ id: number }>(
      `
      INSERT INTO system_alerts (
        owner_id, source, severity, title, message,
        related_profile_id, is_read, created_at, resolved_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING id
      `,
      [
        alert.ownerId,
        alert.source,
        alert.severity,
        alert.title,
        alert.message,
        alert.relatedProfileId ?? null,
        alert.isRead,
        alert.createdAt,
        alert.resolvedAt ?? null,
      ],
    );
    return result.rows[0]?.id ?? 0;
  }

  async recordFileVersion(version: FileVersion): Promise<number> {
    const result = await this.database.query<{ id: number }>(
      `
      INSERT INTO file_versions (
        owner_id, profile_id, file_path, file_name, version_number,
        size, modified_at, source, created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      ON CONFLICT (owner_id, profile_id, file_path, version_number)
      DO UPDATE SET
        file_name = EXCLUDED.file_name,
        size = EXCLUDED.size,
        modified_at = EXCLUDED.modified_at,
        source = EXCLUDED.source,
        created_at = EXCLUDED.created_at
      RETURNING id
      `,
      [
        version.ownerId,
        version.profileId,
        version.filePath,
        version.fileName,
        version.versionNumber,
        version.size,
        version.modifiedAt ?? null,
        version.source,
        version.createdAt,
      ],
    );
    return result.rows[0]?.id ?? 0;
  }

  async getRecentEvents(ownerId: string, limit = 20): Promise<SystemEvent[]> {
    const result = await this.database.query<SystemEventRow>(
      `
      SELECT id, owner_id, event_type, severity, title, message,
             related_profile_id, metadata, created_at
      FROM system_events
      WHERE owner_id = $1
      ORDER BY created_at DESC
      LIMIT $2
      `,
      [ownerId, limit],
    );

    return result.rows.map((row) => this.mapEvent(row));
  }

  async getActiveAlerts(ownerId: string, limit = 10): Promise<SystemAlert[]> {
    const result = await this.database.query<SystemAlertRow>(
      `
      SELECT id, owner_id, source, severity, title, message,
             related_profile_id, is_read, created_at, resolved_at
      FROM system_alerts
      WHERE owner_id = $1 AND resolved_at IS NULL
      ORDER BY created_at DESC
      LIMIT $2
      `,
      [ownerId, limit],
    );

    return result.rows.map((row) => this.mapAlert(row));
  }

  async recordSync(record: SyncRecord): Promise<void> {
    await this.database.query(
      `
      INSERT INTO sync_records (
        owner_id, profile_id, date, local_path, remote_path, mode,
        files_transferred, files_skipped, error_message
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      `,
      [
        record.ownerId,
        record.profileId,
        record.date,
        record.localPath,
        record.remotePath,
        record.mode,
        record.filesTransferred,
        record.filesSkipped,
        record.errorMessage ?? null,
      ],
    );
  }

  async getHealthSummary(ownerId: string): Promise<HealthSummary> {
    const [totalProfiles, totalSyncs, errorSyncs, lastSyncAt, lastEventAt] =
      await Promise.all([
        this.scalarNumber(
          'SELECT COUNT(*)::int AS value FROM ftp_profiles WHERE owner_id = $1',
          [ownerId],
        ),
        this.scalarNumber(
          'SELECT COUNT(*)::int AS value FROM sync_records WHERE owner_id = $1',
          [ownerId],
        ),
        this.scalarNumber(
          'SELECT COUNT(*)::int AS value FROM sync_records WHERE owner_id = $1 AND error_message IS NOT NULL',
          [ownerId],
        ),
        this.scalarDate(
          'SELECT date AS value FROM sync_records WHERE owner_id = $1 ORDER BY date DESC LIMIT 1',
          [ownerId],
        ),
        this.scalarDate(
          'SELECT created_at AS value FROM system_events WHERE owner_id = $1 ORDER BY created_at DESC LIMIT 1',
          [ownerId],
        ),
      ]);

    const [totalAlerts, unresolvedAlerts] = await Promise.all([
      this.scalarNumber(
        'SELECT COUNT(*)::int AS value FROM system_alerts WHERE owner_id = $1',
        [ownerId],
      ),
      this.scalarNumber(
        'SELECT COUNT(*)::int AS value FROM system_alerts WHERE owner_id = $1 AND resolved_at IS NULL',
        [ownerId],
      ),
    ]);

    return {
      totalProfiles: totalProfiles ?? 0,
      totalSyncs: totalSyncs ?? 0,
      totalAlerts: totalAlerts ?? 0,
      unresolvedAlerts: unresolvedAlerts ?? 0,
      errorSyncs: errorSyncs ?? 0,
      lastSyncAt: lastSyncAt ? lastSyncAt.toISOString() : undefined,
      lastEventAt: lastEventAt ? lastEventAt.toISOString() : undefined,
    };
  }

  async getSyncHistory(ownerId: string): Promise<SyncRecord[]> {
    const result = await this.database.query<SyncRecordRow>(
      `
      SELECT id, owner_id, profile_id, date, local_path, remote_path, mode,
             files_transferred, files_skipped, error_message
      FROM sync_records
      WHERE owner_id = $1
      ORDER BY date DESC
      LIMIT 100
      `,
      [ownerId],
    );

    return result.rows.map((row) => ({
      id: row.id,
      ownerId: row.owner_id,
      profileId: row.profile_id,
      date: row.date.toISOString(),
      localPath: row.local_path,
      remotePath: row.remote_path,
      mode: row.mode,
      filesTransferred: row.files_transferred,
      filesSkipped: row.files_skipped,
      errorMessage: row.error_message ?? undefined,
    }));
  }

  async getRecentFileVersions(ownerId: string, limit = 12): Promise<FileVersion[]> {
    const result = await this.database.query<FileVersionRow>(
      `
      SELECT id, owner_id, profile_id, file_path, file_name, version_number,
             size, modified_at, source, created_at
      FROM file_versions
      WHERE owner_id = $1
      ORDER BY created_at DESC
      LIMIT $2
      `,
      [ownerId, limit],
    );

    return result.rows.map((row) => this.mapVersion(row));
  }

  async getLatestFileVersion(
    ownerId: string,
    profileId: number,
    filePath: string,
  ): Promise<FileVersion | null> {
    const result = await this.database.query<FileVersionRow>(
      `
      SELECT id, owner_id, profile_id, file_path, file_name, version_number,
             size, modified_at, source, created_at
      FROM file_versions
      WHERE owner_id = $1 AND profile_id = $2 AND file_path = $3
      ORDER BY version_number DESC
      LIMIT 1
      `,
      [ownerId, profileId, filePath],
    );

    return result.rows[0] ? this.mapVersion(result.rows[0]) : null;
  }

  async getFileVersionHistory(
    ownerId: string,
    profileId: number,
    filePath: string,
    limit = 20,
  ): Promise<FileVersion[]> {
    const result = await this.database.query<FileVersionRow>(
      `
      SELECT id, owner_id, profile_id, file_path, file_name, version_number,
             size, modified_at, source, created_at
      FROM file_versions
      WHERE owner_id = $1 AND profile_id = $2 AND file_path = $3
      ORDER BY version_number DESC
      LIMIT $4
      `,
      [ownerId, profileId, filePath, limit],
    );

    return result.rows.map((row) => this.mapVersion(row));
  }

  async acknowledgeAlert(alertId: number, ownerId: string): Promise<void> {
    await this.database.query(
      `
      UPDATE system_alerts
      SET is_read = TRUE, resolved_at = NOW()
      WHERE id = $1 AND owner_id = $2
      `,
      [alertId, ownerId],
    );
  }

  private async scalarNumber(query: string, params: unknown[]) {
    const result = await this.database.query<{ value: number }>(query, params);
    return result.rows[0]?.value ?? null;
  }

  private async scalarDate(query: string, params: unknown[]) {
    const result = await this.database.query<{ value: Date }>(query, params);
    const value = result.rows[0]?.value;
    return value ? new Date(value) : null;
  }

  private mapEvent(row: SystemEventRow): SystemEvent {
    return {
      id: row.id,
      ownerId: row.owner_id,
      eventType: row.event_type,
      severity: row.severity as SystemEvent['severity'],
      title: row.title,
      message: row.message,
      relatedProfileId: row.related_profile_id ?? undefined,
      metadata: row.metadata ?? undefined,
      createdAt: row.created_at.toISOString(),
    };
  }

  private mapAlert(row: SystemAlertRow): SystemAlert {
    return {
      id: row.id,
      ownerId: row.owner_id,
      source: row.source,
      severity: row.severity as SystemAlert['severity'],
      title: row.title,
      message: row.message,
      relatedProfileId: row.related_profile_id ?? undefined,
      isRead: row.is_read,
      createdAt: row.created_at.toISOString(),
      resolvedAt: row.resolved_at ? row.resolved_at.toISOString() : undefined,
    };
  }

  private mapVersion(row: FileVersionRow): FileVersion {
    return {
      id: row.id,
      ownerId: row.owner_id,
      profileId: row.profile_id,
      filePath: row.file_path,
      fileName: row.file_name,
      versionNumber: row.version_number,
      size: row.size,
      modifiedAt: row.modified_at ? row.modified_at.toISOString() : undefined,
      source: row.source,
      createdAt: row.created_at.toISOString(),
    };
  }
}
