import type { FileVersion } from '../entities/file-version.js';
import type { HealthSummary } from '../entities/health-summary.js';
import type { SyncRecord } from '../entities/sync-record.js';
import type { SystemAlert } from '../entities/system-alert.js';
import type { SystemEvent } from '../entities/system-event.js';

export interface MonitoringRepository {
  recordEvent(event: SystemEvent): Promise<void>;
  createAlert(alert: SystemAlert): Promise<number>;
  recordFileVersion(version: FileVersion): Promise<number>;
  getRecentEvents(ownerId: string, limit?: number): Promise<SystemEvent[]>;
  getActiveAlerts(ownerId: string, limit?: number): Promise<SystemAlert[]>;
  recordSync(record: SyncRecord): Promise<void>;
  getHealthSummary(ownerId: string): Promise<HealthSummary>;
  getSyncHistory(ownerId: string): Promise<SyncRecord[]>;
  getRecentFileVersions(ownerId: string, limit?: number): Promise<FileVersion[]>;
  getLatestFileVersion(
    ownerId: string,
    profileId: number,
    filePath: string,
  ): Promise<FileVersion | null>;
  getFileVersionHistory(
    ownerId: string,
    profileId: number,
    filePath: string,
    limit?: number,
  ): Promise<FileVersion[]>;
  acknowledgeAlert(alertId: number, ownerId: string): Promise<void>;
}

