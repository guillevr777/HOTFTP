export interface AppEnv {
  port: number;
  databaseUrl?: string;
  databaseSsl: boolean;
  demoUserEmail: string;
  demoUserPassword: string;
  demoUserDisplayName: string;
  ftp: {
    host: string;
    port: number;
    user: string;
    password: string;
    secure: boolean;
  };
}

export function loadEnv(source: NodeJS.ProcessEnv): AppEnv {
  return {
    port: Number(source.PORT ?? 3000),
    databaseUrl: source.DATABASE_URL,
    databaseSsl: String(source.DATABASE_SSL ?? 'false').toLowerCase() === 'true',
    demoUserEmail: source.API_DEMO_EMAIL ?? 'demo@hotftp.local',
    demoUserPassword: source.API_DEMO_PASSWORD ?? 'demo123',
    demoUserDisplayName: source.API_DEMO_DISPLAY_NAME ?? 'HOTFTP Demo',
    ftp: {
      host: source.FTP_HOST ?? '127.0.0.1',
      port: Number(source.FTP_PORT ?? 21),
      user: source.FTP_USER ?? 'anonymous',
      password: source.FTP_PASSWORD ?? '',
      secure: String(source.FTP_SECURE ?? 'false').toLowerCase() === 'true',
    },
  };
}
