import type { AppUser } from '../../../domain/entities/user.js';
import type { AuthRepository } from '../../../domain/repositories/auth-repository.js';

export class LoginUser {
  constructor(private readonly authRepository: AuthRepository) {}

  execute(email: string, password: string): Promise<AppUser> {
    return this.authRepository.login(email, password);
  }
}

