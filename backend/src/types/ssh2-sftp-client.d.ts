declare module 'ssh2-sftp-client' {
  import { ReadStream, WriteStream } from 'node:fs';

  interface SftpListEntry {
    name: string;
    type: string;
    size?: number;
    modifyTime?: number | Date | string;
  }

  interface SftpClientOptions {
    host: string;
    port: number;
    username: string;
    password?: string;
  }

  class SftpClient {
    connect(options: SftpClientOptions): Promise<void>;
    list(path: string): Promise<SftpListEntry[]>;
    put(local: string | ReadStream, remotePath: string): Promise<void>;
    get(remotePath: string, destination: string | WriteStream): Promise<void>;
    delete(path: string): Promise<void>;
    end(): Promise<void>;
  }

  export default SftpClient;
}
