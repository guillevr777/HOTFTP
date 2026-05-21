import type { FtpProfile } from '../entities/ftp-profile.js';
import type { RemoteFile } from '../entities/remote-file.js';

export interface FtpGateway {
  listRemoteFiles(profile: FtpProfile, path: string): Promise<RemoteFile[]>;
  uploadFile(
    localFilePath: string,
    remotePath: string,
    profile: FtpProfile,
  ): Promise<void>;
  createRemoteDirectory(
    remotePath: string,
    profile: FtpProfile,
  ): Promise<void>;
  downloadFileToPath(
    remoteFileName: string,
    remoteDirectory: string,
    targetLocalPath: string,
    profile: FtpProfile,
  ): Promise<void>;
  deleteRemoteFile(
    remoteFileName: string,
    remoteDirectory: string,
    profile: FtpProfile,
  ): Promise<void>;
  testConnection(profile: FtpProfile): Promise<boolean>;
}


