import type { SyncRecord } from '../../../domain/entities/sync-record.js';
import type { MonitoringRepository } from '../../../domain/repositories/monitoring-repository.js';

export class GetSyncHistory {
  constructor(private readonly monitoringRepository: MonitoringRepository) {}

  execute(ownerId: string): Promise<SyncRecord[]> {
    return this.monitoringRepository.getSyncHistory(ownerId);
  }
}

