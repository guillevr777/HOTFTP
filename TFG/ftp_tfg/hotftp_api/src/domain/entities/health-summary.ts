export interface HealthSummary {
  totalProfiles: number;
  totalSyncs: number;
  totalAlerts: number;
  unresolvedAlerts: number;
  errorSyncs: number;
  lastSyncAt?: string;
  lastEventAt?: string;
}

