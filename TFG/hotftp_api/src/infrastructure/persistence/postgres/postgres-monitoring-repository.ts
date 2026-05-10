import type { HealthSummary } from '../../../domain/entities/health-summary.js';
import type { SyncRecord } from '../../../domain/entities/sync-record.js';
import type { MonitoringRepository } from '../../../domain/repositories/monitoring-repository.js';
import type { PostgresDatabase } from './postgres-database.js';

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
    const [totalProfiles, totalSyncs, errorSyncs, lastSyncAt] = await Promise.all([
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
    ]);

    return {
      totalProfiles: totalProfiles ?? 0,
      totalSyncs: totalSyncs ?? 0,
      totalAlerts: 0,
      unresolvedAlerts: 0,
      errorSyncs: errorSyncs ?? 0,
      lastSyncAt: lastSyncAt ? lastSyncAt.toISOString() : undefined,
      lastEventAt: undefined,
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

  private async scalarNumber(query: string, params: unknown[]) {
    const result = await this.database.query<{ value: number }>(query, params);
    return result.rows[0]?.value ?? null;
  }

  private async scalarDate(query: string, params: unknown[]) {
    const result = await this.database.query<{ value: Date }>(query, params);
    const value = result.rows[0]?.value;
    return value ? new Date(value) : null;
  }
}
