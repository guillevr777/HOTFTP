import type { FtpProfile } from '../entities/ftp-profile.js';

export interface ProfileRepository {
  list(ownerId: string): Promise<FtpProfile[]>;
  save(profile: FtpProfile): Promise<FtpProfile>;
  findById(ownerId: string, id: number): Promise<FtpProfile | null>;
  delete(ownerId: string, id: number): Promise<void>;
}
