export interface FtpProfile {
  id?: number;
  ownerId: string;
  name: string;
  host: string;
  port: number;
  username: string;
  password: string;
  useFTPS: boolean;
  passiveMode: boolean;
}
