export type SystemEventSeverity = 'info' | 'success' | 'warning' | 'error';

export interface SystemEvent {
  id?: number;
  ownerId: string;
  eventType: string;
  severity: SystemEventSeverity;
  title: string;
  message: string;
  relatedProfileId?: number;
  metadata?: string;
  createdAt: string;
}
