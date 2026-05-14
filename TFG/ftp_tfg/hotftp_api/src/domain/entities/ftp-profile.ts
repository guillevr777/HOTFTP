export type FtpTransportType = 'direct' | 'api';
export type FtpProtocolType = 'ftp' | 'sftp' | 'ftps';

export interface FtpProfile {
  id?: number;
  ownerId: string;
  transportType: FtpTransportType;
  protocol: FtpProtocolType;
  name: string;
  host: string;
  port: number;
  username: string;
  password: string;
  passiveMode: boolean;
}
