import { Client } from 'basic-ftp';

import type { FtpProfile } from '../../domain/entities/ftp-profile.js';
import type { RemoteFile } from '../../domain/entities/remote-file.js';
import type { FtpGateway } from '../../domain/repositories/ftp-gateway.js';

export interface FtpConnectionConfig {
  host: string;
  port: number;
  user: string;
  password: string;
  secure: boolean;
}

export class BasicFtpGateway implements FtpGateway {
  constructor(private readonly fallbackConfig: FtpConnectionConfig) {}

  async listRemoteFiles(profile: FtpProfile, path: string): Promise<RemoteFile[]> {
    const client = new Client();
    client.ftp.verbose = false;

    const config: FtpConnectionConfig = {
      host: profile.host || this.fallbackConfig.host,
      port: profile.port || this.fallbackConfig.port,
      user: profile.username || this.fallbackConfig.user,
      password: profile.password || this.fallbackConfig.password,
      secure: profile.useFTPS || this.fallbackConfig.secure,
    };

    try {
      await client.access(config);
      const entries = await client.list(path || '/');
      return entries.map((entry) => ({
        name: entry.name,
        path: path ? `${path.replace(/\/$/, '')}/${entry.name}` : `/${entry.name}`,
        size: entry.size ?? 0,
        isDirectory: entry.isDirectory,
        modifiedAt: entry.modifiedAt?.toISOString(),
      }));
    } finally {
      client.close();
    }
  }
}
