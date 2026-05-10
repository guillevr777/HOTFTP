export interface RemoteFile {
  name: string;
  path: string;
  size: number;
  isDirectory: boolean;
  modifiedAt?: string;
}

