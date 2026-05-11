import { z } from 'zod';

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export const profileSchema = z.object({
  id: z.coerce.number().int().positive().optional(),
  ownerId: z.string(),
  name: z.string().min(1),
  host: z.string().min(1),
  port: z.number().int().positive(),
  username: z.string().min(1),
  password: z.string().min(1),
  useFTPS: z.boolean().default(false),
  passiveMode: z.boolean().default(true),
});

export const syncRunSchema = z.object({
  ownerId: z.string().min(1),
  profileId: z.coerce.number().int().positive(),
  remotePath: z.string().default('/'),
});

export const syncRecordSchema = z.object({
  id: z.coerce.number().int().positive().optional(),
  ownerId: z.string().min(1),
  profileId: z.coerce.number().int().positive(),
  date: z.string().datetime(),
  localPath: z.string().default(''),
  remotePath: z.string().default('/'),
  mode: z.string().min(1),
  filesTransferred: z.coerce.number().int().nonnegative().default(0),
  filesSkipped: z.coerce.number().int().nonnegative().default(0),
  errorMessage: z.string().optional(),
});

export const dumpScheduleSchema = z.object({
  id: z.coerce.number().int().positive().optional(),
  ownerId: z.string().min(1),
  profileId: z.coerce.number().int().positive(),
  enabled: z.coerce.boolean().default(true),
  localPath: z.string().min(1),
  remotePath: z.string().default('/'),
  sourceSide: z.enum(['local', 'remote']),
  transferMode: z.enum(['oneWay', 'syncBoth']),
  deleteSourceAfterCopy: z.coerce.boolean().default(false),
  intervalValue: z.coerce.number().int().positive().default(24),
  intervalUnit: z.enum(['hours', 'days']).default('hours'),
  lastRunAt: z.string().datetime().optional(),
  nextRunAt: z.string().datetime().optional(),
});

export const monitoringOwnerSchema = z.object({
  ownerId: z.string().min(1),
});

export const eventSchema = z.object({
  id: z.coerce.number().int().positive().optional(),
  ownerId: z.string().min(1),
  eventType: z.string().min(1),
  severity: z.enum(['info', 'success', 'warning', 'error']),
  title: z.string().min(1),
  message: z.string().min(1),
  relatedProfileId: z.coerce.number().int().positive().optional(),
  metadata: z.string().optional(),
  createdAt: z.string().datetime().default(() => new Date().toISOString()),
});

export const alertSchema = z.object({
  id: z.coerce.number().int().positive().optional(),
  ownerId: z.string().min(1),
  source: z.string().min(1),
  severity: z.enum(['info', 'warning', 'error']),
  title: z.string().min(1),
  message: z.string().min(1),
  relatedProfileId: z.coerce.number().int().positive().optional(),
  isRead: z.coerce.boolean().default(false),
  createdAt: z.string().datetime().default(() => new Date().toISOString()),
  resolvedAt: z.string().datetime().optional(),
});

export const fileVersionSchema = z.object({
  id: z.coerce.number().int().positive().optional(),
  ownerId: z.string().min(1),
  profileId: z.coerce.number().int().positive(),
  filePath: z.string().min(1),
  fileName: z.string().min(1),
  versionNumber: z.coerce.number().int().positive(),
  size: z.coerce.number().int().nonnegative(),
  modifiedAt: z.string().datetime().optional(),
  source: z.string().min(1),
  createdAt: z.string().datetime().default(() => new Date().toISOString()),
});
