export type SystemAlertSeverity = 'info' | 'warning' | 'error';

export interface SystemAlert {
  id?: number;
  ownerId: string;
  source: string;
  severity: SystemAlertSeverity;
  title: string;
  message: string;
  relatedProfileId?: number;
  isRead: boolean;
  createdAt: string;
  resolvedAt?: string;
}
