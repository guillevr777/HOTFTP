import type { FtpProfile } from '../../../domain/entities/ftp-profile.js';
import type { ProfileRepository } from '../../../domain/repositories/profile-repository.js';

export class InMemoryProfileRepository implements ProfileRepository {
  private nextId = 2;
  private profiles: FtpProfile[] = [
    {
      id: 1,
      ownerId: 'demo-owner',
      transportType: 'remote',
      name: 'Servidor demo',
      host: '127.0.0.1',
      port: 21,
      username: 'demo',
      password: 'demo',
      useFTPS: false,
      passiveMode: true,
    },
  ];

  async list(ownerId: string): Promise<FtpProfile[]> {
    return this.profiles.filter((profile) => profile.ownerId === ownerId);
  }

  async save(profile: FtpProfile): Promise<FtpProfile> {
    const index = this.profiles.findIndex(
      (item) => item.id === profile.id && item.ownerId === profile.ownerId,
    );
    if (index >= 0) {
      this.profiles[index] = profile;
      return profile;
    }

    const next = profile.id ? profile : { ...profile, id: this.nextId++ };
    this.profiles.push(next);
    return next;
  }

  async findById(ownerId: string, id: number): Promise<FtpProfile | null> {
    return (
      this.profiles.find(
        (profile) => profile.ownerId === ownerId && profile.id === id,
      ) ?? null
    );
  }

  async delete(ownerId: string, id: number): Promise<void> {
    this.profiles = this.profiles.filter(
      (profile) => !(profile.ownerId === ownerId && profile.id === id),
    );
  }
}
