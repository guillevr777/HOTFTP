import type { AppUser } from '../entities/user.js';

export interface AuthRepository {
  login(email: string, password: string): Promise<AppUser>;
}

