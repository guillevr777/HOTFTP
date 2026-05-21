export interface FileVersion {
  id?: number;
  ownerId: string;
  profileId: number;
  filePath: string;
  fileName: string;
  versionNumber: number;
  size: number;
  modifiedAt?: string;
  source: string;
  createdAt: string;
}
