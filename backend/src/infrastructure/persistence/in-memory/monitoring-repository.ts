import type { FileVersion } from '../../../domain/entities/file-version.js';
import type { HealthSummary } from '../../../domain/entities/health-summary.js';
import type { SyncRecord } from '../../../domain/entities/sync-record.js';
import type { SystemAlert } from '../../../domain/entities/system-alert.js';
import type { SystemEvent } from '../../../domain/entities/system-event.js';
import type { MonitoringRepository } from '../../../domain/repositories/monitoring-repository.js';

export class InMemoryMonitoringRepository implements MonitoringRepository {
  private readonly events: SystemEvent[] = [];
  private readonly alerts: SystemAlert[] = [];
  private readonly versions: FileVersion[] = [];
  private readonly syncRecords: SyncRecord[] = [];

  async recordEvent(event: SystemEvent): Promise<void> {
    this.events.unshift(event);
  }

  async createAlert(alert: SystemAlert): Promise<number> {
    const id = alert.id ?? this.alerts.length + 1;
    this.alerts.unshift({ ...alert, id });
    return id;
  }

  async recordFileVersion(version: FileVersion): Promise<number> {
    const id = version.id ?? this.versions.length + 1;
    this.versions.unshift({ ...version, id });
    return id;
  }

  async getRecentEvents(ownerId: string, limit = 20): Promise<SystemEvent[]> {
    return this.events.filter((event) => event.ownerId === ownerId).slice(0, limit);
  }

  async getActiveAlerts(ownerId: string, limit = 10): Promise<SystemAlert[]> {
    return this.alerts
      .filter((alert) => alert.ownerId === ownerId && !alert.resolvedAt)
      .slice(0, limit);
  }

  async recordSync(record: SyncRecord): Promise<void> {
    this.syncRecords.unshift(record);
  }

  async getHealthSummary(ownerId: string): Promise<HealthSummary> {
    const records = this.syncRecords.filter((record) => record.ownerId === ownerId);
    const lastSyncAt = records[0]?.date;
    const ownerAlerts = this.alerts.filter((alert) => alert.ownerId === ownerId);
    const ownerEvents = this.events.filter((event) => event.ownerId === ownerId);

    return {
      totalProfiles: 0,
      totalSyncs: records.length,
      totalAlerts: ownerAlerts.length,
      unresolvedAlerts: ownerAlerts.filter((alert) => !alert.resolvedAt).length,
      errorSyncs: records.filter((record) => record.errorMessage).length,
      lastSyncAt,
      lastEventAt: ownerEvents[0]?.createdAt ?? lastSyncAt,
    };
  }

  async getSyncHistory(ownerId: string): Promise<SyncRecord[]> {
    return this.syncRecords.filter((record) => record.ownerId === ownerId);
  }

  async getRecentFileVersions(ownerId: string, limit = 12): Promise<FileVersion[]> {
    return this.versions
      .filter((version) => version.ownerId === ownerId)
      .slice(0, limit);
  }

  async getLatestFileVersion(
    ownerId: string,
    profileId: number,
    filePath: string,
  ): Promise<FileVersion | null> {
    return (
      this.versions.find(
        (version) =>
          version.ownerId === ownerId &&
          version.profileId === profileId &&
          version.filePath === filePath,
      ) ?? null
    );
  }

  async getFileVersionHistory(
    ownerId: string,
    profileId: number,
    filePath: string,
    limit = 20,
  ): Promise<FileVersion[]> {
    return this.versions
      .filter(
        (version) =>
          version.ownerId === ownerId &&
          version.profileId === profileId &&
          version.filePath === filePath,
      )
      .slice(0, limit);
  }

  async acknowledgeAlert(alertId: number, ownerId: string): Promise<void> {
    const alert = this.alerts.find(
      (item) => item.id === alertId && item.ownerId === ownerId,
    );
    if (alert) {
      alert.isRead = true;
      alert.resolvedAt = new Date().toISOString();
    }
  }
}

