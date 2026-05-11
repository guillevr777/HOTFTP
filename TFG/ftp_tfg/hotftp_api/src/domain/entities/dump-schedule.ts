export type DumpSourceSide = 'local' | 'remote';
export type DumpTransferMode = 'oneWay' | 'syncBoth';
export type DumpIntervalUnit = 'hours' | 'days';

export interface DumpSchedule {
  id?: number;
  ownerId: string;
  profileId: number;
  enabled: boolean;
  localPath: string;
  remotePath: string;
  sourceSide: DumpSourceSide;
  transferMode: DumpTransferMode;
  deleteSourceAfterCopy: boolean;
  intervalValue: number;
  intervalUnit: DumpIntervalUnit;
  lastRunAt?: string;
  nextRunAt?: string;
}
