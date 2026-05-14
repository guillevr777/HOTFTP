import { isIP } from 'node:net';

import type { FtpTransportType } from '../entities/ftp-profile.js';

export function resolveTransportType(host: string): FtpTransportType {
  const normalized = host.trim().toLowerCase();
  if (!normalized) return 'api';
  if (normalized === 'localhost') return 'direct';

  const ipVersion = isIP(normalized);
  if (ipVersion === 0) return 'api';

  return isPrivateOrLocalIp(normalized, ipVersion as 4 | 6) ? 'direct' : 'api';
}

function isPrivateOrLocalIp(host: string, version: 4 | 6): boolean {
    if (version === 4) {
      const parts = host.split('.').map((part) => Number(part));
      if (parts.length !== 4 || parts.some((part) => Number.isNaN(part))) {
        return false;
      }
      const [a, b = -1] = parts;
    if (a === 10) return true;
    if (a === 127) return true;
    if (a === 169 && b === 254) return true;
    if (a === 172 && b >= 16 && b <= 31) return true;
    if (a === 192 && b === 168) return true;
    return false;
  }

  if (host === '::1') return true;
  if (host.startsWith('fe80:')) return true;
  if (host.startsWith('fc') || host.startsWith('fd')) return true;
  return false;
}
