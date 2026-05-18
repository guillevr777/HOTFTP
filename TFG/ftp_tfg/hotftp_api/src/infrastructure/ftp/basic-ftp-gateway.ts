import { Client } from 'basic-ftp';
import { createReadStream } from 'node:fs';
import SftpClient from 'ssh2-sftp-client';

import type { FtpProfile } from '../../domain/entities/ftp-profile.js';
import type { RemoteFile } from '../../domain/entities/remote-file.js';
import type { FtpGateway } from '../../domain/repositories/ftp-gateway.js';

export interface FtpConnectionConfig {
  host: string;
  port: number;
  user: string;
  password: string;
  secure: boolean | 'implicit';
}

export class BasicFtpGateway implements FtpGateway {
  constructor(private readonly fallbackConfig: FtpConnectionConfig) {}

  async listRemoteFiles(profile: FtpProfile, path: string): Promise<RemoteFile[]> {
    if (profile.protocol === 'sftp') {
      return this.listRemoteFilesSftp(profile, path);
    }

    const client = new Client();
    client.ftp.verbose = false;

    try {
      await client.access(this.toConfig(profile));
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

  async uploadFile(
    localFilePath: string,
    remotePath: string,
    profile: FtpProfile,
  ): Promise<void> {
    if (profile.protocol === 'sftp') {
      return this.uploadFileSftp(localFilePath, remotePath, profile);
    }

    const client = new Client();
    client.ftp.verbose = false;
    try {
      await client.access(this.toConfig(profile));
      await client.cd(remotePath || '/');
      await client.uploadFrom(createReadStream(localFilePath), localFilePath.split(/[\\/]/).pop() ?? 'upload.bin');
    } finally {
      client.close();
    }
  }

  async downloadFileToPath(
    remoteFileName: string,
    remoteDirectory: string,
    targetLocalPath: string,
    profile: FtpProfile,
  ): Promise<void> {
    if (profile.protocol === 'sftp') {
      return this.downloadFileToPathSftp(
        remoteFileName,
        remoteDirectory,
        targetLocalPath,
        profile,
      );
    }

    const client = new Client();
    client.ftp.verbose = false;
    try {
      await client.access(this.toConfig(profile));
      await client.cd(remoteDirectory || '/');
      await client.downloadTo(targetLocalPath, remoteFileName);
    } finally {
      client.close();
    }
  }

  async deleteRemoteFile(
    remoteFileName: string,
    remoteDirectory: string,
    profile: FtpProfile,
  ): Promise<void> {
    if (profile.protocol === 'sftp') {
      return this.deleteRemoteFileSftp(
        remoteFileName,
        remoteDirectory,
        profile,
      );
    }

    const client = new Client();
    client.ftp.verbose = false;
    try {
      await client.access(this.toConfig(profile));
      await client.cd(remoteDirectory || '/');
      await client.remove(remoteFileName);
    } finally {
      client.close();
    }
  }

  async testConnection(profile: FtpProfile): Promise<boolean> {
    if (profile.protocol === 'sftp') {
      const client = new SftpClient();
      try {
        await client.connect(this.toSftpConfig(profile));
        return true;
      } catch {
        return false;
      } finally {
        await client.end().catch(() => undefined);
      }
    }

    const client = new Client();
    client.ftp.verbose = false;
    try {
      await client.access(this.toConfig(profile));
      return true;
    } catch {
      return false;
    } finally {
      client.close();
    }
  }

  private toConfig(profile: FtpProfile): FtpConnectionConfig {
    const useImplicitFtps = profile.protocol === 'ftps' && profile.port === 990;
    return {
      host: profile.host || this.fallbackConfig.host,
      port: profile.port || this.fallbackConfig.port,
      user: profile.username || this.fallbackConfig.user,
      password: profile.password || this.fallbackConfig.password,
      secure: profile.protocol === 'ftps'
        ? (useImplicitFtps ? 'implicit' : true)
        : this.fallbackConfig.secure,
    };
  }

  private toSftpConfig(profile: FtpProfile) {
    return {
      host: profile.host || this.fallbackConfig.host,
      port: profile.port || 22,
      username: profile.username || this.fallbackConfig.user,
      password: profile.password || this.fallbackConfig.password,
    };
  }

  private async listRemoteFilesSftp(
    profile: FtpProfile,
    path: string,
  ): Promise<RemoteFile[]> {
    const client = new SftpClient();
    try {
      await client.connect(this.toSftpConfig(profile));
      const entries = await client.list(path || '/');
      return entries.map((entry: any) => ({
        name: entry.name,
        path: path ? `${path.replace(/\/$/, '')}/${entry.name}` : `/${entry.name}`,
        size: entry.size ?? 0,
        isDirectory: entry.type === 'd' || entry.type === 'directory',
        modifiedAt: this.toDateString(entry.modifyTime),
      }));
    } finally {
      await client.end().catch(() => undefined);
    }
  }

  private async uploadFileSftp(
    localFilePath: string,
    remotePath: string,
    profile: FtpProfile,
  ): Promise<void> {
    const client = new SftpClient();
    try {
      await client.connect(this.toSftpConfig(profile));
      const remoteDirectory = remotePath || '/';
      const remoteFilePath = this.joinRemotePath(
        remoteDirectory,
        localFilePath.split(/[\\/]/).pop() ?? 'upload.bin',
      );
      await client.put(localFilePath, remoteFilePath);
    } finally {
      await client.end().catch(() => undefined);
    }
  }

  private async downloadFileToPathSftp(
    remoteFileName: string,
    remoteDirectory: string,
    targetLocalPath: string,
    profile: FtpProfile,
  ): Promise<void> {
    const client = new SftpClient();
    try {
      await client.connect(this.toSftpConfig(profile));
      const remoteFilePath = this.joinRemotePath(remoteDirectory || '/', remoteFileName);
      await client.get(remoteFilePath, targetLocalPath);
    } finally {
      await client.end().catch(() => undefined);
    }
  }

  private async deleteRemoteFileSftp(
    remoteFileName: string,
    remoteDirectory: string,
    profile: FtpProfile,
  ): Promise<void> {
    const client = new SftpClient();
    try {
      await client.connect(this.toSftpConfig(profile));
      const remoteFilePath = this.joinRemotePath(remoteDirectory || '/', remoteFileName);
      await client.delete(remoteFilePath);
    } finally {
      await client.end().catch(() => undefined);
    }
  }

  private joinRemotePath(directory: string, name: string) {
    const normalizedDirectory = directory.replace(/\/+$/, '') || '/';
    return normalizedDirectory === '/' ? `/${name}` : `${normalizedDirectory}/${name}`;
  }

  private toDateString(value: unknown): string | undefined {
    if (value instanceof Date) {
      return value.toISOString();
    }
    if (typeof value === 'number' && Number.isFinite(value)) {
      return new Date(value * 1000).toISOString();
    }
    if (typeof value === 'string' && value) {
      const asNumber = Number(value);
      if (!Number.isNaN(asNumber)) {
        return new Date(asNumber * 1000).toISOString();
      }
      const parsed = new Date(value);
      return Number.isNaN(parsed.getTime()) ? undefined : parsed.toISOString();
    }
    return undefined;
  }
}
