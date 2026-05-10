import type { FtpProfile } from '../../../domain/entities/ftp-profile.js';
import type { RemoteFile } from '../../../domain/entities/remote-file.js';
import type { FtpGateway } from '../../../domain/repositories/ftp-gateway.js';
import type { ProfileRepository } from '../../../domain/repositories/profile-repository.js';
import { HttpError } from '../../../shared/http/http-error.js';

export class ListRemoteFiles {
  constructor(
    private readonly profileRepository: ProfileRepository,
    private readonly ftpGateway: FtpGateway,
  ) {}

  async execute(
    ownerId: string,
    profileId: number,
    path: string,
  ): Promise<RemoteFile[]> {
    const profile = await this.profileRepository.findById(ownerId, profileId);
    if (!profile) {
      throw new HttpError(404, 'Perfil FTP no encontrado', 'profile_not_found');
    }

    return this.ftpGateway.listRemoteFiles(profile as FtpProfile, path);
  }
}
