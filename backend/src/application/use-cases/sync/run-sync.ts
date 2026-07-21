import type { FtpGateway } from '../../../domain/repositories/ftp-gateway.js';
import type { MonitoringRepository } from '../../../domain/repositories/monitoring-repository.js';
import type { ProfileRepository } from '../../../domain/repositories/profile-repository.js';
import type { SyncRecord } from '../../../domain/entities/sync-record.js';
import { HttpError } from '../../../shared/http/http-error.js';

export interface RunSyncInput {
  ownerId: string;
  profileId: number;
  remotePath: string;
}

export class RunSync {
  constructor(
    private readonly profileRepository: ProfileRepository,
    private readonly ftpGateway: FtpGateway,
    private readonly monitoringRepository: MonitoringRepository,
  ) {}

  async execute(input: RunSyncInput) {
    const profile = await this.profileRepository.findById(
      input.ownerId,
      input.profileId,
    );
    if (!profile) {
      throw new HttpError(404, 'Perfil FTP no encontrado', 'profile_not_found');
    }

    const remoteFiles = await this.ftpGateway.listRemoteFiles(
      profile,
      input.remotePath,
    );

    const record: SyncRecord = {
      ownerId: input.ownerId,
      profileId: input.profileId,
      date: new Date().toISOString(),
      localPath: '',
      remotePath: input.remotePath,
      mode: 'api-run',
      filesTransferred: remoteFiles.filter((file) => !file.isDirectory).length,
      filesSkipped: 0,
    };

    await this.monitoringRepository.recordSync(record);

    return {
      profileId: input.profileId,
      remotePath: input.remotePath,
      filesFound: remoteFiles.length,
      filesTransferred: record.filesTransferred,
      filesSkipped: record.filesSkipped,
    };
  }
}
