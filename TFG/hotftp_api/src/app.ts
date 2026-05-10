import express from 'express';
import cors from 'cors';

import type { AppDependencies } from './config/dependencies.js';
import { createRouter } from './infrastructure/http/routes.js';

export function createApp(dependencies: AppDependencies) {
  const app = express();

  app.use(cors());
  app.use(express.json({ limit: '20mb' }));

  app.get('/health', (_req, res) => {
    res.json({
      status: 'ok',
      service: 'hotftp-api',
      timestamp: new Date().toISOString(),
    });
  });

  app.use('/api/v1', createRouter(dependencies));

  app.use((_req, res) => {
    res.status(404).json({
      error: 'not_found',
      message: 'Endpoint no encontrado',
    });
  });

  return app;
}
