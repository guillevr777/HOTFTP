import type { HealthSummary } from '../../../domain/entities/health-summary.js';
import type { MonitoringRepository } from '../../../domain/repositories/monitoring-repository.js';
import type { ProfileRepository } from '../../../domain/repositories/profile-repository.js';

export class GetHealthSummary {
  constructor(
    private readonly profileRepository: ProfileRepository,
    private readonly monitoringRepository: MonitoringRepository,
  ) {}

  async execute(ownerId: string): Promise<HealthSummary> {
    const [summary, profiles] = await Promise.all([
      this.monitoringRepository.getHealthSummary(ownerId),
      this.profileRepository.list(ownerId),
    ]);

    return {
      ...summary,
      totalProfiles: profiles.length,
    };
  }
}

