export interface SyncRecord {
  id?: number;
  ownerId: string;
  profileId: number;
  date: string;
  localPath: string;
  remotePath: string;
  mode: string;
  filesTransferred: number;
  filesSkipped: number;
  errorMessage?: string;
}
