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
