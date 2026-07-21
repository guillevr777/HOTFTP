import type { DumpSchedule } from '../../../domain/entities/dump-schedule.js';
import type { DumpScheduleRepository } from '../../../domain/repositories/dump-schedule-repository.js';

export class InMemoryDumpScheduleRepository implements DumpScheduleRepository {
  private readonly schedules: DumpSchedule[] = [];

  async list(ownerId: string): Promise<DumpSchedule[]> {
    return this.schedules
      .filter((schedule) => schedule.ownerId === ownerId)
      .sort((a, b) => {
        const aValue = a.nextRunAt ?? '';
        const bValue = b.nextRunAt ?? '';
        return aValue.localeCompare(bValue);
      });
  }

  async findByProfile(
    ownerId: string,
    profileId: number,
  ): Promise<DumpSchedule | null> {
    return (
      this.schedules.find(
        (schedule) =>
          schedule.ownerId === ownerId && schedule.profileId === profileId,
      ) ?? null
    );
  }

  async save(schedule: DumpSchedule): Promise<DumpSchedule> {
    const nextId = schedule.id ?? this.schedules.length + 1;
    const item = { ...schedule, id: nextId };
    const index = this.schedules.findIndex(
      (existing) =>
        existing.ownerId === schedule.ownerId &&
        existing.profileId === schedule.profileId,
    );
    if (index === -1) {
      this.schedules.unshift(item);
    } else {
      this.schedules[index] = item;
    }
    return item;
  }

  async delete(ownerId: string, id: number): Promise<void> {
    const index = this.schedules.findIndex(
      (schedule) => schedule.ownerId === ownerId && schedule.id === id,
    );
    if (index !== -1) {
      this.schedules.splice(index, 1);
    }
  }
}
