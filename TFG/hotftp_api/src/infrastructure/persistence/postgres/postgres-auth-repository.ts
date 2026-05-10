import { createHash } from 'node:crypto';

import type { AppUser } from '../../../domain/entities/user.js';
import type { AuthRepository } from '../../../domain/repositories/auth-repository.js';
import { HttpError } from '../../../shared/http/http-error.js';
import type { PostgresDatabase } from './postgres-database.js';

type ApiUserRow = {
  id: string;
  email: string;
  display_name: string;
  provider_ids: string[] | null;
  password_hash: string;
};

export class PostgresAuthRepository implements AuthRepository {
  constructor(private readonly database: PostgresDatabase) {}

  async login(email: string, password: string): Promise<AppUser> {
    const normalizedEmail = email.trim().toLowerCase();
    const passwordHash = createHash('sha256').update(password).digest('hex');
    const result = await this.database.query<ApiUserRow>(
      `
      SELECT id, email, display_name, provider_ids, password_hash
      FROM api_users
      WHERE email = $1
      LIMIT 1
      `,
      [normalizedEmail],
    );

    const row = result.rows[0];
    if (!row || row.password_hash !== passwordHash) {
      throw new HttpError(401, 'Credenciales invalidas', 'invalid_credentials');
    }

    return {
      id: row.id,
      email: row.email,
      displayName: row.display_name,
      providerIds: row.provider_ids ?? [],
    };
  }
}

