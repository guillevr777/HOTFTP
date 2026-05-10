import type { AppEnv } from './env.js';
import type { AuthRepository } from '../domain/repositories/auth-repository.js';
import type { MonitoringRepository } from '../domain/repositories/monitoring-repository.js';
import type { ProfileRepository } from '../domain/repositories/profile-repository.js';
import { InMemoryAuthRepository } from '../infrastructure/persistence/in-memory/auth-repository.js';
import { InMemoryMonitoringRepository } from '../infrastructure/persistence/in-memory/monitoring-repository.js';
import { InMemoryProfileRepository } from '../infrastructure/persistence/in-memory/profile-repository.js';
import { PostgresDatabase } from '../infrastructure/persistence/postgres/postgres-database.js';
import { PostgresAuthRepository } from '../infrastructure/persistence/postgres/postgres-auth-repository.js';
import { PostgresMonitoringRepository } from '../infrastructure/persistence/postgres/postgres-monitoring-repository.js';
import { PostgresProfileRepository } from '../infrastructure/persistence/postgres/postgres-profile-repository.js';
import { BasicFtpGateway } from '../infrastructure/ftp/basic-ftp-gateway.js';
import { LoginUser } from '../application/use-cases/auth/login-user.js';
import { ListProfiles } from '../application/use-cases/profiles/list-profiles.js';
import { SaveProfile } from '../application/use-cases/profiles/save-profile.js';
import { ListRemoteFiles } from '../application/use-cases/files/list-remote-files.js';
import { GetSyncHistory } from '../application/use-cases/sync/get-sync-history.js';
import { RunSync } from '../application/use-cases/sync/run-sync.js';
import { GetHealthSummary } from '../application/use-cases/monitoring/get-health-summary.js';

type DependencyBundle = {
  authRepository: AuthRepository;
  profileRepository: ProfileRepository;
  monitoringRepository: MonitoringRepository;
  ftpGateway: BasicFtpGateway;
  loginUser: LoginUser;
  listProfiles: ListProfiles;
  saveProfile: SaveProfile;
  listRemoteFiles: ListRemoteFiles;
  getSyncHistory: GetSyncHistory;
  runSync: RunSync;
  getHealthSummary: GetHealthSummary;
};

export async function createDependencies(env: AppEnv): Promise<DependencyBundle> {
  const ftpGateway = new BasicFtpGateway(env.ftp);

  if (!env.databaseUrl) {
    const authRepository = new InMemoryAuthRepository();
    const profileRepository = new InMemoryProfileRepository();
    const monitoringRepository = new InMemoryMonitoringRepository();

    return {
      authRepository,
      profileRepository,
      monitoringRepository,
      ftpGateway,
      loginUser: new LoginUser(authRepository),
      listProfiles: new ListProfiles(profileRepository),
      saveProfile: new SaveProfile(profileRepository),
      listRemoteFiles: new ListRemoteFiles(profileRepository, ftpGateway),
      getSyncHistory: new GetSyncHistory(monitoringRepository),
      runSync: new RunSync(profileRepository, ftpGateway, monitoringRepository),
      getHealthSummary: new GetHealthSummary(
        profileRepository,
        monitoringRepository,
      ),
    };
  }

  return createPostgresDependencies(env, ftpGateway);
}

async function createPostgresDependencies(
  env: AppEnv,
  ftpGateway: BasicFtpGateway,
) : Promise<DependencyBundle> {
  const database = new PostgresDatabase({
    connectionString: env.databaseUrl!,
    ssl: env.databaseSsl,
    demoUserEmail: env.demoUserEmail,
    demoUserPassword: env.demoUserPassword,
    demoUserDisplayName: env.demoUserDisplayName,
  });
  await database.initialize();

  const authRepository = new PostgresAuthRepository(database);
  const profileRepository = new PostgresProfileRepository(database);
  const monitoringRepository = new PostgresMonitoringRepository(database);

  return {
    authRepository,
    profileRepository,
    monitoringRepository,
    ftpGateway,
    loginUser: new LoginUser(authRepository),
    listProfiles: new ListProfiles(profileRepository),
    saveProfile: new SaveProfile(profileRepository),
    listRemoteFiles: new ListRemoteFiles(profileRepository, ftpGateway),
    getSyncHistory: new GetSyncHistory(monitoringRepository),
    runSync: new RunSync(profileRepository, ftpGateway, monitoringRepository),
    getHealthSummary: new GetHealthSummary(
      profileRepository,
      monitoringRepository,
    ),
  };
}

export type AppDependencies = DependencyBundle;
