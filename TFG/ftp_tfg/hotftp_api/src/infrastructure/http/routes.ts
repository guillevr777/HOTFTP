import { Router } from 'express';
import type { NextFunction, Request, Response } from 'express';
import multer from 'multer';
import { ZodError } from 'zod';
import os from 'node:os';
import { join } from 'node:path';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';

import type { AppDependencies } from '../../config/dependencies.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { HttpError } from '../../shared/http/http-error.js';
import {
  alertSchema,
  dumpScheduleSchema,
  eventSchema,
  fileVersionSchema,
  loginSchema,
  monitoringOwnerSchema,
  profileSchema,
  syncRecordSchema,
  syncRunSchema,
} from './schemas.js';

export function createRouter(deps: AppDependencies) {
  const router = Router();
  const upload = multer({ storage: multer.memoryStorage() });

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

  router.delete(
    '/profiles/:id',
    asyncHandler(async (req, res) => {
      const ownerId = String(req.query.ownerId ?? 'demo-owner');
      const profileId = Number(req.params.id);
      if (Number.isNaN(profileId)) {
        throw new HttpError(400, 'id invalido', 'validation_error');
      }
      await deps.deleteProfile.execute(ownerId, profileId);
      res.status(204).send();
    }),
  );

  router.post(
    '/profiles/test-connection',
    asyncHandler(async (req, res) => {
      const profile = profileSchema.parse(req.body);
      const ok = await deps.ftpGateway.testConnection(profile);
      res.json({ ok });
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
    '/files/upload',
    upload.single('file'),
    asyncHandler(async (req, res) => {
      const ownerId = String(req.body.ownerId ?? '');
      const profileId = Number(req.body.profileId ?? '');
      const remotePath = String(req.body.remotePath ?? '/');
      const file = req.file;
      if (!ownerId || Number.isNaN(profileId) || !file) {
        throw new HttpError(400, 'ownerId, profileId y file son obligatorios', 'validation_error');
      }

      const profile = await deps.profileRepository.findById(ownerId, profileId);
      if (!profile) {
        throw new HttpError(404, 'Perfil FTP no encontrado', 'profile_not_found');
      }

      const tmpDir = await mkdtemp(join(os.tmpdir(), 'hotftp-upload-'));
      const tempFile = join(tmpDir, file.originalname);
      await writeFile(tempFile, file.buffer);
      try {
        await deps.ftpGateway.uploadFile(tempFile, remotePath, profile);
        res.status(200).json({ ok: true });
      } finally {
        await rm(tmpDir, { recursive: true, force: true });
      }
    }),
  );

  router.get(
    '/files/download',
    asyncHandler(async (req, res) => {
      const ownerId = String(req.query.ownerId ?? '');
      const profileId = Number(req.query.profileId ?? '');
      const remotePath = String(req.query.remotePath ?? '/');
      const fileName = String(req.query.fileName ?? '');
      if (!ownerId || Number.isNaN(profileId) || !fileName) {
        throw new HttpError(400, 'ownerId, profileId y fileName son obligatorios', 'validation_error');
      }
      const profile = await deps.profileRepository.findById(ownerId, profileId);
      if (!profile) {
        throw new HttpError(404, 'Perfil FTP no encontrado', 'profile_not_found');
      }

      const tmpDir = await mkdtemp(join(os.tmpdir(), 'hotftp-download-'));
      const tempFile = join(tmpDir, fileName);
      try {
        await deps.ftpGateway.downloadFileToPath(fileName, remotePath, tempFile, profile);
        res.download(tempFile, fileName, async () => {
          await rm(tmpDir, { recursive: true, force: true });
        });
      } catch (error) {
        await rm(tmpDir, { recursive: true, force: true });
        throw error;
      }
    }),
  );

  router.delete(
    '/files/remote',
    asyncHandler(async (req, res) => {
      const ownerId = String(req.query.ownerId ?? '');
      const profileId = Number(req.query.profileId ?? '');
      const remotePath = String(req.query.remotePath ?? '/');
      const fileName = String(req.query.fileName ?? '');
      if (!ownerId || Number.isNaN(profileId) || !fileName) {
        throw new HttpError(400, 'ownerId, profileId y fileName son obligatorios', 'validation_error');
      }
      const profile = await deps.profileRepository.findById(ownerId, profileId);
      if (!profile) {
        throw new HttpError(404, 'Perfil FTP no encontrado', 'profile_not_found');
      }
      await deps.ftpGateway.deleteRemoteFile(fileName, remotePath, profile);
      res.status(204).send();
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
    '/schedules',
    asyncHandler(async (req, res) => {
      const { ownerId } = monitoringOwnerSchema.parse({
        ownerId: req.query.ownerId ?? 'demo-owner',
      });
      const schedules = await deps.dumpScheduleRepository.list(ownerId);
      res.json(schedules);
    }),
  );

  router.get(
    '/schedules/profile',
    asyncHandler(async (req, res) => {
      const { ownerId } = monitoringOwnerSchema.parse({
        ownerId: req.query.ownerId ?? 'demo-owner',
      });
      const profileId = Number(req.query.profileId ?? '');
      if (Number.isNaN(profileId)) {
        throw new HttpError(400, 'profileId es obligatorio', 'validation_error');
      }
      const schedule = await deps.dumpScheduleRepository.findByProfile(
        ownerId,
        profileId,
      );
      res.json(schedule);
    }),
  );

  router.post(
    '/schedules',
    asyncHandler(async (req, res) => {
      const schedule = dumpScheduleSchema.parse(req.body);
      const saved = await deps.dumpScheduleRepository.save(schedule);
      res.status(201).json(saved);
    }),
  );

  router.delete(
    '/schedules/:id',
    asyncHandler(async (req, res) => {
      const { ownerId } = monitoringOwnerSchema.parse({
        ownerId: req.query.ownerId ?? 'demo-owner',
      });
      const id = Number(req.params.id);
      if (Number.isNaN(id)) {
        throw new HttpError(400, 'id invalido', 'validation_error');
      }
      await deps.dumpScheduleRepository.delete(ownerId, id);
      res.status(204).send();
    }),
  );

  router.get(
    '/monitoring/summary',
    asyncHandler(async (req, res) => {
      const { ownerId } = monitoringOwnerSchema.parse({
        ownerId: req.query.ownerId ?? 'demo-owner',
      });
      const summary = await deps.getHealthSummary.execute(ownerId);
      res.json(summary);
    }),
  );

  router.get(
    '/sync/history',
    asyncHandler(async (req, res) => {
      const { ownerId } = monitoringOwnerSchema.parse({
        ownerId: req.query.ownerId ?? 'demo-owner',
      });
      const history = await deps.getSyncHistory.execute(ownerId);
      res.json(history);
    }),
  );

  router.get(
    '/monitoring/events',
    asyncHandler(async (req, res) => {
      const { ownerId } = monitoringOwnerSchema.parse({
        ownerId: req.query.ownerId ?? 'demo-owner',
      });
      const limit = Number(req.query.limit ?? 20);
      const events = await deps.monitoringRepository.getRecentEvents(
        ownerId,
        Number.isNaN(limit) ? 20 : limit,
      );
      res.json(events);
    }),
  );

  router.post(
    '/monitoring/events',
    asyncHandler(async (req, res) => {
      const event = eventSchema.parse(req.body);
      await deps.monitoringRepository.recordEvent(event);
      res.status(201).json(event);
    }),
  );

  router.get(
    '/monitoring/alerts/active',
    asyncHandler(async (req, res) => {
      const { ownerId } = monitoringOwnerSchema.parse({
        ownerId: req.query.ownerId ?? 'demo-owner',
      });
      const limit = Number(req.query.limit ?? 10);
      const alerts = await deps.monitoringRepository.getActiveAlerts(
        ownerId,
        Number.isNaN(limit) ? 10 : limit,
      );
      res.json(alerts);
    }),
  );

  router.post(
    '/monitoring/alerts',
    asyncHandler(async (req, res) => {
      const alert = alertSchema.parse(req.body);
      const id = await deps.monitoringRepository.createAlert(alert);
      res.status(201).json({ ...alert, id });
    }),
  );

  router.post(
    '/monitoring/alerts/:id/acknowledge',
    asyncHandler(async (req, res) => {
      const { ownerId } = monitoringOwnerSchema.parse({
        ownerId: req.body.ownerId ?? req.query.ownerId ?? 'demo-owner',
      });
      const alertId = Number(req.params.id);
      if (Number.isNaN(alertId)) {
        throw new HttpError(400, 'id invalido', 'validation_error');
      }
      await deps.monitoringRepository.acknowledgeAlert(alertId, ownerId);
      res.status(204).send();
    }),
  );

  router.get(
    '/monitoring/file-versions/recent',
    asyncHandler(async (req, res) => {
      const { ownerId } = monitoringOwnerSchema.parse({
        ownerId: req.query.ownerId ?? 'demo-owner',
      });
      const limit = Number(req.query.limit ?? 12);
      const versions = await deps.monitoringRepository.getRecentFileVersions(
        ownerId,
        Number.isNaN(limit) ? 12 : limit,
      );
      res.json(versions);
    }),
  );

  router.post(
    '/monitoring/file-versions',
    asyncHandler(async (req, res) => {
      const version = fileVersionSchema.parse(req.body);
      const id = await deps.monitoringRepository.recordFileVersion(version);
      res.status(201).json({ ...version, id });
    }),
  );

  router.get(
    '/monitoring/file-versions/latest',
    asyncHandler(async (req, res) => {
      const { ownerId } = monitoringOwnerSchema.parse({
        ownerId: req.query.ownerId ?? 'demo-owner',
      });
      const profileId = Number(req.query.profileId ?? '');
      const filePath = String(req.query.filePath ?? '');
      if (Number.isNaN(profileId) || !filePath) {
        throw new HttpError(400, 'ownerId, profileId y filePath son obligatorios', 'validation_error');
      }
      const version = await deps.monitoringRepository.getLatestFileVersion(
        ownerId,
        profileId,
        filePath,
      );
      res.json(version);
    }),
  );

  router.get(
    '/monitoring/file-versions/history',
    asyncHandler(async (req, res) => {
      const { ownerId } = monitoringOwnerSchema.parse({
        ownerId: req.query.ownerId ?? 'demo-owner',
      });
      const profileId = Number(req.query.profileId ?? '');
      const filePath = String(req.query.filePath ?? '');
      const limit = Number(req.query.limit ?? 20);
      if (Number.isNaN(profileId) || !filePath) {
        throw new HttpError(400, 'ownerId, profileId y filePath son obligatorios', 'validation_error');
      }
      const versions = await deps.monitoringRepository.getFileVersionHistory(
        ownerId,
        profileId,
        filePath,
        Number.isNaN(limit) ? 20 : limit,
      );
      res.json(versions);
    }),
  );

  router.post(
    '/sync/records',
    asyncHandler(async (req, res) => {
      const record = syncRecordSchema.parse(req.body);
      await deps.monitoringRepository.recordSync({
        ...record,
      });
      res.status(201).json({ ok: true });
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
