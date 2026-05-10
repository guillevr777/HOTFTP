import { Router } from 'express';
import type { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';

import type { AppDependencies } from '../../config/dependencies.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { HttpError } from '../../shared/http/http-error.js';
import { loginSchema, profileSchema, syncRunSchema } from './schemas.js';

export function createRouter(deps: AppDependencies) {
  const router = Router();

  router.post(
    '/auth/login',
    asyncHandler(async (req, res) => {
      const { email, password } = loginSchema.parse(req.body);
      const user = await deps.loginUser.execute(email, password);
      res.json(user);
    }),
  );

  router.get(
    '/profiles',
    asyncHandler(async (req, res) => {
      const ownerId = String(req.query.ownerId ?? 'demo-owner');
      const profiles = await deps.listProfiles.execute(ownerId);
      res.json(profiles);
    }),
  );

  router.post(
    '/profiles',
    asyncHandler(async (req, res) => {
      const saved = await deps.saveProfile.execute(profileSchema.parse(req.body));
      res.status(201).json(saved);
    }),
  );

  router.get(
    '/files/remote',
    asyncHandler(async (req, res) => {
      const ownerId = String(req.query.ownerId ?? '');
      const profileId = Number(req.query.profileId ?? '');
      const path = String(req.query.path ?? '/');

      if (!ownerId || Number.isNaN(profileId)) {
        throw new HttpError(400, 'ownerId y profileId son obligatorios', 'validation_error');
      }

      const files = await deps.listRemoteFiles.execute(ownerId, profileId, path);
      res.json(files);
    }),
  );

  router.post(
    '/sync/run',
    asyncHandler(async (req, res) => {
      const result = await deps.runSync.execute(syncRunSchema.parse(req.body));

      res.json(result);
    }),
  );

  router.get(
    '/monitoring/summary',
    asyncHandler(async (req, res) => {
      const ownerId = String(req.query.ownerId ?? 'demo-owner');
      const summary = await deps.getHealthSummary.execute(ownerId);
      res.json(summary);
    }),
  );

  router.get(
    '/sync/history',
    asyncHandler(async (req, res) => {
      const ownerId = String(req.query.ownerId ?? 'demo-owner');
      const history = await deps.getSyncHistory.execute(ownerId);
      res.json(history);
    }),
  );

  router.use(
    (
      error: unknown,
      _req: Request,
      res: Response,
      _next: NextFunction,
    ) => {
      if (error instanceof ZodError) {
        res.status(400).json({
          error: 'validation_error',
          message: 'La solicitud no es valida',
          issues: error.issues,
        });
        return;
      }
      if (error instanceof HttpError) {
        res.status(error.statusCode).json({
          error: error.code,
          message: error.message,
        });
        return;
      }

      console.error(error);
      res.status(500).json({
        error: 'internal_error',
        message: 'Error inesperado en la API',
      });
    },
  );

  return router;
}
