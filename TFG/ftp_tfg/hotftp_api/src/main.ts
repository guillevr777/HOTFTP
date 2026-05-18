import 'dotenv/config';

import { createApp } from './app.js';
import { loadEnv } from './config/env.js';
import { createDependencies } from './config/dependencies.js';

async function bootstrap() {
  const env = loadEnv(process.env);
  const dependencies = await createDependencies(env);
  const app = createApp(dependencies);

  app.listen(env.port, '0.0.0.0');
}

void bootstrap();
