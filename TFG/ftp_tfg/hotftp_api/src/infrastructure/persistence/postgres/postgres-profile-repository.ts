import type { FtpProfile } from '../../../domain/entities/ftp-profile.js';
import type { ProfileRepository } from '../../../domain/repositories/profile-repository.js';
import { HttpError } from '../../../shared/http/http-error.js';
import type { PostgresDatabase } from './postgres-database.js';

type FtpProfileRow = {
  id: number;
  owner_id: string;
  transport_type: 'local' | 'remote';
  name: string;
  host: string;
  port: number;
  username: string;
  password: string;
  use_ftps: boolean;
  passive_mode: boolean;
};

export class PostgresProfileRepository implements ProfileRepository {
  constructor(private readonly database: PostgresDatabase) {}

  async list(ownerId: string): Promise<FtpProfile[]> {
    const result = await this.database.query<FtpProfileRow>(
      `
      SELECT id, owner_id, transport_type, name, host, port, username, password, use_ftps, passive_mode
      FROM ftp_profiles
      WHERE owner_id = $1
      ORDER BY name ASC
      `,
      [ownerId],
    );

    return result.rows.map(this.toDomain);
  }

  async save(profile: FtpProfile): Promise<FtpProfile> {
    if (profile.id == null) {
      const result = await this.database.query<FtpProfileRow>(
        `
        INSERT INTO ftp_profiles (
          owner_id, transport_type, name, host, port, username, password, use_ftps, passive_mode
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING id, owner_id, transport_type, name, host, port, username, password, use_ftps, passive_mode
        `,
        [
          profile.ownerId,
          profile.transportType,
          profile.name,
          profile.host,
          profile.port,
          profile.username,
          profile.password,
          profile.useFTPS,
          profile.passiveMode,
        ],
      );

      const row = result.rows[0];
      if (!row) {
        throw new Error('No se pudo crear el perfil FTP');
      }

      return this.toDomain(row);
    }

    const result = await this.database.query<FtpProfileRow>(
      `
      UPDATE ftp_profiles
      SET transport_type = $1,
          name = $2,
          host = $3,
          port = $4,
          username = $5,
          password = $6,
          use_ftps = $7,
          passive_mode = $8
      WHERE id = $9 AND owner_id = $10
      RETURNING id, owner_id, transport_type, name, host, port, username, password, use_ftps, passive_mode
      `,
      [
        profile.transportType,
        profile.name,
        profile.host,
        profile.port,
        profile.username,
        profile.password,
        profile.useFTPS,
        profile.passiveMode,
        profile.id,
        profile.ownerId,
      ],
    );

    const row = result.rows[0];
    if (!row) {
      throw new HttpError(404, 'Perfil FTP no encontrado', 'profile_not_found');
    }

    return this.toDomain(row);
  }

  async findById(ownerId: string, id: number): Promise<FtpProfile | null> {
    const result = await this.database.query<FtpProfileRow>(
      `
      SELECT id, owner_id, transport_type, name, host, port, username, password, use_ftps, passive_mode
      FROM ftp_profiles
      WHERE owner_id = $1 AND id = $2
      LIMIT 1
      `,
      [ownerId, id],
    );

    return result.rows[0] ? this.toDomain(result.rows[0]) : null;
  }

  async delete(ownerId: string, id: number): Promise<void> {
    await this.database.query(
      `
      DELETE FROM ftp_profiles
      WHERE owner_id = $1 AND id = $2
      `,
      [ownerId, id],
    );
  }

  private toDomain(row: FtpProfileRow): FtpProfile {
    return {
      id: row.id,
      ownerId: row.owner_id,
      transportType: row.transport_type,
      name: row.name,
      host: row.host,
      port: row.port,
      username: row.username,
      password: row.password,
      useFTPS: row.use_ftps,
      passiveMode: row.passive_mode,
    };
  }
}
