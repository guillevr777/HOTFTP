export type FtpTransportType = 'local' | 'remote';

export interface FtpProfile {
  id?: number;
  ownerId: string;
  transportType: FtpTransportType;
  name: string;
  host: string;
  port: number;
  username: string;
  password: string;
  useFTPS: boolean;
  passiveMode: boolean;
}
