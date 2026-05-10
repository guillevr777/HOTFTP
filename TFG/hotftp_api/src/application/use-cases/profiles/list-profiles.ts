import type { FtpProfile } from '../../../domain/entities/ftp-profile.js';
import type { ProfileRepository } from '../../../domain/repositories/profile-repository.js';

export class ListProfiles {
  constructor(private readonly profileRepository: ProfileRepository) {}

  execute(ownerId: string): Promise<FtpProfile[]> {
    return this.profileRepository.list(ownerId);
  }
}

