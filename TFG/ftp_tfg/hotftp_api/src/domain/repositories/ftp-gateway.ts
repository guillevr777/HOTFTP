import type { FtpProfile } from '../entities/ftp-profile.js';
import type { RemoteFile } from '../entities/remote-file.js';

export interface FtpGateway {
  listRemoteFiles(profile: FtpProfile, path: string): Promise<RemoteFile[]>;
}

