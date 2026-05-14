import type { FtpProfile } from '../../../domain/entities/ftp-profile.js';
import type { ProfileRepository } from '../../../domain/repositories/profile-repository.js';
import { resolveTransportType } from '../../../domain/services/connection-route.js';
import { HttpError } from '../../../shared/http/http-error.js';
import type { PostgresDatabase } from './postgres-database.js';

type FtpProfileRow = {
  id: number;
  owner_id: string;
  transport_type: string;
  protocol: string;
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
      SELECT id, owner_id, transport_type, protocol, name, host, port, username, password, use_ftps, passive_mode
      FROM ftp_profiles
      WHERE owner_id = $1
      ORDER BY name ASC
      `,
      [ownerId],
    );

    return result.rows.map(this.toDomain);
  }

  async save(profile: FtpProfile): Promise<FtpProfile> {
    const normalized = {
      ...profile,
      transportType: resolveTransportType(profile.host),
    };

    if (profile.id == null) {
      const result = await this.database.query<FtpProfileRow>(
        `
        INSERT INTO ftp_profiles (
          owner_id, transport_type, protocol, name, host, port, username, password, use_ftps, passive_mode
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING id, owner_id, transport_type, protocol, name, host, port, username, password, use_ftps, passive_mode
        `,
        [
          normalized.ownerId,
          normalized.transportType,
          normalized.protocol,
          normalized.name,
          normalized.host,
          normalized.port,
          normalized.username,
          normalized.password,
          normalized.protocol === 'ftps',
          normalized.passiveMode,
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
          protocol = $2,
          name = $3,
          host = $4,
          port = $5,
          username = $6,
          password = $7,
          use_ftps = $8,
          passive_mode = $9
      WHERE id = $10 AND owner_id = $11
      RETURNING id, owner_id, transport_type, protocol, name, host, port, username, password, use_ftps, passive_mode
      `,
      [
        normalized.transportType,
        normalized.protocol,
        normalized.name,
        normalized.host,
        normalized.port,
        normalized.username,
        normalized.password,
        normalized.protocol === 'ftps',
        normalized.passiveMode,
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
      SELECT id, owner_id, transport_type, protocol, name, host, port, username, password, use_ftps, passive_mode
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
      transportType:
        row.transport_type === 'remote' || row.transport_type === 'api'
          ? 'api'
          : 'direct',
      protocol:
        row.protocol === 'sftp' || row.protocol === 'ftps'
          ? row.protocol
          : 'ftp',
      name: row.name,
      host: row.host,
      port: row.port,
      username: row.username,
      password: row.password,
      passiveMode: row.passive_mode,
    };
  }
}
