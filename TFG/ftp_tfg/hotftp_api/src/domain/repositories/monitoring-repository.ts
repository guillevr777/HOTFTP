import type { HealthSummary } from '../entities/health-summary.js';
import type { SyncRecord } from '../entities/sync-record.js';

export interface MonitoringRepository {
  recordSync(record: SyncRecord): Promise<void>;
  getHealthSummary(ownerId: string): Promise<HealthSummary>;
  getSyncHistory(ownerId: string): Promise<SyncRecord[]>;
}

