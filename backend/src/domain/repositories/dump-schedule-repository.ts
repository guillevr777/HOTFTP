import type { DumpSchedule } from '../entities/dump-schedule.js';

export interface DumpScheduleRepository {
  list(ownerId: string): Promise<DumpSchedule[]>;
  findByProfile(ownerId: string, profileId: number): Promise<DumpSchedule | null>;
  save(schedule: DumpSchedule): Promise<DumpSchedule>;
  delete(ownerId: string, id: number): Promise<void>;
}
