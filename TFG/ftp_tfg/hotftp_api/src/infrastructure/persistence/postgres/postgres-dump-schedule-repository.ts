import type { DumpSchedule } from '../../../domain/entities/dump-schedule.js';
import type { DumpScheduleRepository } from '../../../domain/repositories/dump-schedule-repository.js';
import { HttpError } from '../../../shared/http/http-error.js';
import type { PostgresDatabase } from './postgres-database.js';

type DumpScheduleRow = {
  id: number;
  owner_id: string;
  profile_id: number;
  enabled: boolean;
  local_path: string;
  remote_path: string;
  source_side: string;
  transfer_mode: string;
  delete_source_after_copy: boolean;
  interval_value: number;
  interval_unit: string;
  last_run_at: Date | null;
  next_run_at: Date | null;
};

export class PostgresDumpScheduleRepository implements DumpScheduleRepository {
  constructor(private readonly database: PostgresDatabase) {}

  async list(ownerId: string): Promise<DumpSchedule[]> {
    const result = await this.database.query<DumpScheduleRow>(
      `
      SELECT id, owner_id, profile_id, enabled, local_path, remote_path,
             source_side, transfer_mode, delete_source_after_copy,
             interval_value, interval_unit, last_run_at, next_run_at
      FROM dump_schedules
      WHERE owner_id = $1
      ORDER BY next_run_at ASC NULLS LAST, id ASC
      `,
      [ownerId],
    );

    return result.rows.map((row) => this.mapRow(row));
  }

  async findByProfile(
    ownerId: string,
    profileId: number,
  ): Promise<DumpSchedule | null> {
    const result = await this.database.query<DumpScheduleRow>(
      `
      SELECT id, owner_id, profile_id, enabled, local_path, remote_path,
             source_side, transfer_mode, delete_source_after_copy,
             interval_value, interval_unit, last_run_at, next_run_at
      FROM dump_schedules
      WHERE owner_id = $1 AND profile_id = $2
      LIMIT 1
      `,
      [ownerId, profileId],
    );

    return result.rows[0] ? this.mapRow(result.rows[0]) : null;
  }

  async save(schedule: DumpSchedule): Promise<DumpSchedule> {
    const result = await this.database.query<DumpScheduleRow>(
      `
      INSERT INTO dump_schedules (
        owner_id, profile_id, enabled, local_path, remote_path, source_side,
        transfer_mode, delete_source_after_copy, interval_value, interval_unit,
        last_run_at, next_run_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      ON CONFLICT (owner_id, profile_id)
      DO UPDATE SET
        enabled = EXCLUDED.enabled,
        local_path = EXCLUDED.local_path,
        remote_path = EXCLUDED.remote_path,
        source_side = EXCLUDED.source_side,
        transfer_mode = EXCLUDED.transfer_mode,
        delete_source_after_copy = EXCLUDED.delete_source_after_copy,
        interval_value = EXCLUDED.interval_value,
        interval_unit = EXCLUDED.interval_unit,
        last_run_at = EXCLUDED.last_run_at,
        next_run_at = EXCLUDED.next_run_at
      RETURNING id, owner_id, profile_id, enabled, local_path, remote_path,
                source_side, transfer_mode, delete_source_after_copy,
                interval_value, interval_unit, last_run_at, next_run_at
      `,
      [
        schedule.ownerId,
        schedule.profileId,
        schedule.enabled,
        schedule.localPath,
        schedule.remotePath,
        schedule.sourceSide,
        schedule.transferMode,
        schedule.deleteSourceAfterCopy,
        schedule.intervalValue,
        schedule.intervalUnit,
        schedule.lastRunAt ?? null,
        schedule.nextRunAt ?? null,
      ],
    );

    const row = result.rows[0];
    if (!row) {
      throw new Error('No se pudo guardar la tarea programada');
    }
    return this.mapRow(row);
  }

  async delete(ownerId: string, id: number): Promise<void> {
    const result = await this.database.query(
      `
      DELETE FROM dump_schedules
      WHERE owner_id = $1 AND id = $2
      `,
      [ownerId, id],
    );

    if (result.rowCount === 0) {
      throw new HttpError(404, 'Tarea programada no encontrada', 'schedule_not_found');
    }
  }

  private mapRow(row: DumpScheduleRow): DumpSchedule {
    return {
      id: row.id,
      ownerId: row.owner_id,
      profileId: row.profile_id,
      enabled: row.enabled,
      localPath: row.local_path,
      remotePath: row.remote_path,
      sourceSide: row.source_side as DumpSchedule['sourceSide'],
      transferMode: row.transfer_mode as DumpSchedule['transferMode'],
      deleteSourceAfterCopy: row.delete_source_after_copy,
      intervalValue: row.interval_value,
      intervalUnit: row.interval_unit as DumpSchedule['intervalUnit'],
      lastRunAt: row.last_run_at ? row.last_run_at.toISOString() : undefined,
      nextRunAt: row.next_run_at ? row.next_run_at.toISOString() : undefined,
    };
  }
}
