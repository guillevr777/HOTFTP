import type { AppUser } from '../../../domain/entities/user.js';
import type { AuthRepository } from '../../../domain/repositories/auth-repository.js';
import { randomUUID } from 'node:crypto';

export class InMemoryAuthRepository implements AuthRepository {
  async login(email: string, _password: string): Promise<AppUser> {
    const normalizedEmail = email.trim().toLowerCase();
    return {
      id: randomUUID(),
      email: normalizedEmail,
      displayName: normalizedEmail.split('@')[0] || 'Usuario',
      providerIds: ['password'],
    };
  }
}
