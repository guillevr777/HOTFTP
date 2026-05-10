import type { FtpProfile } from '../../../domain/entities/ftp-profile.js';
import type { ProfileRepository } from '../../../domain/repositories/profile-repository.js';
import { HttpError } from '../../../shared/http/http-error.js';
import type { PostgresDatabase } from './postgres-database.js';

type FtpProfileRow = {
  id: number;
  owner_id: string;
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
      SELECT id, owner_id, name, host, port, username, password, use_ftps, passive_mode
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
          owner_id, name, host, port, username, password, use_ftps, passive_mode
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING id, owner_id, name, host, port, username, password, use_ftps, passive_mode
        `,
        [
          profile.ownerId,
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
      SET name = $1,
          host = $2,
          port = $3,
          username = $4,
          password = $5,
          use_ftps = $6,
          passive_mode = $7
      WHERE id = $8 AND owner_id = $9
      RETURNING id, owner_id, name, host, port, username, password, use_ftps, passive_mode
      `,
      [
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
      SELECT id, owner_id, name, host, port, username, password, use_ftps, passive_mode
      FROM ftp_profiles
      WHERE owner_id = $1 AND id = $2
      LIMIT 1
      `,
      [ownerId, id],
    );

    return result.rows[0] ? this.toDomain(result.rows[0]) : null;
  }

  private toDomain(row: FtpProfileRow): FtpProfile {
    return {
      id: row.id,
      ownerId: row.owner_id,
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
