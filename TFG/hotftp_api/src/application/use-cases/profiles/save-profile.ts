import type { FtpProfile } from '../../../domain/entities/ftp-profile.js';
import type { ProfileRepository } from '../../../domain/repositories/profile-repository.js';

export class SaveProfile {
  constructor(private readonly profileRepository: ProfileRepository) {}

  execute(profile: FtpProfile): Promise<FtpProfile> {
    return this.profileRepository.save(profile);
  }
}

