import type { ProfileRepository } from '../../../domain/repositories/profile-repository.js';

export class DeleteProfile {
  constructor(private readonly profileRepository: ProfileRepository) {}

  execute(ownerId: string, id: number): Promise<void> {
    return this.profileRepository.delete(ownerId, id);
  }
}

