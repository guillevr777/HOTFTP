import type { HealthSummary } from '../../../domain/entities/health-summary.js';
import type { SyncRecord } from '../../../domain/entities/sync-record.js';
import type { MonitoringRepository } from '../../../domain/repositories/monitoring-repository.js';

export class InMemoryMonitoringRepository implements MonitoringRepository {
  private readonly syncRecords: SyncRecord[] = [];

  async recordSync(record: SyncRecord): Promise<void> {
    this.syncRecords.unshift(record);
  }

  async getHealthSummary(ownerId: string): Promise<HealthSummary> {
    const records = this.syncRecords.filter((record) => record.ownerId === ownerId);
    const lastSyncAt = records[0]?.date;

    return {
      totalProfiles: 0,
      totalSyncs: records.length,
      totalAlerts: 0,
      unresolvedAlerts: 0,
      errorSyncs: records.filter((record) => record.errorMessage).length,
      lastSyncAt,
      lastEventAt: lastSyncAt,
    };
  }

  async getSyncHistory(ownerId: string): Promise<SyncRecord[]> {
    return this.syncRecords.filter((record) => record.ownerId === ownerId);
  }
}

